#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative "../xcode_project_manager"
require_relative "../../project_finder"
require_relative "../pbxproj_manager"
require_relative "../generators/ui_view_creator_generator"
require_relative "../generators/base_view_controller_generator"
require_relative "../generators/base_binding_generator"
require_relative "../generators/base_collection_view_cell_generator"

class DirectorySetup < PbxprojManager
  def initialize(project_file_path = nil)
    super(project_file_path)
    base_dir = File.expand_path('../..', File.dirname(__FILE__))
    
    # ProjectFinderを使用してパスを設定
    @paths = ProjectFinder.setup_paths(base_dir, @project_file_path)
    @xcode_manager = XcodeProjectManager.new(@project_file_path)
  end

  def create_missing_directories
    puts "Checking and creating missing directories..."
    
    directories_to_create = []
    
    # 各ディレクトリの存在をチェック
    check_and_add_directory(@paths.view_path, "View", directories_to_create)
    check_and_add_directory(@paths.layout_path, "Layouts", directories_to_create)
    check_and_add_directory(@paths.style_path, "Styles", directories_to_create)
    check_and_add_directory(@paths.bindings_path, "Bindings", directories_to_create)
    check_and_add_directory(@paths.core_path, "Core", directories_to_create)
    check_and_add_directory(@paths.ui_path, "UI", directories_to_create)
    check_and_add_directory(@paths.base_path, "Base", directories_to_create)
    
    unless directories_to_create.empty?
      # ディレクトリを作成
      directories_to_create.each do |dir_info|
        FileUtils.mkdir_p(dir_info[:path])
        puts "Created directory: #{dir_info[:path]}"
      end
      
      # Xcodeプロジェクトに追加
      add_directories_to_xcode_project(directories_to_create)
    end
    
    # ディレクトリが作成されたかどうかに関係なく、必要なCoreファイルをチェック・作成
    create_core_files_if_needed
    
    puts "Directory creation completed successfully!"
  end

  private

  def check_and_add_directory(path, name, directories_to_create)
    unless Dir.exist?(path)
      directories_to_create << {
        path: path,
        name: name,
        relative_path: get_relative_path(path)
      }
      puts "  Missing: #{path}"
    else
      puts "  Exists: #{path}"
    end
  end

  def get_relative_path(full_path)
    # プロジェクトルートからの相対パスを取得
    project_root = File.dirname(File.dirname(@project_file_path))
    Pathname.new(full_path).relative_path_from(Pathname.new(project_root)).to_s
  end

  def add_directories_to_xcode_project(directories_to_create)
    return if directories_to_create.empty?
    
    puts "Adding directories to Xcode project..."
    
    safe_pbxproj_operation([], []) do
      # Coreグループを最初に追加（UI/Baseが内部で作成されるため）
      core_dir = directories_to_create.find { |d| d[:name] == "Core" }
      other_dirs = directories_to_create.reject { |d| d[:name] == "Core" || d[:name] == "UI" || d[:name] == "Base" }
      
      # Coreを最初に追加
      if core_dir
        puts "  Adding Core group to Xcode project (will include UI and Base)..."
        @xcode_manager.add_folder_group(core_dir[:name], core_dir[:relative_path])
      end
      
      # その他のディレクトリを追加
      other_dirs.each do |dir_info|
        folder_name = dir_info[:name]
        puts "  Adding #{folder_name} group to Xcode project..."
        @xcode_manager.add_folder_group(folder_name, dir_info[:relative_path])
      end
      
      puts "Successfully added directories to Xcode project"
    end
  end



  def create_core_files_if_needed
    puts "Checking for missing core files..."
    created_files = []
    
    # ディレクトリの存在をチェック
    ui_exists = Dir.exist?(@paths.ui_path)
    base_exists = Dir.exist?(@paths.base_path)
    
    # UIViewCreator.swift をチェック・作成
    if ui_exists
      ui_view_creator_file = File.join(@paths.ui_path, "UIViewCreator.swift")
      unless File.exist?(ui_view_creator_file)
        puts "  Missing: UIViewCreator.swift"
        ui_generator = UIViewCreatorGenerator.new(@project_file_path)
        ui_view_creator_path = ui_generator.generate(@paths.ui_path)
        created_files << ui_view_creator_path if ui_view_creator_path
      else
        puts "  Exists: UIViewCreator.swift"
      end
    end
    
    # BaseViewController.swift をチェック・作成
    if base_exists
      base_vc_file = File.join(@paths.base_path, "BaseViewController.swift")
      unless File.exist?(base_vc_file)
        puts "  Missing: BaseViewController.swift"
        base_vc_generator = BaseViewControllerGenerator.new(@project_file_path)
        base_view_controller_path = base_vc_generator.generate(@paths.base_path)
        created_files << base_view_controller_path if base_view_controller_path
      else
        puts "  Exists: BaseViewController.swift"
      end
    end
    
    # BaseBinding.swift をチェック・作成
    if base_exists
      base_binding_file = File.join(@paths.base_path, "BaseBinding.swift")
      unless File.exist?(base_binding_file)
        puts "  Missing: BaseBinding.swift"
        base_binding_generator = BaseBindingGenerator.new(@project_file_path)
        base_binding_path = base_binding_generator.generate(@paths.base_path)
        created_files << base_binding_path if base_binding_path
      else
        puts "  Exists: BaseBinding.swift"
      end
    end
    
    # BaseCollectionViewCell.swift をチェック・作成
    if base_exists
      base_cell_file = File.join(@paths.base_path, "BaseCollectionViewCell.swift")
      unless File.exist?(base_cell_file)
        puts "  Missing: BaseCollectionViewCell.swift"
        base_cell_generator = BaseCollectionViewCellGenerator.new(@project_file_path)
        base_cell_path = base_cell_generator.generate(@paths.base_path)
        created_files << base_cell_path if base_cell_path
      else
        puts "  Exists: BaseCollectionViewCell.swift"
      end
    end
    
    # 作成されたファイルをXcodeプロジェクトに追加
    unless created_files.empty?
      puts "Created #{created_files.size} missing core files"
      add_core_files_to_xcode_project(created_files)
    else
      puts "All core files already exist"
    end
  end

  def add_core_files_to_xcode_project(file_paths)
    safe_pbxproj_operation([], file_paths) do
      file_paths.each do |file_path|
        # グループ名を決定
        if file_path.include?("/UI/")
          group_name = "UI"
        elsif file_path.include?("/Base/")
          group_name = "Base"
        else
          group_name = "Core"
        end
        
        # CoreFileAdderを使用してファイルを追加
        @xcode_manager.add_core_file(file_path, group_name)
      end
      puts "Added core files to Xcode project"
    end
  end
end

