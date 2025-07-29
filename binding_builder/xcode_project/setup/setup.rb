#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative "../pbxproj_manager"
require_relative "../../project_finder"

class Setup < PbxprojManager
  def initialize(project_file_path = nil)
    super(project_file_path)
  end

  def run_full_setup
    puts "=== Starting SwiftJsonUI Project Setup ==="
    
    # 1. ディレクトリ構造の作成
    setup_directories
    
    # 2. ライブラリパッケージの追加
    setup_libraries
    
    # 3. HotLoader機能の設定
    setup_hotloader
    
    # 4. HotLoad Build Phaseの設定
    setup_hotload_build_phase
    
    # 5. Info.plistからStoryBoard参照を削除
    remove_storyboard_from_info_plist
    
    # 6. membershipExceptionsを設定
    setup_membership_exceptions
    
    puts "=== SwiftJsonUI Project Setup Completed Successfully! ==="
  end

  private

  def setup_directories
    puts "Setting up project directories..."
    require_relative 'directory_setup'
    
    directory_setup = DirectorySetup.new(@project_file_path)
    directory_setup.create_missing_directories
  end

  def setup_libraries
    puts "Setting up required libraries..."
    require_relative 'library_setup'
    
    library_setup = LibrarySetup.new(@project_file_path)
    library_setup.setup_libraries
  end

  def setup_hotloader
    puts "Setting up HotLoader functionality..."
    require_relative 'app_delegate_setup'
    
    app_delegate_setup = AppDelegateSetup.new(@project_file_path)
    app_delegate_setup.add_hotloader_functionality
  end

  def setup_hotload_build_phase
    puts "Setting up HotLoad Build Phase..."
    require_relative 'hotload_setup'
    
    hotload_setup = HotLoadSetup.new(@project_file_path)
    hotload_setup.setup_hotload_build_phase
  end

  def remove_storyboard_from_info_plist
    puts "Removing StoryBoard references from Info.plist..."
    
    # Info.plistファイルを探す
    project_dir = File.dirname(File.dirname(@project_file_path))
    info_plist_path = find_info_plist_file(project_dir)
    
    if info_plist_path.nil?
      puts "Warning: Could not find Info.plist file. StoryBoard references not removed."
      return
    end

    puts "Updating Info.plist: #{info_plist_path}"
    
    # Info.plistの内容を読み込む
    content = File.read(info_plist_path)
    
    # 既にStoryBoard参照が削除されているかチェック
    unless content.include?("UISceneStoryboardFile")
      puts "StoryBoard references already removed from Info.plist"
      return
    end
    
    # StoryBoard参照を削除
    updated_content = remove_storyboard_references(content)
    
    # ファイルに書き戻す
    File.write(info_plist_path, updated_content)
    puts "StoryBoard references removed from Info.plist successfully"
  end

  def find_info_plist_file(project_dir)
    # プロジェクトディレクトリから再帰的にInfo.plistを検索
    Dir.glob("#{project_dir}/**/Info.plist").first
  end

  def remove_storyboard_references(content)
    # UISceneStoryboardFileキーとその値を削除
    content = content.gsub(/\s*<key>UISceneStoryboardFile<\/key>\s*\n\s*<string>.*?<\/string>\s*\n/, "")
    content
  end
end

# コマンドライン実行
if __FILE__ == $0
  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../../", __FILE__)
    project_file_path = ProjectFinder.find_project_file(binding_builder_dir)
    setup = Setup.new(project_file_path)
    setup.run_full_setup
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end