require "fileutils"
require_relative '../pbxproj_manager'

# Base class for adding files to Xcode project
class FileAdder
  def self.add_files(project_manager, options = {})
    raise NotImplementedError, "Subclasses must implement add_files method"
  end

  protected

  # ターゲットとビルドフェーズを取得
  def self.get_target_build_phases(project_content, phase_type)
    target_build_phases = []
    current_target = nil
    current_target_name = nil
    in_target = false
    in_build_phases = false
    
    project_content.each_line do |line|
      # PBXNativeTargetの開始を検出
      if line.match(/([A-F0-9]{24}) \/\* (.+?) \*\/ = \{/)
        uuid = $1
        name = $2
        # 次の行でisa = PBXNativeTargetかチェックするため一時保存
        current_target = uuid
        current_target_name = name
        in_target = false
      elsif current_target && line.include?("isa = PBXNativeTarget")
        # 前の行で見つけたUUIDが実際にPBXNativeTargetだった
        in_target = true
        puts "DEBUG: Found PBXNativeTarget: #{current_target_name} (#{current_target})" if ENV['DEBUG']
      elsif in_target && line.include?("buildPhases = (")
        # buildPhasesセクション内でSourcesまたはResourcesを探す
        in_build_phases = true
      elsif in_target && in_build_phases && line.match(/([A-F0-9]{24}) \/\* (Sources|Resources) \*\/,/)
        build_phase_uuid = $1
        phase_name = $2
        # PBXSourcesBuildPhaseまたはPBXResourcesBuildPhaseのチェック
        if (phase_type == "PBXSourcesBuildPhase" && phase_name == "Sources") ||
           (phase_type == "PBXResourcesBuildPhase" && phase_name == "Resources")
          target_build_phases << [current_target, build_phase_uuid]
          puts "DEBUG: Found #{phase_name} build phase for target #{current_target}: #{build_phase_uuid}" if ENV['DEBUG']
        end
      elsif in_build_phases && line.strip == ");"
        # buildPhasesセクションの終了
        in_build_phases = false
      elsif line.strip == "};" && in_target
        # ターゲットセクションの終了
        in_target = false
        in_build_phases = false
        current_target = nil
        current_target_name = nil
      end
    end
    target_build_phases
  end

  # テスト用ターゲットを除外してビルドフェーズを検出
  def self.count_non_test_build_phases(project_manager, project_content, phase_type)
    # ターゲットとビルドフェーズを取得
    target_build_phases = get_target_build_phases(project_content, phase_type)
    puts "DEBUG: Found #{target_build_phases.length} total build phases for #{phase_type}" if ENV['DEBUG']
    
    # .appターゲットのビルドフェーズをカウント
    count = 0
    target_build_phases.each do |target_uuid, build_phase_uuid|
      if is_app_target?(project_content, target_uuid)
        puts "DEBUG: Target #{target_uuid} is an app target" if ENV['DEBUG']
        count += 1
      end
    end
    puts "DEBUG: Found #{count} app targets" if ENV['DEBUG']
    count
  end

  # テスト用以外のビルドフェーズの挿入位置を見つける
  def self.find_non_test_build_phase_insert_lines(project_content, phase_type)
    target_build_phases = get_target_build_phases(project_content, phase_type)
    insert_lines = []
    
    target_build_phases.each do |target_uuid, build_phase_uuid|
      if is_app_target?(project_content, target_uuid)
        # ビルドフェーズのfiles = (行を見つける
        project_content.each_line.with_index do |line, index|
          # PBXSourcesBuildPhaseまたはPBXResourcesBuildPhaseセクション内の定義を探す
          phase_name = phase_type == "PBXSourcesBuildPhase" ? "Sources" : "Resources"
          if line.include?("#{build_phase_uuid} /* #{phase_name} */ = {")
            puts "DEBUG: Found build phase definition at line #{index}" if ENV['DEBUG']
            # 次の数行でfiles = (を探す
            (index+1..index+10).each do |i|
              if project_content.lines[i] && project_content.lines[i].include?("files = (")
                puts "DEBUG: Found 'files = (' at line #{i}" if ENV['DEBUG']
                insert_lines << i + 1
                break
              end
            end
            break
          end
        end
      end
    end
    puts "DEBUG: Total insert lines found: #{insert_lines.length}" if ENV['DEBUG']
    insert_lines
  end

  # ターゲットがアプリターゲットかどうかを判定
  def self.is_app_target?(project_content, target_uuid)
    # ターゲットのproductReferenceを取得
    product_ref_uuid = get_target_product_reference(project_content, target_uuid)
    return false unless product_ref_uuid
    
    # productReferenceが.appかどうかチェック
    is_app_product?(project_content, product_ref_uuid)
  end

  # ターゲットのproductReferenceを取得
  def self.get_target_product_reference(project_content, target_uuid)
    in_target_section = false
    found_target_header = false
    
    project_content.each_line do |line|
      # ターゲットの開始を検出
      if line.include?("#{target_uuid} /*") && line.include?("*/ = {")
        found_target_header = true
      elsif found_target_header && line.include?("isa = PBXNativeTarget")
        in_target_section = true
      elsif in_target_section && line.include?("productReference = ")
        if line.match(/productReference = ([A-F0-9]{24}) \/\*/)
          return $1
        end
      elsif in_target_section && line.strip == "};"
        break
      end
    end
    nil
  end

  # productReferenceが.appかどうかチェック
  def self.is_app_product?(project_content, product_ref_uuid)
    project_content.each_line do |line|
      if line.include?(product_ref_uuid) && line.include?("isa = PBXFileReference")
        # .app で終わるかチェック
        return line.include?(".app")
      end
    end
    false
  end

  # PBXBuildFileセクションの終わりを見つける
  def self.find_pbx_build_file_section_end(project_content)
    lines = project_content.lines
    lines.each_with_index do |line, index|
      if line.include?("/* End PBXBuildFile section */")
        puts "DEBUG: Found PBXBuildFile section end at line #{index}: #{line.strip}"
        return index
      end
    end
    puts "WARNING: Could not find '/* End PBXBuildFile section */' marker in project file!"
    nil
  end
  
  # PBXBuildFileセクションを作成
  def self.create_pbx_build_file_section(project_content)
    lines = project_content.lines
    
    # objectsセクションの開始を探す
    objects_start = nil
    lines.each_with_index do |line, index|
      if line.strip == "objects = {"
        objects_start = index + 1
        break
      end
    end
    
    if objects_start.nil?
      puts "ERROR: Could not find objects section"
      return nil
    end
    
    # PBXBuildFileセクションを挿入
    section_header = "\n/* Begin PBXBuildFile section */\n"
    section_footer = "/* End PBXBuildFile section */\n"
    
    lines.insert(objects_start, section_header)
    lines.insert(objects_start + 1, section_footer)
    project_content.replace(lines.join)
    
    puts "Created PBXBuildFile section at line #{objects_start}"
    # 新しく作成したセクションの終了位置を返す
    objects_start + 1
  end
  
  # PBXBuildFileセクションの終わりを見つけるか、無ければ作成
  def self.find_or_create_pbx_build_file_section_end(project_content)
    insert_line = find_pbx_build_file_section_end(project_content)
    if insert_line.nil?
      puts "PBXBuildFile section not found, creating it..."
      insert_line = create_pbx_build_file_section(project_content)
    end
    insert_line
  end

  # PBXFileReferenceセクションの終わりを見つける
  def self.find_pbx_file_reference_section_end(project_content)
    project_content.each_line.with_index do |line, index|
      if line.include?("/* End PBXFileReference section */")
        return index
      end
    end
    nil
  end

  # バックアップとエラーハンドリングを含む安全な処理実行
  def self.safe_add_files(project_manager, &block)
    return unless File.exist?(project_manager.project_file_path)
    
    # バックアップを作成
    backup_path = project_manager.project_file_path + ".backup"
    FileUtils.copy(project_manager.project_file_path, backup_path)
    
    begin
      # プロジェクトファイルを読み取り
      project_content = File.read(project_manager.project_file_path)
      
      # Xcode 16の同期グループをチェック
      if PbxprojManager.is_synchronized_group?(project_content)
        puts "Consider converting the main app folder to a regular group to avoid duplicate compilation."
        FileUtils.rm(backup_path) if File.exist?(backup_path)
        return
      end
      
      # サブクラスの処理を実行
      puts "DEBUG: Processing project file: #{project_manager.project_file_path}"
      puts "DEBUG: Content length before processing: #{project_content.length}"
      
      result = block.call(project_content)
      
      # デバッグ: 変更前後を確認
      if project_content.include?("PBXBuildFile")
        puts "DEBUG: PBXBuildFile section exists in content"
      end
      puts "DEBUG: Content length after processing: #{project_content.length}"
      
      # プロジェクトファイルを書き戻し
      File.write(project_manager.project_file_path, project_content)
      puts "DEBUG: Written project file to: #{project_manager.project_file_path}"
      
      # バックアップファイルを削除
      FileUtils.rm(backup_path) if File.exist?(backup_path)
      
      result
    rescue => e
      puts "Error adding files to Xcode project: #{e.message}"
      puts e.backtrace.first(3)
      # エラー時は元のファイルを復元
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, project_manager.project_file_path)
        FileUtils.rm(backup_path)
        puts "Restored original project file"
      end
      raise e
    end
  end
end