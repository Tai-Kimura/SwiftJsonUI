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
# 1. Converts PBXFileSystemSynchronizedRootGroup → PBXGroup
# 2. Converts PBXFileSystemSynchronizedGroup → PBXGroup
# 3. Removes PBXFileSystemSynchronizedBuildFileExceptionSet sections
# 4. Adds empty children arrays to groups
# 5. Links converted groups to their parent groups (maintains hierarchy)
# 6. Ensures Core group contains UI and Base subgroups
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
# - Groups will be empty (no file references)
# - You'll need to manually add files back to groups in Xcode
# - This restores the traditional behavior where you explicitly control which files are included

require 'fileutils'
require 'json'
require 'time'

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
    
    # 変換実行
    converted = false
    
    # 1. セクション名を変換
    # PBXFileSystemSynchronizedRootGroupセクションをPBXGroupセクションに変換
    if content.include?("/* Begin PBXFileSystemSynchronizedRootGroup section */")
      content.gsub!(
        /\/\* Begin PBXFileSystemSynchronizedRootGroup section \*\//,
        '/* Begin PBXGroup section */'
      )
      content.gsub!(
        /\/\* End PBXFileSystemSynchronizedRootGroup section \*\//,
        '/* End PBXGroup section */'
      )
      converted = true
      puts "Converted PBXFileSystemSynchronizedRootGroup section to PBXGroup section"
    end
    
    # PBXFileSystemSynchronizedGroupセクションも同様に
    if content.include?("/* Begin PBXFileSystemSynchronizedGroup section */")
      content.gsub!(
        /\/\* Begin PBXFileSystemSynchronizedGroup section \*\//,
        '/* Begin PBXGroup section */'
      )
      content.gsub!(
        /\/\* End PBXFileSystemSynchronizedGroup section \*\//,
        '/* End PBXGroup section */'
      )
      converted = true
      puts "Converted PBXFileSystemSynchronizedGroup section to PBXGroup section"
    end
    
    # 2. isa = PBXFileSystemSynchronized* を PBXGroup に変換
    if content.include?("PBXFileSystemSynchronizedRootGroup")
      content.gsub!(/isa = PBXFileSystemSynchronizedRootGroup;/, 'isa = PBXGroup;')
      converted = true
      puts "Converted isa = PBXFileSystemSynchronizedRootGroup to PBXGroup"
    end
    
    if content.include?("PBXFileSystemSynchronizedGroup")
      content.gsub!(/isa = PBXFileSystemSynchronizedGroup;/, 'isa = PBXGroup;')
      converted = true
      puts "Converted isa = PBXFileSystemSynchronizedGroup to PBXGroup"
    end
    
    # 3. 既存のファイル情報を収集
    file_references_by_group = {}
    group_uuids = {}
    
    # まず、グループのUUIDを収集
    content.scan(/([A-F0-9]{24}) \/\* ([^*]+) \*\/ = \{[^}]*?isa = PBX(?:FileSystem)?(?:Synchronized)?(?:Root)?Group;/) do |uuid, name|
      group_uuids[name] = uuid
      puts "DEBUG: Found group #{name} with UUID #{uuid}"
    end
    
    # exceptionsがある場合、そのファイル参照を収集
    content.scan(/([A-F0-9]{24}) \/\* Exceptions for "([^"]+)" folder.*?\*\/ = \{[^}]*?membershipExceptions = \(([^)]*)\)/m) do |exception_uuid, folder_name, exceptions|
      files = exceptions.scan(/([^,\s]+)[,\s]*/).flatten.reject { |f| f.strip.empty? }
      puts "DEBUG: Found #{files.length} files in #{folder_name} folder exceptions"
      
      # 各ファイルのUUIDを探す
      file_uuids = []
      files.each do |file|
        # ファイル名からPBXFileReferenceのUUIDを検索
        if match = content.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(file)} \*\/ = \{[^}]*?isa = PBXFileReference/)
          file_uuids << "#{match[1]} /* #{file} */"
          puts "  Found file reference: #{file} -> #{match[1]}"
        end
      end
      
      file_references_by_group[folder_name] = file_uuids if file_uuids.any?
    end
    
    # 4. explicitFileTypesとexplicitFoldersを削除してchildrenに置き換え
    content.gsub!(/explicitFileTypes = \{[^}]*\};\s*explicitFolders = \([^)]*\);/m) do
      "children = (\n\t\t\t);"
    end
    
    # 4.5. 各グループの変換処理を改善
    group_uuids.each do |group_name, group_uuid|
      # グループ定義を見つけて変換
      content.gsub!(/(#{group_uuid} \/\* #{Regexp.escape(group_name)} \*\/ = \{[^}]*?)(\};)/m) do |match|
        group_content = $1
        suffix = $2
        
        # exceptionsを削除
        group_content.gsub!(/\s*exceptions = [^;]+;\s*/m, '')
        
        # childrenがない場合は追加
        unless group_content.include?("children =")
          # ファイル参照があれば追加
          if file_references_by_group[group_name] && file_references_by_group[group_name].any?
            children_items = file_references_by_group[group_name].map { |ref| "\t\t\t\t#{ref}," }.join("\n")
            group_content += "\n\t\t\tchildren = (\n#{children_items}\n\t\t\t);"
          else
            group_content += "\n\t\t\tchildren = (\n\t\t\t);"
          end
        else
          # 既存のchildrenが空の場合、ファイル参照を追加
          if file_references_by_group[group_name] && file_references_by_group[group_name].any?
            group_content.gsub!(/children = \(\s*\);/m) do
              children_items = file_references_by_group[group_name].map { |ref| "\t\t\t\t#{ref}," }.join("\n")
              "children = (\n#{children_items}\n\t\t\t);"
            end
          end
        end
        
        "#{group_content}#{suffix}"
      end
    end
    
    # 3.5. グループ定義内のchildrenがないものに空のchildrenを追加
    # PBXGroupセクション内のグループでchildrenがないものを修正
    content.gsub!(/(isa = PBXGroup;[^}]*?)(path = [^;]+;)(\s*sourceTree = [^;]+;)(\s*\};)/m) do |match|
      if match.include?("children =")
        match
      else
        "#{$1}children = (\n\t\t\t);\n\t\t\t#{$2}#{$3}#{$4}"
      end
    end
    
    # 4. PBXFileSystemSynchronizedBuildFileExceptionSetセクションを削除
    if content.include?("/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */")
      content.gsub!(
        /\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m,
        ''
      )
      converted = true
      puts "Removed PBXFileSystemSynchronizedBuildFileExceptionSet section"
    end
    
    # 5. exceptionsへの参照を削除（既に上で処理済みだが念のため）
    content.gsub!(/\s*exceptions = \([^)]*\);\s*/m, '')
    content.gsub!(/\s*exceptions = [A-F0-9]{24} \/\* [^*]* \*\/;\s*/m, '')
    
    # 6. 複数のPBXGroupセクションをマージ
    group_sections = content.scan(/\/\* Begin PBXGroup section \*\/(.*?)\/\* End PBXGroup section \*\//m)
    if group_sections.length > 1
      # すべてのグループエントリを集める
      all_groups = group_sections.map { |section| section[0].strip }.join("\n")
      
      # 最初のPBXGroupセクションにすべてをまとめる
      content.sub!(
        /\/\* Begin PBXGroup section \*\/.*?\/\* End PBXGroup section \*\//m,
        "/* Begin PBXGroup section */\n#{all_groups}\n/* End PBXGroup section */"
      )
      
      # 残りのPBXGroupセクションを削除
      while content.scan(/\/\* Begin PBXGroup section \*\//m).length > 1
        # 2番目以降のPBXGroupセクションを削除
        content.sub!(
          /\/\* End PBXGroup section \*\/(.*?)\/\* Begin PBXGroup section \*\/.*?\/\* End PBXGroup section \*\//m,
          '/* End PBXGroup section */\1'
        )
      end
      
      puts "Merged multiple PBXGroup sections into one"
    end
    
    if converted
      # 7. メインアプリグループにchildrenを追加（もし存在しない場合）
      # 既存のグループのUUIDを収集
      existing_groups = {}
      content.scan(/([A-F0-9]{24}) \/\* (View|Layouts|Styles|Bindings|Core|UI|Base) \*\/ = \{/) do |uuid, name|
        existing_groups[name] = uuid
        puts "DEBUG: Found group #{name} with UUID #{uuid}"
      end
      
      if existing_groups.empty?
        puts "INFO: No SwiftJsonUI groups found in the project"
        puts "     This is normal for new projects. Run 'sjui setup' after this to create the groups."
      end
      
      # メインアプリグループを見つけて、childrenを追加
      project_dir = File.dirname(File.dirname(@pbxproj_path))
      app_name = File.basename(project_dir, '.xcodeproj')
      
      # メインアプリグループのUUIDを動的に検出
      puts "DEBUG: Looking for main app group: #{app_name}"
      main_app_group_uuid = nil
      
      # より柔軟なパターンでメインアプリグループを検索
      content.scan(/([A-F0-9]{24}) \/\* #{Regexp.escape(app_name)} \*\/ = \{[^}]*?isa = PBXGroup;[^}]*?\}/m) do |uuid|
        group_content = $&
        # pathかexceptionsを含むものがメインアプリグループ
        if group_content.include?("path = #{app_name}") || group_content.include?("exceptions =")
          main_app_group_uuid = uuid[0]
          puts "DEBUG: Found main app group UUID: #{main_app_group_uuid}"
          break
        end
      end
      
      if main_app_group_uuid
        # メインアプリグループのパターンを探す
        content.gsub!(/(#{main_app_group_uuid} \/\* #{Regexp.escape(app_name)} \*\/ = \{[^}]*?isa = PBXGroup;)([^}]*?)(\};)/m) do |match|
        prefix = $1
        middle = $2
        suffix = $3
        
        if !middle.include?("children =")
          puts "DEBUG: Main app group has no children, adding..."
          # childrenがない場合、追加する
          children_array = []
          
          # 標準的な順序でグループを追加
          ['View', 'Layouts', 'Styles', 'Bindings', 'Core'].each do |group_name|
            if existing_groups[group_name]
              children_array << "\t\t\t\t#{existing_groups[group_name]} /* #{group_name} */,"
              puts "DEBUG: Adding #{group_name} to children"
            end
          end
          
          if children_array.any?
            children_str = "\n\t\t\tchildren = (\n#{children_array.join("\n")}\n\t\t\t);"
            "#{prefix}#{children_str}#{middle}#{suffix}"
          else
            match
          end
        else
          # childrenが既にある場合、既存のグループを確認して不足分を追加
          existing_children = middle[/children = \((.*?)\);/m, 1]
          
          children_to_add = []
          ['View', 'Layouts', 'Styles', 'Bindings', 'Core'].each do |group_name|
            if existing_groups[group_name] && !existing_children.include?(existing_groups[group_name])
              children_to_add << "\t\t\t\t#{existing_groups[group_name]} /* #{group_name} */,"
            end
          end
          
          if children_to_add.any?
            middle.gsub!(/children = \(\s*(.*?)\s*\);/m) do |children_match|
              existing_items = $1.strip
              if existing_items.empty?
                "children = (\n#{children_to_add.join("\n")}\n\t\t\t);"
              else
                "children = (\n\t\t\t\t#{existing_items}\n#{children_to_add.join("\n")}\n\t\t\t);"
              end
            end
          end
          
          "#{prefix}#{middle}#{suffix}"
        end
      end
      else
        puts "WARNING: Could not find main app group for #{app_name}"
      end
      
      # Core グループにUI、Baseサブグループを追加
      if existing_groups['Core'] && (existing_groups['UI'] || existing_groups['Base'])
        content.gsub!(/(#{existing_groups['Core']} \/\* Core \*\/ = \{[^}]*?isa = PBXGroup;)([^}]*?)(\};)/m) do |match|
          prefix = $1
          middle = $2
          suffix = $3
          
          if !middle.include?("children =")
            children_array = []
            ['UI', 'Base'].each do |group_name|
              if existing_groups[group_name]
                children_array << "\t\t\t\t#{existing_groups[group_name]} /* #{group_name} */,"
              end
            end
            
            if children_array.any?
              children_str = "\n\t\t\tchildren = (\n#{children_array.join("\n")}\n\t\t\t);"
              "#{prefix}#{children_str}#{middle}#{suffix}"
            else
              match
            end
          else
            match
          end
        end
      end
      
      puts "✅ Groups linked to parent groups"
      
      # 8. 収集したファイル参照を各グループに追加
      if file_references_by_group.any?
        puts "\nAdding file references to groups..."
        
        file_references_by_group.each do |group_name, file_uuids|
          puts "Adding #{file_uuids.length} files to #{group_name} group"
          
          # グループを検索して、childrenに追加
          content.gsub!(/(\/\* #{Regexp.escape(group_name)} \*\/ = \{[^}]*?children = \()([^)]*)(\);)/m) do |match|
            prefix = $1
            existing_children = $2.strip
            suffix = $3
            
            # 既存のchildrenと新しいファイルを結合
            all_children = []
            all_children << existing_children unless existing_children.empty?
            file_uuids.each { |uuid| all_children << "\t\t\t\t#{uuid}," }
            
            "#{prefix}\n#{all_children.join("\n")}\n\t\t\t#{suffix}"
          end
        end
      end
      
      # 変換情報を保存（setupで使用）
      if file_references_by_group.any?
        project_dir = File.dirname(@pbxproj_path)
        conversion_info = {
          'conversion_date' => Time.now.iso8601,
          'file_references' => file_references_by_group
        }
        File.write(File.join(project_dir, '.conversion_info.json'), JSON.pretty_generate(conversion_info))
        puts "Saved conversion info for file restoration"
      end
      
      # ファイル保存
      File.write(@pbxproj_path, content)
      puts "✅ Conversion completed!"
      puts "ℹ️  Synchronized folders have been converted to regular groups"
      
      if existing_groups.empty?
        puts "\n📝 Next step: Run 'sjui setup' to create the SwiftJsonUI directory structure"
        puts "   Your existing files (AppDelegate, SceneDelegate, etc.) will be restored."
      else
        puts "\n📝 Groups have been relinked. You may need to manually add files back to groups in Xcode"
      end
    else
      puts "No synchronized groups found. Project may already be using group references."
    end
    
    # 変更があったか確認
    if content != original_content
      puts "\nChanges made to: #{@pbxproj_path}"
      puts "Backup saved as: #{@backup_path}"
      puts "\nNext steps:"
      puts "1. Open the project in Xcode"
      puts "2. You may see empty groups - this is expected"
      puts "3. Right-click on each empty group and 'Add Files to...'"
      puts "4. Select the corresponding folder and choose 'Create groups'"
      puts "5. Make sure to check the target membership"
    end
  end
  
  def validate
    content = File.read(@pbxproj_path)
    
    sync_groups = content.scan(/PBXFileSystemSynchronized(?:Root)?Group/).length
    sync_sections = content.scan(/PBXFileSystemSynchronized/).length
    sync_exceptions = content.scan(/PBXFileSystemSynchronizedBuildFileExceptionSet/).length
    regular_groups = content.scan(/isa = PBXGroup/).length
    
    puts "\nValidation Results:"
    puts "- Regular groups (PBXGroup): #{regular_groups}"
    puts "- Synchronized groups: #{sync_groups}"
    puts "- Synchronized sections: #{sync_sections}"
    puts "- Exception sets: #{sync_exceptions}"
    
    if sync_sections > 0
      puts "⚠️  Still has #{sync_sections} synchronized references"
      
      # 詳細を表示
      if sync_groups > 0
        puts "  - PBXFileSystemSynchronized groups: #{sync_groups}"
      end
      if sync_exceptions > 0
        puts "  - PBXFileSystemSynchronizedBuildFileExceptionSet: #{sync_exceptions}"
      end
      
      false
    else
      puts "✅ All groups are regular PBXGroup references"
      true
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