#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative '../../core/pbxproj_manager'
require_relative '../../core/project_finder'
require_relative '../../core/config_manager'

module SjuiTools
  module SwiftUI
    module Setup
      class SwiftUISetup < ::SjuiTools::Core::PbxprojManager
        def initialize(project_file_path = nil)
          super(project_file_path)
        end

        def run_full_setup
          puts "=== Starting SwiftUI Project Setup ==="
          
          # Use CommonSetup for shared functionality
          require_relative '../../core/setup/common_setup'
          common_setup = ::SjuiTools::Core::Setup::CommonSetup.new(@project_file_path)
          
          # 1. Ensure workspace exists (for SPM)
          common_setup.ensure_workspace_exists
          
          # 2. Create directories for SwiftUI mode
          create_swiftui_directories
          
          # 3. Setup libraries (same as binding mode)
          common_setup.setup_libraries
          
          # 4. Generate HotLoader setup file for SwiftUI
          generate_hotloader_setup
          
          # 5. Add sjui.config.json to Xcode project for bundle access
          add_config_to_project
          
          # 6. Cleanup project references (before membership exceptions)
          common_setup.cleanup_project_references
          
          # 7. Setup membership exceptions (MUST be last - after all project.save calls)
          common_setup.setup_membership_exceptions
          
          puts "=== SwiftUI Project Setup Completed Successfully! ==="
        end

        private

        def create_swiftui_directories
          puts "Creating SwiftUI project directories..."
          
          # Load config to get directory names
          config = ::SjuiTools::Core::ConfigManager.load_config
          source_path = ::SjuiTools::Core::ProjectFinder.get_full_source_path || Dir.pwd
          
          # Create Layouts directory
          layouts_dir = config['layouts_directory'] || 'Layouts'
          layouts_path = File.join(source_path, layouts_dir)
          unless Dir.exist?(layouts_path)
            FileUtils.mkdir_p(layouts_path)
            puts "Created directory: #{layouts_dir}"
          end
          
          # Create Styles directory
          styles_dir = config['styles_directory'] || 'Styles'
          styles_path = File.join(source_path, styles_dir)
          unless Dir.exist?(styles_path)
            FileUtils.mkdir_p(styles_path)
            puts "Created directory: #{styles_dir}"
          end
          
          # Create ViewModel directory
          viewmodel_dir = config['viewmodel_directory'] || 'ViewModel'
          viewmodel_path = File.join(source_path, viewmodel_dir)
          unless Dir.exist?(viewmodel_path)
            FileUtils.mkdir_p(viewmodel_path)
            puts "Created directory: #{viewmodel_dir}"
          end
          
          # Create ResourceManager directory
          resource_manager_dir = config['resource_manager_directory'] || 'ResourceManager'
          resource_manager_path = File.join(source_path, resource_manager_dir)
          unless Dir.exist?(resource_manager_path)
            FileUtils.mkdir_p(resource_manager_path)
            puts "Created directory: #{resource_manager_dir}"
          end
          
          # Create StringManager.swift in ResourceManager directory
          create_string_manager_file(resource_manager_path)
          
          # SwiftUI doesn't need Generated directory anymore
          # Views are generated directly in the View directory
        end
        
        def generate_hotloader_setup
          puts "Generating HotLoader setup for SwiftUI..."
          
          require_relative 'hotloader_generator'
          
          # Get the source path
          source_path = ::SjuiTools::Core::ProjectFinder.get_full_source_path || Dir.pwd
          
          # Generate HotLoaderSetup.swift in the main app directory
          hotloader_path = File.join(source_path, 'HotLoaderSetup.swift')
          ::SjuiTools::SwiftUI::Setup::HotLoaderGenerator.generate(hotloader_path)
          
          # Add the file to Xcode project if not already there
          add_file_to_project(hotloader_path)
        end
        
        def add_file_to_project(file_path)
          return unless File.exist?(file_path)
          
          require 'xcodeproj'
          project_path = @project_file_path
          project = Xcodeproj::Project.open(project_path)
          
          # Find the main group
          main_group = project.main_group
          target = project.targets.first
          
          # Check if file already exists in project
          file_name = File.basename(file_path)
          existing_file = main_group.files.find { |f| f.display_name == file_name }
          
          unless existing_file
            # Add file reference to project
            file_ref = main_group.new_file(file_path)
            
            # Add to target's compile sources or resources based on file type
            if file_path.end_with?('.swift')
              target.add_file_references([file_ref])
            else
              # Add as resource for non-Swift files (like .json)
              target.add_resources([file_ref])
            end
            
            project.save
            puts "Added #{file_name} to Xcode project"
          end
        end
        
        def add_config_to_project
          puts "Adding sjui.config.json to Xcode project as resource..."
          
          # Get the source path
          source_path = ::SjuiTools::Core::ProjectFinder.get_full_source_path || Dir.pwd
          config_path = File.join(source_path, '..', 'sjui.config.json')
          
          if File.exist?(config_path)
            add_file_to_project(config_path)
          else
            puts "Warning: sjui.config.json not found at #{config_path}"
          end
        end
        
        def create_string_manager_file(resource_manager_path)
          string_manager_path = File.join(resource_manager_path, 'StringManager.swift')
          unless File.exist?(string_manager_path)
            # Create empty StringManager.swift file
            File.write(string_manager_path, "// StringManager.swift\n// Implementation will be added separately\n")
            puts "Created file: StringManager.swift"
            
            # Add to Xcode project
            add_file_to_project(string_manager_path)
          else
            puts "File already exists: StringManager.swift"
          end
        end
      end
    end
  end
end