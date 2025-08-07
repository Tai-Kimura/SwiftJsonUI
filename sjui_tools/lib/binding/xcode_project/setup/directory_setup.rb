#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "ostruct"
require_relative '../../../core/xcode_project_manager'
require_relative '../../../core/project_finder'
require_relative '../../../core/config_manager'
require_relative '../../../core/pbxproj_manager'
require_relative '../generators/ui_view_creator_generator'
require_relative '../generators/base_view_controller_generator'
require_relative '../generators/base_binding_generator'
require_relative '../generators/base_collection_view_cell_generator'

module SjuiTools
  module Binding
    module XcodeProject
      module Setup
        class DirectorySetup < ::SjuiTools::Core::PbxprojManager
          def initialize(project_file_path = nil)
            super(project_file_path)
            base_dir = File.expand_path('../..', File.dirname(__FILE__))
            
            # ProjectFinderを使用してパスを設定
            Core::ProjectFinder.setup_paths(@project_file_path)
            
            # Get configuration
            config = Core::ConfigManager.load_config
            
            # Set paths based on configuration
            source_path = Core::ProjectFinder.get_full_source_path
            
            # Create a simple object to hold paths (matching 6.3.0 structure)
            @paths = OpenStruct.new(
              source_path: source_path,
              sjui_source_path: source_path,  # For compatibility
              view_path: File.join(source_path, config['view_directory'] || 'View'),
              bindings_path: File.join(source_path, config['bindings_directory'] || 'Bindings'),
              layouts_path: File.join(source_path, config['layouts_directory'] || 'Layouts'),
              layout_path: File.join(source_path, config['layouts_directory'] || 'Layouts'),  # alias
              styles_path: File.join(source_path, config['styles_directory'] || 'Styles'),
              style_path: File.join(source_path, config['styles_directory'] || 'Styles'),  # alias
              core_path: File.join(source_path, 'Core'),
              ui_path: File.join(source_path, 'Core', 'UI'),
              base_path: File.join(source_path, 'Core', 'Base')  # Base should be at same level as UI
            )
            
            @xcode_manager = ::SjuiTools::Core::XcodeProjectManager.new(@project_file_path)
          end

          def create_missing_directories
            puts "Checking and creating missing directories..."
            
            directories_to_create = []
            
            # 各ディレクトリの存在をチェック（6.3.0と同じ順序）
            check_and_add_directory(@paths.view_path, "View", directories_to_create)
            check_and_add_directory(@paths.layout_path, "Layouts", directories_to_create)
            check_and_add_directory(@paths.style_path, "Styles", directories_to_create)
            check_and_add_directory(@paths.bindings_path, "Bindings", directories_to_create)
            check_and_add_directory(@paths.core_path, "Core", directories_to_create)
            check_and_add_directory(@paths.ui_path, "UI", directories_to_create)
            check_and_add_directory(@paths.base_path, "Base", directories_to_create)
            
            unless directories_to_create.empty?
              # ディレクトリを作成（create_dirフラグがtrueの場合のみ）
              directories_to_create.each do |dir_info|
                if dir_info[:create_dir]
                  FileUtils.mkdir_p(dir_info[:path])
                  puts "Created directory: #{dir_info[:path]}"
                end
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
            dir_exists = Dir.exist?(path)
            
            # ディレクトリが存在しない場合は作成必要
            if !dir_exists
              puts "  Missing: #{path}"
            else
              puts "  Exists: #{path}"
            end
            
            # Xcodeプロジェクトにグループが存在するか確認
            # .xcodeprojディレクトリの場合は、project.pbxprojファイルを読む
            pbxproj_path = @project_file_path
            if @project_file_path.end_with?('.xcodeproj')
              pbxproj_path = File.join(@project_file_path, 'project.pbxproj')
            end
            
            project_content = File.read(pbxproj_path)
            group_exists = project_content.include?("/* #{name} */ = {")
            
            if !group_exists
              puts "    (Group not in Xcode project, will be added)"
            end
            
            # ディレクトリが存在しない、またはXcodeグループが存在しない場合は追加
            if !dir_exists || !group_exists
              directories_to_create << {
                path: path,
                name: name,
                relative_path: get_relative_path(path),
                create_dir: !dir_exists
              }
            end
          end

          def get_relative_path(full_path)
            # グループ名を返す（親グループからの相対パス）
            # 例: /path/to/project/Core -> Core
            File.basename(full_path)
          end

          def add_directories_to_xcode_project(directories_to_create)
            return if directories_to_create.empty?
            
            puts "Adding directories to Xcode project..."
            
            # Coreグループを最初に追加（UI/Baseが内部で作成されるため）
            core_dir = directories_to_create.find { |d| d[:name] == "Core" }
            other_dirs = directories_to_create.reject { |d| d[:name] == "Core" || d[:name] == "UI" || d[:name] == "Base" }
            
            # Coreを最初に追加
            if core_dir
              puts "  Adding Core group to Xcode project (will include UI and Base)..."
              @xcode_manager.add_directory(core_dir[:path], core_dir[:name])
            end
            
            # その他のディレクトリを追加
            other_dirs.each do |dir_info|
              folder_name = dir_info[:name]
              puts "  Adding #{folder_name} group to Xcode project..."
              @xcode_manager.add_directory(dir_info[:path], dir_info[:name])
            end
            
            puts "Successfully added directories to Xcode project"
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
                ui_generator = Generators::UIViewCreatorGenerator.new(@project_file_path)
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
                base_vc_generator = Generators::BaseViewControllerGenerator.new(@project_file_path)
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
                base_binding_generator = Generators::BaseBindingGenerator.new(@project_file_path)
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
                base_cell_generator = Generators::BaseCollectionViewCellGenerator.new(@project_file_path)
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
            file_paths.each do |file_path|
              # グループ名を決定
              if file_path.include?("/Core/UI/")
                group_name = "Core/UI"
              elsif file_path.include?("/Core/Base/")
                group_name = "Core/Base"
              elsif file_path.include?("/UI/")
                group_name = "UI"
              elsif file_path.include?("/Base/")
                group_name = "Base"
              else
                group_name = "Core"
              end
              
              # ファイルを追加
              @xcode_manager.add_file(file_path, group_name)
            end
            puts "Added core files to Xcode project"
          end
        end
      end
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../", __FILE__)
    project_file_path = SjuiTools::Core::ProjectFinder.find_project_file(binding_builder_dir)
    setup = SjuiTools::Binding::XcodeProject::Setup::DirectorySetup.new(project_file_path)
    setup.create_missing_directories
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end