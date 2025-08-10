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
          
          # 4. Cleanup project references (before membership exceptions)
          common_setup.cleanup_project_references
          
          # 5. Setup membership exceptions (MUST be last - after all project.save calls)
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
          
          # Create Generated directory for SwiftUI output
          if config['swiftui'] && config['swiftui']['output_directory']
            output_dir = config['swiftui']['output_directory']
            output_path = File.join(source_path, output_dir)
            unless Dir.exist?(output_path)
              FileUtils.mkdir_p(output_path)
              puts "Created directory: #{output_dir}"
            end
          end
        end
      end
    end
  end
end