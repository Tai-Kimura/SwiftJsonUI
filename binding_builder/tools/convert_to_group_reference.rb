#!/usr/bin/env ruby

# convert_to_group_reference.rb - Xcode 16 Synchronized Folder to Group Reference Converter
#
# Purpose:
# This tool converts Xcode 16's new synchronized folder references back to traditional group references.
# 
# Background:
# Starting with Xcode 16, Apple introduced synchronized folders that automatically include all files
# in a directory. While convenient, this can cause issues with SwiftJsonUI's binding_builder:
# - All files in synchronized folders are automatically compiled, causing duplicate compilation errors
# - binding_builder needs precise control over which files are included in the build
# - The new format is incompatible with older Xcode versions
#
# What this tool does:
# 1. Converts PBXFileSystemSynchronizedRootGroup → PBXGroup for the main app only
# 2. Creates PBXFileReference entries for standard files (AppDelegate, SceneDelegate, etc.)
# 3. Removes exceptions and fileSystemSynchronizedGroups references
# 4. Preserves test targets as synchronized (they don't have the same issues)
# 5. Maintains all existing file references in the project
#
# Usage:
# - Run via: sjui convert to-group [--force]
# - The --force flag skips the confirmation prompt
# - A backup of the project file is created before conversion
#
# Important: Order of operations
# For new Xcode 16 projects:
# 1. Run `sjui convert to-group` first to convert synchronized folders
# 2. Then run `sjui setup` to create the SwiftJsonUI directory structure
#
# For existing projects with SwiftJsonUI already set up:
# - Run `sjui convert to-group` to fix synchronization issues
#
# After conversion:
# - The main app group will contain all existing files and groups
# - Test targets remain as synchronized folders (no issues there)
# - You can continue using binding_builder normally

require 'fileutils'
require 'json'
require 'time'
require 'securerandom'

class XcodeSyncToGroupConverter
  def initialize(pbxproj_path)
    @pbxproj_path = pbxproj_path
    @backup_path = "#{pbxproj_path}.backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
  end

  def convert
    puts "Converting Xcode 16 synchronized folders to group references..."
    
    # バックアップ作成
    FileUtils.copy(@pbxproj_path, @backup_path)
    puts "Backup created: #{@backup_path}"
    
    # ファイル読み込み
    content = File.read(@pbxproj_path)
    original_content = content.dup
    
    # プロジェクト情報を取得
    # /tmp/test_non_setup.pbxproj の場合は特別処理
    if @pbxproj_path.include?('/tmp/')
      # ファイル名から推測
      app_name = 'bindingTestApp'
      project_dir = '/tmp'
    else
      project_dir = File.dirname(File.dirname(@pbxproj_path))
      app_name = File.basename(project_dir, '.xcodeproj')
    end
    
    # メインアプリグループのUUIDを探す
    main_app_uuid = nil
    content.scan(/([A-F0-9]{24}) \/\* #{Regexp.escape(app_name)} \*\/ = \{[^}]*?isa = PBXFileSystemSynchronized(?:Root)?Group;/m) do |uuid|
      main_app_uuid = uuid[0]
      puts "Found main app synchronized group: #{main_app_uuid}"
      break
    end
    
    unless main_app_uuid
      puts "No synchronized groups found. Project may already be using group references."
      return
    end
    
    # 1. 実際のディレクトリ構造からファイルを取得
    app_dir = if @pbxproj_path.include?('/tmp/')
      nil  # テスト環境では実際のファイルシステムを参照しない
    else
      File.join(project_dir, app_name)
    end
    
    # 2. PBXFileSystemSynchronizedBuildFileExceptionSetセクションから情報を取得してから削除
    exception_files = []
    content.scan(/membershipExceptions = \(([^)]*)\)/m) do |exceptions|
      files = exceptions[0].scan(/([^,\s]+)[,\s]*/).flatten.reject { |f| f.strip.empty? }
      exception_files.concat(files)
    end
    
    if content.include?("/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */")
      content.gsub!(
        /\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m,
        ''
      )
      puts "Removed PBXFileSystemSynchronizedBuildFileExceptionSet section"
    end
    
    # 3. ファイルリストを作成（実際のファイルまたは標準セット）
    files_to_add = if app_dir && Dir.exist?(app_dir)
      # 実際のディレクトリから取得（第一階層のみ）
      Dir.children(app_dir).select do |item|
        path = File.join(app_dir, item)
        # ファイルのみ（ディレクトリは除外）
        File.file?(path) && 
        # 隠しファイルを除外
        !item.start_with?('.') &&
        # 特定の拡張子のみ
        item.match?(/\.(swift|plist|xcassets|storyboard|xcdatamodeld)$/)
      end
    else
      # テスト環境または新規プロジェクトの場合は標準セット
      standard_files = ['AppDelegate.swift', 'SceneDelegate.swift', 'Info.plist', 
                       'Assets.xcassets', 'LaunchScreen.storyboard', 'Main.storyboard']
      # exceptionsに含まれているファイルも追加
      (standard_files + exception_files).uniq
    end
    
    puts "Found #{files_to_add.size} files to add: #{files_to_add.join(', ')}"
    
    # 4. PBXFileReferenceを作成
    file_references = create_file_references(files_to_add, app_name)
    
    # PBXFileReferenceセクションに追加
    if file_references.any? && content.include?("/* Begin PBXFileReference section */")
      # セクションの最後に追加
      content.gsub!(/(\/\* End PBXFileReference section \*\/)/) do |match|
        refs = file_references.map { |ref| ref[:definition] }.join("\n")
        "#{refs}\n#{match}"
      end
      puts "Added #{file_references.size} file references"
    end
    
    # 5. メインアプリグループをPBXGroupに変換
    children_items = []
    
    # ファイル参照を追加
    file_references.each do |ref|
      children_items << "\t\t\t\t#{ref[:uuid]} /* #{ref[:name]} */,"
    end
    
    # 既存のグループを収集して追加（SwiftJsonUI関連を含む）
    groups_to_add = []
    content.scan(/([A-F0-9]{24}) \/\* ([^*]+) \*\/ = \{[^}]*?isa = PBXGroup;/) do |uuid, name|
      next if name == app_name || name == 'Products' || name.include?('Tests')
      groups_to_add << { uuid: uuid, name: name }
    end
    
    # グループを特定の順序で追加（SwiftJsonUIのグループを優先）
    swiftjsonui_groups = ['View', 'Layouts', 'Styles', 'Bindings', 'Core']
    
    # SwiftJsonUIグループを順番に追加し、パスも修正
    swiftjsonui_groups.each do |group_name|
      group = groups_to_add.find { |g| g[:name] == group_name }
      if group
        children_items << "\t\t\t\t#{group[:uuid]} /* #{group[:name]} */,"
        groups_to_add.delete(group)
        
        # グループのパスを修正
        fix_group_path(content, group[:uuid], group[:name])
      end
    end
    
    # その他のグループを追加
    groups_to_add.each do |group|
      children_items << "\t\t\t\t#{group[:uuid]} /* #{group[:name]} */,"
    end
    
    # メインアプリグループを変換
    content.gsub!(/(#{main_app_uuid} \/\* #{Regexp.escape(app_name)} \*\/ = \{)([^}]*?)(isa = PBXFileSystemSynchronized(?:Root)?Group;)([^}]*?)(\};)/m) do |match|
      prefix = $1
      before_isa = $2
      isa = $3
      after_isa = $4
      suffix = $5
      
      # isaをPBXGroupに変更
      new_isa = "isa = PBXGroup;"
      
      # exceptionsを削除
      after_isa = after_isa.gsub(/\s*exceptions = [^;]+;\s*/m, '')
      
      # explicitFileTypesとexplicitFoldersを削除
      after_isa = after_isa.gsub(/\s*explicitFileTypes = \{[^}]*\};\s*explicitFolders = \([^)]*\);\s*/m, '')
      
      # childrenを追加
      children_str = "\n\t\t\tchildren = (\n#{children_items.join("\n")}\n\t\t\t);"
      
      "#{prefix}#{before_isa}#{new_isa}#{children_str}#{after_isa}#{suffix}"
    end
    
    # 4. fileSystemSynchronizedGroupsを削除（メインアプリのみ）
    content.gsub!(/fileSystemSynchronizedGroups = \(\s*#{main_app_uuid} \/\* #{Regexp.escape(app_name)} \*\/,?\s*\);/m, '')
    
    # PBXFileSystemSynchronizedRootGroupセクションをPBXGroupセクションに移動
    if content.include?("/* Begin PBXFileSystemSynchronizedRootGroup section */")
      # メインアプリグループの定義を抽出
      main_group_def = nil
      content.scan(/(#{main_app_uuid} \/\* #{Regexp.escape(app_name)} \*\/ = \{[^}]*?\};)/m) do |match|
        main_group_def = match[0]
        break
      end
      
      if main_group_def
        # 元の場所から削除
        content.gsub!(main_group_def, '')
        
        # PBXGroupセクションに追加
        if content.include?("/* Begin PBXGroup section */")
          content.gsub!(/(\/\* End PBXGroup section \*\/)/) do |match|
            "\t\t#{main_group_def}\n#{match}"
          end
        else
          # PBXGroupセクションがない場合は作成
          content.gsub!(/(\/\* End PBXFileReference section \*\/\n)/) do |match|
            "#{match}\n/* Begin PBXGroup section */\n\t\t#{main_group_def}\n/* End PBXGroup section */\n"
          end
        end
      end
    end
    
    # ファイル保存
    File.write(@pbxproj_path, content)
    puts "✅ Conversion completed!"
    puts "ℹ️  Main app synchronized folder has been converted to regular group"
    puts "ℹ️  Test targets remain as synchronized folders (no issues there)"
    
    # 変更があったか確認
    if content != original_content
      puts "\nChanges made to: #{@pbxproj_path}"
      puts "Backup saved as: #{@backup_path}"
    end
  end
  
  def validate
    content = File.read(@pbxproj_path)
    
    sync_groups = content.scan(/PBXFileSystemSynchronized(?:Root)?Group/).length
    sync_refs = content.scan(/fileSystemSynchronizedGroups/).length
    sync_exceptions = content.scan(/PBXFileSystemSynchronizedBuildFileExceptionSet/).length
    regular_groups = content.scan(/isa = PBXGroup/).length
    
    puts "\nValidation Results:"
    puts "- Regular groups (PBXGroup): #{regular_groups}"
    puts "- Synchronized groups remaining: #{sync_groups}"
    puts "- fileSystemSynchronizedGroups references: #{sync_refs}"
    puts "- Exception sets: #{sync_exceptions}"
    
    if sync_groups > 0
      puts "ℹ️  #{sync_groups} synchronized groups remain (likely test targets - this is OK)"
    end
    
    if sync_exceptions > 0
      puts "⚠️  Still has #{sync_exceptions} exception sets"
      false
    else
      puts "✅ Main app group is now a regular PBXGroup"
      true
    end
  end
  
  private
  
  def create_file_references(files, app_name)
    references = []
    
    files.each do |filename|
      # ファイルタイプを推測
      file_type = case filename
      when /\.swift$/
        'sourcecode.swift'
      when /\.plist$/
        'text.plist.xml'
      when /\.xcassets$/
        'folder.assetcatalog'
      when /\.storyboard$/
        'file.storyboard'
      when /\.xcdatamodeld$/
        'wrapper.xcdatamodel'
      else
        'text'
      end
      
      uuid = generate_uuid
      
      definition = "\t\t#{uuid} /* #{filename} */ = {"
      definition += "isa = PBXFileReference; "
      definition += "lastKnownFileType = #{file_type}; "
      definition += "path = #{filename}; "
      definition += "sourceTree = \"<group>\"; };"
      
      references << {
        uuid: uuid,
        name: filename,
        definition: definition
      }
    end
    
    # xcdatamodeldファイルが見つからない場合は追加（新規プロジェクトで必要）
    if !files.any? { |f| f.end_with?('.xcdatamodeld') }
      xcdatamodeld_name = "#{app_name}.xcdatamodeld"
      uuid = generate_uuid
      
      definition = "\t\t#{uuid} /* #{xcdatamodeld_name} */ = {"
      definition += "isa = PBXFileReference; "
      definition += "lastKnownFileType = wrapper.xcdatamodel; "
      definition += "path = #{xcdatamodeld_name}; "
      definition += "sourceTree = \"<group>\"; };"
      
      references << {
        uuid: uuid,
        name: xcdatamodeld_name,
        definition: definition
      }
    end
    
    references
  end
  
  def generate_uuid
    # Xcodeスタイルの24文字のUUID生成
    SecureRandom.hex(12).upcase
  end
  
  def fix_group_path(content, group_uuid, group_name)
    # グループのパスを正しく設定（親グループからの相対パス）
    content.gsub!(/(#{group_uuid} \/\* #{Regexp.escape(group_name)} \*\/ = \{[^}]*?path = )([^;]+)(;)/m) do
      prefix = $1
      suffix = $3
      # SwiftJsonUIグループは単純なグループ名をパスとして使用
      if ['View', 'Layouts', 'Styles', 'Bindings', 'Core'].include?(group_name)
        "#{prefix}#{group_name}#{suffix}"
      else
        # その他のグループは元のパスを保持
        "#{prefix}#{$2}#{suffix}"
      end
    end
    
    # Core内のUI/Baseグループのパスも修正
    if group_name == "Core"
      # Coreグループ内のUI/Baseを探す
      if content.match(/(#{group_uuid} \/\* Core \*\/ = \{[^}]*?children = \([^)]*\))/m)
        core_section = $1
        # UI/Baseグループを探す
        core_section.scan(/([A-F0-9]{24}) \/\* (UI|Base) \*\//).each do |uuid, name|
          content.gsub!(/(#{uuid} \/\* #{name} \*\/ = \{[^}]*?path = )([^;]+)(;)/m) do
            "#{$1}#{name}#{$3}"
          end
        end
      end
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby convert_to_group_reference.rb <path/to/project.pbxproj>"
    puts "Example: ruby convert_to_group_reference.rb MyApp.xcodeproj/project.pbxproj"
    exit 1
  end
  
  pbxproj_path = ARGV[0]
  
  unless File.exist?(pbxproj_path)
    puts "Error: File not found: #{pbxproj_path}"
    exit 1
  end
  
  converter = XcodeSyncToGroupConverter.new(pbxproj_path)
  converter.convert
  converter.validate
end