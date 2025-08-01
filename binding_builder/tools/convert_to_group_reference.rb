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
# 2. Removes exceptions and fileSystemSynchronizedGroups references
# 3. Preserves test targets as synchronized (they don't have the same issues)
# 4. Maintains all existing file references in the project
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
    project_dir = File.dirname(File.dirname(@pbxproj_path))
    app_name = File.basename(project_dir, '.xcodeproj')
    
    # メインアプリグループのUUIDを探す
    main_app_uuid = nil
    content.scan(/([A-F0-9]{24}) \/\* #{Regexp.escape(app_name)} \*\/ = \{[^}]*?isa = PBXFileSystemSynchronized(?:Root)?Group;/) do |uuid|
      main_app_uuid = uuid[0]
      puts "Found main app synchronized group: #{main_app_uuid}"
      break
    end
    
    unless main_app_uuid
      puts "No synchronized groups found. Project may already be using group references."
      return
    end
    
    # 1. メインアプリグループをPBXGroupに変換
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
      
      # explicitFileTypesとexplicitFoldersをchildrenに置き換え
      if after_isa =~ /explicitFileTypes = \{[^}]*\};\s*explicitFolders = \([^)]*\);/m
        after_isa = after_isa.gsub(/explicitFileTypes = \{[^}]*\};\s*explicitFolders = \([^)]*\);/m, "children = (\n\t\t\t);")
      end
      
      # childrenがない場合は追加
      unless after_isa.include?("children =")
        after_isa = "\n\t\t\tchildren = (\n\t\t\t);" + after_isa
      end
      
      "#{prefix}#{before_isa}#{new_isa}#{after_isa}#{suffix}"
    end
    
    # 2. fileSystemSynchronizedGroupsを削除（メインアプリのみ）
    content.gsub!(/fileSystemSynchronizedGroups = \(\s*#{main_app_uuid} \/\* #{Regexp.escape(app_name)} \*\/,?\s*\);/m, '')
    
    # 3. PBXFileSystemSynchronizedBuildFileExceptionSetセクションを削除
    if content.include?("/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */")
      content.gsub!(
        /\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m,
        ''
      )
      puts "Removed PBXFileSystemSynchronizedBuildFileExceptionSet section"
    end
    
    # 4. 既存のファイル・グループ参照を収集してchildrenに追加
    # まず、すべてのグループとファイル参照を収集
    all_items = {}
    
    # PBXGroupを収集
    content.scan(/([A-F0-9]{24}) \/\* ([^*]+) \*\/ = \{[^}]*?isa = PBXGroup;/) do |uuid, name|
      next if name == app_name || name == 'Products' || name.include?('Tests')
      all_items[name] = { uuid: uuid, type: 'group' }
    end
    
    # PBXFileReferenceを収集（メインアプリに属するもの）
    content.scan(/([A-F0-9]{24}) \/\* ([^*]+) \*\/ = \{[^}]*?isa = PBXFileReference;[^}]*?path = ([^;]+);/) do |uuid, name, path|
      # メインアプリディレクトリに属するファイルのみ
      if path.include?(app_name) || name.match?(/\.(swift|plist|xcassets|storyboard|xcdatamodeld)$/)
        all_items[name] = { uuid: uuid, type: 'file' } unless name.include?('Tests')
      end
    end
    
    # メインアプリグループのchildrenを更新
    if all_items.any?
      content.gsub!(/(#{main_app_uuid} \/\* #{Regexp.escape(app_name)} \*\/ = \{[^}]*?children = \()(\s*\);)/m) do |match|
        prefix = $1
        suffix = $2
        
        children_items = []
        
        # 重要なファイルを優先的に追加
        priority_files = ['AppDelegate.swift', 'SceneDelegate.swift', 'Info.plist', 'Assets.xcassets']
        priority_files.each do |file|
          if all_items[file]
            children_items << "\t\t\t\t#{all_items[file][:uuid]} /* #{file} */,"
            all_items.delete(file)
          end
        end
        
        # 残りのアイテムを追加（グループ→ファイルの順）
        all_items.select { |_, v| v[:type] == 'group' }.each do |name, info|
          children_items << "\t\t\t\t#{info[:uuid]} /* #{name} */,"
        end
        
        all_items.select { |_, v| v[:type] == 'file' }.each do |name, info|
          children_items << "\t\t\t\t#{info[:uuid]} /* #{name} */,"
        end
        
        if children_items.any?
          "#{prefix}\n#{children_items.join("\n")}\n\t\t\t#{suffix}"
        else
          match
        end
      end
      
      puts "Added #{all_items.size} items to main app group"
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