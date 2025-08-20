#!/usr/bin/env ruby

require "fileutils"
require "json"
require_relative "destroyer"
require_relative "binding_destroyer"
require_relative '../../../core/project_finder'
require_relative '../../../core/config_manager'

class ViewDestroyer < Destroyer
  def initialize(project_file_path = nil)
    super(project_file_path)
    base_dir = File.expand_path('../..', File.dirname(__FILE__))
    
    # ProjectFinderを使用してパスを設定
    paths = ProjectFinder.setup_paths(base_dir, @project_file_path)
    @view_path = paths.view_path
    @layout_path = paths.layout_path
    @binding_destroyer = BindingDestroyer.new(@project_file_path)
  end

  def destroy(view_name)
    # 名前の正規化
    camel_name = view_name.split('_').map(&:capitalize).join
    snake_name = view_name.downcase
    
    puts "Destroying view files for: #{camel_name}"
    
    # 1. ファイルパスの構築
    view_folder_path = "#{@view_path}/#{camel_name}"
    view_controller_path = "#{view_folder_path}/#{camel_name}ViewController.swift"
    json_path = "#{@layout_path}/#{snake_name}.json"
    
    # 2. ファイルの存在確認
    files_to_remove = []
    
    if File.exist?(view_controller_path)
      files_to_remove << view_controller_path
    else
      puts "Warning: ViewController file not found: #{view_controller_path}"
    end
    
    if File.exist?(json_path)
      files_to_remove << json_path
    else
      puts "Warning: JSON layout file not found: #{json_path}"
    end
    
    if files_to_remove.empty?
      puts "No view files found to destroy for view: #{camel_name}"
      return
    end
    
    # 3. Xcodeプロジェクトから削除（ViewControllerとJSONファイル）
    file_names = [
      "#{camel_name}ViewController.swift",
      "#{snake_name}.json"
    ]
    remove_from_xcode_project_with_group(file_names, camel_name, files_to_remove)
    
    # 4. Bindingファイルを削除（別のDestroyerを使用）
    @binding_destroyer.destroy(view_name)
    
    # 5. ファイルシステムからファイルを削除
    delete_files(files_to_remove)
    
    # 6. 空のフォルダを削除
    if Dir.exist?(view_folder_path) && Dir.empty?(view_folder_path)
      Dir.rmdir(view_folder_path)
      puts "Deleted empty folder: #{view_folder_path}"
    end
    
    puts "Successfully destroyed view: #{camel_name}"
  end

  private

  def remove_from_xcode_project_with_group(file_names, folder_name, created_files = [])
    # グループも含めたファイル名を準備
    all_file_names = file_names.dup
    
    # フォルダグループのUUIDも取得するため、フォルダ名も含める
    remove_from_xcode_project(all_file_names, created_files) do |lines|
      collect_uuids_for_files_with_group(lines, file_names, folder_name)
    end
  end

  def collect_uuids_for_files_with_group(lines, file_names, folder_name)
    uuids = []
    
    lines.each do |line|
      file_names.each do |file_name|
        # PBXFileReference entries - より厳密なマッチング
        if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(file_name)} \*\/ = \{isa = PBXFileReference/)
          uuids << $1
          puts "Found FileReference UUID for #{file_name}: #{$1}"
        # PBXBuildFile entries (Sources)
        elsif line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(file_name)} in Sources \*\/ = \{isa = PBXBuildFile/)
          uuids << $1
          puts "Found BuildFile UUID for #{file_name}: #{$1}"
        # PBXBuildFile entries (Resources)
        elsif line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(file_name)} in Resources \*\/ = \{isa = PBXBuildFile/)  
          uuids << $1
          puts "Found BuildFile UUID for #{file_name}: #{$1}"
        end
      end
      
      # PBXGroup entries
      if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(folder_name)} \*\/ = \{isa = PBXGroup/)
        uuids << $1
        puts "Found Folder Group UUID: #{$1}"
      end
    end
    
    uuids.uniq
  end

end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: ruby view_destroyer.rb <view_name>"
    puts "Example: ruby view_destroyer.rb sample"
    exit 1
  end

  view_name = ARGV[0]
  
  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../", __FILE__)
    project_file_path = ProjectFinder.find_project_file(binding_builder_dir)
    destroyer = ViewDestroyer.new(project_file_path)
    destroyer.destroy(view_name)
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end