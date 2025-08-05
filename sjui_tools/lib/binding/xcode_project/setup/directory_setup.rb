#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative '../../xcode_project_manager'
require_relative '../../../core/project_finder'
require_relative '../pbxproj_manager'
require_relative '../generators/ui_view_creator_generator'
require_relative '../generators/base_view_controller_generator'
require_relative '../generators/base_binding_generator'
require_relative '../generators/base_collection_view_cell_generator'

module SjuiTools
  module Binding
    module XcodeProject
      module Setup
        class DirectorySetup < ::SjuiTools::Binding::XcodeProject::PbxprojManager
          def initialize(project_file_path = nil)
            super(project_file_path)
            base_dir = File.expand_path('../..', File.dirname(__FILE__))
            
            # ProjectFinderを使用してパスを設定
            Core::ProjectFinder.setup_paths(@project_file_path)
            @xcode_manager = ::SjuiTools::Binding::XcodeProjectManager.new(@project_file_path)
          end

          def create_missing_directories
            puts "Checking for missing directories..."
            
            # 必要なディレクトリの構造
            directories_to_create = [
              { name: "View", path: @paths.view_path },
              { name: "Bindings", path: @paths.bindings_path },
              { name: "Layouts", path: @paths.layouts_path },
              { name: "Styles", path: @paths.styles_path },
              { name: "Core", path: @paths.core_path, 
                subdirs: ["UI", "UI/Base", "Extensions", "Json", "JsonUI", "Utilities"] }
            ]
            
            # ディレクトリの作成
            created_directories = []
            directories_to_create.each do |dir_info|
              if create_directory_structure(dir_info)
                created_directories << dir_info
              end
            end
            
            # Xcodeプロジェクトに追加
            if created_directories.any?
              add_directories_to_xcode_project(created_directories)
            end
            
            # CoreファイルとSwiftJsonUI-Bridging-Header.hを作成/確認
            setup_core_files
            
            puts "Directory setup completed"
          end

          private

          def create_directory_structure(dir_info)
            created = false
            
            # メインディレクトリ
            unless Dir.exist?(dir_info[:path])
              FileUtils.mkdir_p(dir_info[:path])
              puts "Created directory: #{dir_info[:path]}"
              created = true
            end
            
            # サブディレクトリ
            if dir_info[:subdirs]
              dir_info[:subdirs].each do |subdir|
                subdir_path = File.join(dir_info[:path], subdir)
                unless Dir.exist?(subdir_path)
                  FileUtils.mkdir_p(subdir_path)
                  puts "Created subdirectory: #{subdir_path}"
                  created = true
                end
              end
            end
            
            created
          end

          def add_directories_to_xcode_project(directories_to_create)
            return unless @xcode_manager
            
            puts "Adding directories to Xcode project..."
            
            # Coreグループを最初に追加（UI/Baseが内部で作成されるため）
            core_dir = directories_to_create.find { |d| d[:name] == "Core" }
            other_dirs = directories_to_create.reject { |d| d[:name] == "Core" || d[:name] == "UI" || d[:name] == "Base" }
            
            # Coreを最初に追加
            if core_dir
              @xcode_manager.add_directory(core_dir[:path], core_dir[:name])
            end
            
            # その他のディレクトリを追加
            other_dirs.each do |dir_info|
              @xcode_manager.add_directory(dir_info[:path], dir_info[:name])
            end
            
            puts "Successfully added directories to Xcode project"
          end

          def setup_core_files
            # UIViewCreator+SJUIを生成/確認
            if Generators::UIViewCreatorGenerator.check_or_generate(@paths)
              puts "UIViewCreator+SJUI.swift is ready"
            end
            
            # BaseViewControllerを生成/確認
            if Generators::BaseViewControllerGenerator.check_or_generate(@paths)
              puts "BaseViewController.swift is ready"
            end
            
            # BaseBindingを生成/確認
            if Generators::BaseBindingGenerator.check_or_generate(@paths)
              puts "BaseBinding.swift is ready"
            end
            
            # BaseCollectionViewCellを生成/確認
            if Generators::BaseCollectionViewCellGenerator.check_or_generate(@paths)
              puts "BaseCollectionViewCell.swift is ready"
            end
            
            # SwiftJsonUI-Bridging-Header.hの確認
            check_bridging_header
          end

          def check_bridging_header
            # プロジェクトのルートディレクトリを決定
            if @project_file_path.end_with?('.pbxproj')
              project_root = File.dirname(File.dirname(File.dirname(@project_file_path)))
            else
              project_root = File.dirname(@project_file_path)
            end
            
            # SwiftJsonUI-Bridging-Header.hのパスを探す
            possible_paths = [
              File.join(project_root, 'SwiftJsonUI-Bridging-Header.h'),
              File.join(@paths.source_path, 'SwiftJsonUI-Bridging-Header.h'),
              File.join(@paths.sjui_source_path, 'SwiftJsonUI-Bridging-Header.h')
            ]
            
            bridging_header_path = possible_paths.find { |path| File.exist?(path) }
            
            if bridging_header_path
              puts "Found bridging header: #{bridging_header_path}"
            else
              # デフォルトの場所に作成
              bridging_header_path = File.join(@paths.source_path, 'SwiftJsonUI-Bridging-Header.h')
              create_bridging_header(bridging_header_path)
              add_bridging_header_to_project(bridging_header_path)
            end
          end

          def create_bridging_header(path)
            content = <<~OBJC
              //
              //  SwiftJsonUI-Bridging-Header.h
              //
              
              #ifndef SwiftJsonUI_Bridging_Header_h
              #define SwiftJsonUI_Bridging_Header_h
              
              // Add Objective-C imports here if needed
              
              #endif /* SwiftJsonUI_Bridging_Header_h */
            OBJC
            
            File.write(path, content)
            puts "Created bridging header: #{path}"
          end

          def add_bridging_header_to_project(path)
            return unless @xcode_manager
            
            # プロジェクトのルートグループに追加
            @xcode_manager.add_file(path, nil)
            
            # TODO: Build Settingsの SWIFT_OBJC_BRIDGING_HEADER を設定する必要がある
            puts "Note: Please set 'Objective-C Bridging Header' in Build Settings to: $(SRCROOT)/#{File.basename(@paths.source_path)}/SwiftJsonUI-Bridging-Header.h"
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