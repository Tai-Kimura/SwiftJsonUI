#!/usr/bin/env ruby

require 'fileutils'
require 'json'

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
    
    # PBXFileSystemSynchronizedRootGroupをPBXGroupに変換
    if content.include?("PBXFileSystemSynchronizedRootGroup")
      content.gsub!(/isa = PBXFileSystemSynchronizedRootGroup;/, 'isa = PBXGroup;')
      converted = true
      puts "Converted PBXFileSystemSynchronizedRootGroup to PBXGroup"
    end
    
    # PBXFileSystemSynchronizedGroupをPBXGroupに変換
    if content.include?("PBXFileSystemSynchronizedGroup")
      content.gsub!(/isa = PBXFileSystemSynchronizedGroup;/, 'isa = PBXGroup;')
      converted = true
      puts "Converted PBXFileSystemSynchronizedGroup to PBXGroup"
    end
    
    # explicitFileTypesとexplicitFoldersを削除してchildrenに置き換え
    content.gsub!(/explicitFileTypes = \{[^}]*\};\s*explicitFolders = \([^)]*\);/m) do
      "children = (\n\t\t\t);"
    end
    
    if converted
      # ファイル保存
      File.write(@pbxproj_path, content)
      puts "✅ Conversion completed!"
      puts "⚠️  IMPORTANT: You need to manually add file references to the groups"
      puts "   Open Xcode and use 'Add Files to...' to re-add your files"
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
    regular_groups = content.scan(/isa = PBXGroup/).length
    
    puts "\nValidation Results:"
    puts "- Regular groups (PBXGroup): #{regular_groups}"
    puts "- Synchronized groups: #{sync_groups}"
    
    if sync_groups > 0
      puts "⚠️  Still has #{sync_groups} synchronized groups"
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