#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative "../project_finder"
require_relative "../config_manager"

class PbxprojManager
  def initialize(project_file_path = nil)
    if project_file_path
      @project_file_path = project_file_path
      @project_root = ProjectFinder.get_project_root(@project_file_path)
    else
      # 後方互換性のため、引数なしの場合は従来通り検索
      @binding_builder_dir = File.expand_path("../../", __FILE__)
      @project_root = File.dirname(@binding_builder_dir)
      @project_file_path = find_project_file
    end
    
    # ConfigManagerを使用してプロジェクト設定を取得
    @config = ConfigManager.load_config(@binding_builder_dir)
    @source_directory = ConfigManager.get_source_directory(@binding_builder_dir)
    @hot_loader_directory = ConfigManager.get_hot_loader_directory(@binding_builder_dir)
  end

  def setup_individual_file_exclusions
    puts "Setting up individual file exclusions in membershipExceptions"
    
    # バックアップを作成
    backup_path = create_backup(@project_file_path)
    
    begin
      content = File.read(@project_file_path)
      
      # binding_builderとhot_loaderディレクトリ内のすべてのファイルを収集
      all_files = collect_all_files_for_exclusion
      puts "Found #{all_files.length} files to exclude"
      
      # membershipExceptionsを更新
      content = update_membership_exceptions_with_all_files(content, all_files)
      
      # ファイルに書き込み
      File.write(@project_file_path, content)
      
      # 整合性をチェック
      if validate_pbxproj(@project_file_path)
        puts "✅ pbxproj file validation passed"
        cleanup_backup(backup_path)
      else
        puts "❌ pbxproj file validation failed, rolling back..."
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        raise "pbxproj file corruption detected after individual file exclusions"
      end
      
    rescue => e
      puts "Error during individual file exclusions: #{e.message}"
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        puts "Restored pbxproj file from backup"
      end
      raise e
    end
  end

  def collect_all_files_for_exclusion
    all_files = ["Info.plist", ".gitignore"]  # Info.plistと.gitignoreを最初に追加
    
    # ConfigManagerを使用してソースディレクトリを動的に取得
    xcodeproj_dir = File.dirname(@project_file_path)
    project_parent = File.dirname(xcodeproj_dir)
    
    # source_directoryが空の場合はプロジェクト直下、指定されている場合はそのディレクトリ
    if @source_directory.empty?
      source_root = project_parent
    else
      source_root = File.join(project_parent, @source_directory)
    end
    
    
    # binding_builderディレクトリのすべてのファイルを追加
    binding_builder_dir = File.join(source_root, "binding_builder")
    puts "Checking binding_builder_dir: #{binding_builder_dir} (exists: #{Dir.exist?(binding_builder_dir)})"
    if Dir.exist?(binding_builder_dir)
      # PBXFileSystemSynchronizedRootGroupが既にsource_directoryを基準にしているため、
      # membershipExceptionsではsource_directoryを含めない
      all_files.concat(get_all_files_in_directory_relative(binding_builder_dir, "binding_builder"))
    end
    
    # hot_loaderディレクトリのすべてのファイルを追加（configから取得）
    if @hot_loader_directory.empty?
      # hot_loader_directoryが空の場合はスキップ
      puts "hot_loader_directory is not configured, skipping hot_loader files"
    else
      # hot_loaderディレクトリはsource_directory内に配置されている前提
      hot_loader_dir = File.join(source_root, "hot_loader")
      puts "Checking hot_loader_dir: #{hot_loader_dir} (exists: #{Dir.exist?(hot_loader_dir)})"
      if Dir.exist?(hot_loader_dir)
        # PBXFileSystemSynchronizedRootGroupが既にsource_directoryを基準にしているため、
        # membershipExceptionsではsource_directoryを含めない
        all_files.concat(get_all_files_in_directory_relative(hot_loader_dir, "hot_loader"))
      end
    end
    
    # installerディレクトリのすべてのファイルを追加
    installer_dir = File.join(source_root, "installer")
    puts "Checking installer_dir: #{installer_dir} (exists: #{Dir.exist?(installer_dir)})"
    if Dir.exist?(installer_dir)
      all_files.concat(get_all_files_in_directory_relative(installer_dir, "installer"))
    end
    
    all_files.sort
  end

  def get_all_files_in_directory_relative(dir_path, prefix)
    return [] unless Dir.exist?(dir_path)
    
    files = []
    begin
      Dir.glob("#{dir_path}/**/*", File::FNM_DOTMATCH).each do |file_path|
        next if File.directory?(file_path)
        
        # .DS_Storeは除外（システムファイル）、その他の.で始まるファイルは含める
        basename = File.basename(file_path)
        next if basename == ".DS_Store"
        
        # dir_pathからの相対パスを取得してprefixを付けて最終的な相対パスを作成
        relative_to_dir = file_path.sub("#{dir_path}/", "")
        relative_path = "#{prefix}/#{relative_to_dir}"
        
        # ファイル名にpbxprojに問題を起こす可能性のある文字が含まれていないかチェック
        if is_safe_file_path?(relative_path)
          files << relative_path
        else
          puts "Warning: Skipping file with potentially problematic name: #{relative_path}"
        end
      end
    rescue => e
      puts "Error reading directory #{dir_path}: #{e.message}"
      return []
    end
    
    files
  end

  def update_membership_exceptions_with_all_files(content, all_files)
    puts "Updating membershipExceptions with #{all_files.length} files"
    
    # 既存のmembershipExceptionsを探す
    target_pattern = /membershipExceptions = \(\s*(.*?)\s*\);/m
    
    if content.match(target_pattern)
      # 新しいexceptionsをフォーマット（すべてのファイルを個別に処理）
      formatted_exceptions = all_files.map do |file|
        # pbxprojで安全な形式にフォーマット
        escaped_file = escape_file_for_pbxproj(file)
        "\t\t\t\t#{escaped_file},"
      end.join("\n")
      
      replacement = "membershipExceptions = (\n#{formatted_exceptions}\n\t\t\t);"
      
      # 手動で置換
      if match = content.match(target_pattern)
        before_match = content[0...match.begin(0)]
        after_match = content[match.end(0)..-1]
        content = before_match + replacement + after_match
      else
        puts "❌ Could not perform manual replacement"
        return content
      end
      
      puts "✅ membershipExceptions updated with #{all_files.length} entries"
    else
      puts "Warning: Could not find membershipExceptions pattern to update"
    end
    
    content
  end
  
  def escape_file_for_pbxproj(file)
    # pbxprojファイルで安全な形式にエスケープ
    
    # 特殊文字や空白を含む場合はダブルクォートで囲む
    if file.match?(/[^a-zA-Z0-9._\-\/]/) || file.include?(" ")
      # ダブルクォート内の特殊文字をエスケープ
      escaped = file.gsub('\\', '\\\\')  # バックスラッシュ
                    .gsub('"', '\\"')    # ダブルクォート
                    .gsub("\n", '\\n')   # 改行
                    .gsub("\t", '\\t')   # タブ
      "\"#{escaped}\""
    else
      # 安全な文字のみの場合はそのまま
      file
    end
  end
  
  def update_membership_exceptions_directory_level(content)
    puts "Using directory-level exclusions (hot_loader, binding_builder)"
    
    # 既存のmembershipExceptionsを探す
    target_pattern = /membershipExceptions = \(\s*(.*?)\s*\);/m
    
    if content.match(target_pattern)
      # ディレクトリレベルの除外
      directory_exceptions = [".gitignore", "hot_loader", "binding_builder"]
      formatted_exceptions = directory_exceptions.map { |dir| "\t\t\t\t#{dir}," }.join("\n")
      
      replacement = "membershipExceptions = (\n#{formatted_exceptions}\n\t\t\t);"
      
      # 手動で置換
      if match = content.match(target_pattern)
        before_match = content[0...match.begin(0)]
        after_match = content[match.end(0)..-1]
        content = before_match + replacement + after_match
      else
        puts "❌ Could not perform manual replacement"
        return content
      end
      
      puts "✅ membershipExceptions updated with directory-level exclusions"
    else
      puts "Warning: Could not find membershipExceptions pattern to update"
    end
    
    content
  end

  protected

  def find_project_file
    # ProjectFinderを使用してプロジェクトファイルを検索
    binding_builder_dir = File.expand_path("../../", __FILE__)
    ProjectFinder.find_project_file(binding_builder_dir)
  end

  def create_backup(file_path)
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_path = "#{file_path}.backup_#{timestamp}"
    FileUtils.copy(file_path, backup_path)
    puts "Created backup: #{backup_path}"
    backup_path
  end

  def cleanup_backup(backup_path)
    if File.exist?(backup_path)
      File.delete(backup_path)
      puts "Cleaned up backup: #{backup_path}"
    end
  end

  def validate_pbxproj(file_path)
    return false unless File.exist?(file_path)
    
    begin
      # plutilコマンドを使用してpbxprojファイルの構文をチェック
      result = `plutil -lint "#{file_path}" 2>&1`
      exit_status = $?.exitstatus
      
      if exit_status == 0
        puts "pbxproj validation passed (plutil syntax check successful)"
        return true
      else
        puts "pbxproj validation failed:"
        puts result
        return false
      end
      
    rescue => e
      puts "pbxproj validation error: #{e.message}"
      
      # plutilが利用できない場合はフォールバック検証
      puts "Falling back to basic validation..."
      return basic_pbxproj_validation(file_path)
    end
  end

  private

  def basic_pbxproj_validation(file_path)
    begin
      content = File.read(file_path)
      
      # 基本的な構造チェック
      return false unless content.include?("// !$*UTF8*$!")
      return false unless content.include?("archiveVersion = 1;")
      return false unless content.include?("objectVersion =")
      
      # 括弧のバランスチェック
      open_braces = content.count('{')
      close_braces = content.count('}')
      if open_braces != close_braces
        puts "Brace mismatch: #{open_braces} open braces, #{close_braces} close braces"
        return false
      end
      
      puts "pbxproj basic validation passed"
      true
      
    rescue => e
      puts "pbxproj basic validation error: #{e.message}"
      false
    end
  end

  def rollback_changes(backup_path, created_files = [])
    puts "Rolling back changes..."
    
    # 作成されたファイルを削除
    created_files.each do |file_path|
      if File.exist?(file_path)
        # フォルダとファイルを削除
        File.delete(file_path)
        puts "Deleted created file: #{file_path}"
        
        # 空のフォルダも削除
        folder_path = File.dirname(file_path)
        if Dir.exist?(folder_path) && Dir.empty?(folder_path)
          Dir.rmdir(folder_path)
          puts "Deleted empty folder: #{folder_path}"
        end
      end
    end
    
    # pbxprojファイルを復元
    if File.exist?(backup_path)
      FileUtils.copy(backup_path, @project_file_path)
      File.delete(backup_path)
      puts "Restored pbxproj file from backup"
    end
  end

  def safe_pbxproj_operation(file_names, created_files = [], &block)
    return unless File.exist?(@project_file_path)
    
    # プロジェクトファイルをバックアップ
    backup_path = create_backup(@project_file_path)
    
    begin
      # ブロック内で処理を実行
      yield
      
      # pbxprojファイルの整合性をチェック
      if validate_pbxproj(@project_file_path)
        puts "pbxproj operation completed successfully"
        cleanup_backup(backup_path)
      else
        puts "pbxproj file validation failed, rolling back..."
        rollback_changes(backup_path, created_files)
        raise "pbxproj file corruption detected"
      end
      
    rescue => e
      puts "Error during pbxproj operation: #{e.message}"
      rollback_changes(backup_path, created_files)
      raise e
    end
  end

  def setup_membership_exceptions
    return unless File.exist?(@project_file_path)
    
    puts "Setting up file exclusions for hot_loader and binding_builder files..."
    
    # 手動で更新したように、すべてのファイルを個別に列挙する方式
    puts "Using individual file exclusions in membershipExceptions"
    setup_individual_file_exclusions
  end

  def setup_membership_exceptions_modern
    # バックアップを作成
    backup_path = create_backup(@project_file_path)
    
    begin
      content = File.read(@project_file_path)
      
      # ディレクトリレベルで除外
      all_files = ["hot_loader", "binding_builder"]
      puts "Found #{all_files.length} directories to exclude: #{all_files.join(', ')}"
      
      # 現在のmembershipExceptionsを取得
      current_exceptions = extract_current_membership_exceptions(content)
      
      # 新しい例外を追加（重複を避けるため既存のhot_loaderとbinding_builderファイルを除外）
      filtered_current = current_exceptions.reject { |f| f.start_with?('hot_loader') || f.start_with?('binding_builder') }
      new_exceptions = (filtered_current + all_files).uniq
      
      # フォーマットして置換
      if new_exceptions.empty?
        puts "No files to add to membershipExceptions"
        cleanup_backup(backup_path)
        return
      end
      
      formatted_exceptions = new_exceptions.map { |file| "\t\t\t\t#{file}," }.join("\n")
      
      target_pattern = /membershipExceptions = \(\s*(.*?)\s*\);/m
      
      if content.match(target_pattern)
        replacement = "membershipExceptions = (\n#{formatted_exceptions}\n\t\t\t);"
        
        puts "Replacing membershipExceptions section (#{new_exceptions.length} entries)"
        
        # 元のセクションを見つけて手動で置換
        if match = content.match(target_pattern)
          before_match = content[0...match.begin(0)]
          after_match = content[match.end(0)..-1]
          content = before_match + replacement + after_match
        else
          puts "❌ Could not perform manual replacement"
          cleanup_backup(backup_path)
          return
        end
        puts "✅ membershipExceptions updated with #{new_exceptions.length} entries"
      else
        puts "Warning: Could not find membershipExceptions pattern to update"
        cleanup_backup(backup_path)
        return
      end
      
      # ファイルに書き込み
      File.write(@project_file_path, content)
      
      # 整合性をチェック
      if validate_pbxproj(@project_file_path)
        puts "✅ pbxproj file validation passed"
        cleanup_backup(backup_path)
      else
        puts "❌ pbxproj file validation failed, rolling back..."
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        raise "pbxproj file corruption detected after membershipExceptions update"
      end
      
    rescue => e
      puts "Error during membershipExceptions setup: #{e.message}"
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        puts "Restored pbxproj file from backup"
      end
      raise e
    end
  end

  def setup_file_exclusions_traditional
    puts "Using traditional file exclusion method"
    puts "Removing hot_loader and binding_builder files from build phases"
    
    # バックアップを作成
    backup_path = create_backup(@project_file_path)
    
    begin
      content = File.read(@project_file_path)
      
      # PBXResourcesBuildPhaseから問題のあるファイルを除外
      content = remove_problematic_files_from_build_phases(content)
      
      # ファイルに書き込み
      File.write(@project_file_path, content)
      
      # 整合性をチェック
      if validate_pbxproj(@project_file_path)
        puts "✅ pbxproj file validation passed"
        cleanup_backup(backup_path)
      else
        puts "❌ pbxproj file validation failed, rolling back..."
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        raise "pbxproj file corruption detected after traditional exclusion"
      end
      
    rescue => e
      puts "Error during traditional file exclusion: #{e.message}"
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        puts "Restored pbxproj file from backup"
      end
      raise e
    end
  end

  def remove_problematic_files_from_build_phases(content)
    puts "Scanning for problematic files in build phases..."
    
    # hot_loaderとbinding_builderに関連するPBXBuildFileエントリを特定
    problematic_uuids = []
    problematic_file_refs = []
    
    content.each_line do |line|
      # PBXBuildFileセクションで問題のあるファイルを特定
      if line.include?("PBXBuildFile") && (line.include?("hot_loader") || line.include?("binding_builder"))
        if match = line.match(/([A-F0-9]{24}) \/\*.*\*\/ = \{isa = PBXBuildFile/)
          problematic_uuids << match[1]
          puts "Found problematic build file: #{match[1]}"
        end
      end
      
      # PBXFileReferenceセクションでも問題のあるファイルを特定
      if line.include?("PBXFileReference") && (line.include?("hot_loader") || line.include?("binding_builder"))
        if match = line.match(/([A-F0-9]{24}) \/\*.*\*\/ = \{isa = PBXFileReference/)
          problematic_file_refs << match[1]
          puts "Found problematic file reference: #{match[1]}"
        end
      end
    end
    
    all_problematic_uuids = problematic_uuids + problematic_file_refs
    
    if all_problematic_uuids.empty?
      puts "No problematic file references found in current pbxproj"
      # ファイル参照がなくても、membershipExceptionsを更新して将来の問題を防ぐ
      return add_filesystem_synchronized_exceptions(content)
    end
    
    puts "Removing #{all_problematic_uuids.length} problematic file references from build phases"
    
    # 各ビルドフェーズから問題のあるUUIDを削除
    lines = content.lines
    modified_lines = []
    
    lines.each do |line|
      # 問題のあるUUIDを含む行をスキップ
      should_skip = all_problematic_uuids.any? { |uuid| line.include?(uuid) }
      
      unless should_skip
        modified_lines << line
      else
        puts "Removing line: #{line.strip}"
      end
    end
    
    modified_content = modified_lines.join
    
    # PBXFileSystemSynchronizedRootGroupのexceptionsを設定
    modified_content = add_filesystem_synchronized_exceptions(modified_content)
    
    modified_content
  end
  

  def add_filesystem_synchronized_exceptions(content)
    puts "Adding file system synchronized exceptions..."
    
    # hot_loaderとbinding_builderディレクトリを除外するため、
    # PBXFileSystemSynchronizedRootGroupに適切なexclusionを追加
    
    # 既存のPBXFileSystemSynchronizedBuildFileExceptionSetを探す
    if content.include?("PBXFileSystemSynchronizedBuildFileExceptionSet")
      puts "Found existing PBXFileSystemSynchronizedBuildFileExceptionSet, updating it"
      
      # membershipExceptionsにhot_loaderとbinding_builderを追加
      target_pattern = /membershipExceptions = \(\s*(.*?)\s*\);/m
      
      if match = content.match(target_pattern)
        current_exceptions = []
        match[1].split("\n").each do |line|
          line = line.strip
          next if line.empty?
          clean_line = line.gsub(/\/\*.*?\*\//, '').strip.gsub(/,$/, '')
          current_exceptions << clean_line unless clean_line.empty?
        end
        
        # hot_loaderとbinding_builderを追加（重複を避ける）
        new_exceptions = (current_exceptions + ["hot_loader", "binding_builder"]).uniq
        formatted_exceptions = new_exceptions.map { |file| "\t\t\t\t#{file}," }.join("\n")
        
        replacement = "membershipExceptions = (\n#{formatted_exceptions}\n\t\t\t);"
        content = content.gsub(target_pattern, replacement)
        puts "Updated membershipExceptions with hot_loader and binding_builder"
      end
    end
    
    content
  end
  
  # テスト用の公開メソッド
  def test_setup_membership_exceptions
    setup_membership_exceptions
  end
  
  # 公開メソッド
  def public_setup_membership_exceptions
    setup_membership_exceptions
  end
  
  # 公開メソッド - 個別ファイル除外
  def public_setup_individual_file_exclusions
    setup_individual_file_exclusions
  end

  private

  def get_all_files_in_directory(dir_path)
    return [] unless Dir.exist?(dir_path)
    
    files = []
    begin
      Dir.glob("#{dir_path}/**/*", File::FNM_DOTMATCH).each do |file_path|
        next if File.directory?(file_path)
        next if File.basename(file_path).start_with?('.')
        
        # プロジェクトルートからの相対パスを取得
        project_root = File.dirname(File.dirname(@project_file_path))
        # source_directoryを使用してパスを構築
        source_base = @source_directory.empty? ? project_root : File.join(project_root, @source_directory)
        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_base)).to_s
        
        # ファイル名にpbxprojに問題を起こす可能性のある文字が含まれていないかチェック
        if is_safe_file_path?(relative_path)
          files << relative_path
        else
          puts "Warning: Skipping file with potentially problematic name: #{relative_path}"
        end
      end
    rescue => e
      puts "Error reading directory #{dir_path}: #{e.message}"
      return []
    end
    
    files
  end
  
  def is_safe_file_path?(path)
    # pbxprojファイルで問題を起こす可能性のある文字をチェック
    return false if path.include?('"')
    return false if path.include?("'")
    return false if path.include?("\n")
    return false if path.include?("\r")
    return false if path.include?("\t")
    return false if path.match?(/[^\x20-\x7E]/) # ASCII印刷可能文字以外
    true
  end

  def extract_current_membership_exceptions(content)
    match = content.match(/membershipExceptions = \(\s*(.*?)\s*\);/m)
    return ["Info.plist"] unless match
    
    exceptions = []
    # 改行で分割してから各行を処理
    match[1].split("\n").each do |line|
      line = line.strip
      next if line.empty?
      # コメントを削除してクリーンなファイル名を取得
      clean_line = line.gsub(/\/\*.*?\*\//, '').strip.gsub(/,$/, '')
      exceptions << clean_line unless clean_line.empty?
    end
    
    exceptions
  end

  def remove_copy_bundle_resources_build_phase(content)
    puts "Checking for hot_loader and binding_builder files in Copy Bundle Resources..."
    
    # Copy Bundle Resourcesビルドフェーズのパターンを検索
    copy_resources_pattern = /(\w+) \/\* Copy Bundle Resources \*\/ = \{\s*isa = PBXResourcesBuildPhase;\s*buildActionMask = \d+;\s*files = \(\s*(.*?)\s*\);\s*runOnlyForDeploymentPostprocessing = 0;\s*\};/m
    
    if content.match(copy_resources_pattern)
      build_phase_id = $1
      files_section = $2
      puts "Found Copy Bundle Resources build phase with ID: #{build_phase_id}"
      
      # ファイルリストから hot_loader と binding_builder 関連のエントリを削除
      filtered_files = []
      files_section.split(',').each do |file_entry|
        file_entry = file_entry.strip
        next if file_entry.empty?
        
        # hot_loader または binding_builder を含むファイルエントリをスキップ
        if file_entry.include?('hot_loader') || file_entry.include?('binding_builder')
          puts "Removing file entry: #{file_entry}"
          next
        end
        
        filtered_files << file_entry
      end
      
      # フィルタされたファイルリストで置換
      filtered_files_str = filtered_files.empty? ? '' : filtered_files.join(",\n\t\t\t\t") + ','
      
      replacement = "#{build_phase_id} /* Copy Bundle Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t#{filtered_files_str}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};"
      
      content = content.gsub(copy_resources_pattern, replacement)
      puts "✅ hot_loader and binding_builder files removed from Copy Bundle Resources"
    else
      puts "No Copy Bundle Resources build phase found"
    end
    
    content
  end
end