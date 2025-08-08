# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'

module SjuiTools
  module CLI
    module Commands
      class Setup
        def run(args)
          options = parse_options(args)
          
          # Check and install dependencies first
          ensure_dependencies_installed
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            puts "Error: Could not find project file (.xcodeproj)"
            puts "Please run this command in an iOS project directory"
            exit 1
          end
          
          # Load config to determine mode
          config = Core::ConfigManager.load_config
          mode = config['mode'] || 'binding'
          
          puts "Setting up SwiftJsonUI project in #{mode} mode..."
          
          # Setup library if Xcode project (this handles everything)
          if Core::ProjectFinder.project_file_path&.end_with?('.xcodeproj')
            if mode == 'swiftui'
              setup_swiftui_project
            else
              setup_library
            end
          else
            puts "Error: No Xcode project found"
            exit 1
          end
          
          puts "\nSetup complete!"
          if mode == 'swiftui'
            puts "Next steps:"
            puts "  1. Create your layouts in the Layouts directory"
            puts "  2. Run 'sjui convert' to generate SwiftUI code"
            puts "  3. Build your project to download the SwiftJsonUI dependencies"
          else
            puts "Next steps:"
            puts "  1. Run 'sjui g view HomeView' to generate your first view"
            puts "  2. Build your project to download the SwiftJsonUI dependencies"
          end
        end

        private

        def ensure_dependencies_installed
          # Check if Gemfile.lock exists
          sjui_tools_dir = File.expand_path('../../../..', __FILE__)
          gemfile_lock = File.join(sjui_tools_dir, 'Gemfile.lock')
          
          unless File.exist?(gemfile_lock)
            puts "Installing sjui_tools dependencies..."
            Dir.chdir(sjui_tools_dir) do
              success = system('bundle install')
              unless success
                puts "Warning: Failed to install some dependencies"
                puts "You may need to install them manually with: cd sjui_tools && bundle install"
              end
            end
          end
        end

        def parse_options(args)
          options = {}
          
          OptionParser.new do |opts|
            opts.banner = "Usage: sjui setup [options]"
            
            opts.on('-h', '--help', 'Show this help message') do
              puts opts
              exit
            end
          end.parse!(args)
          
          options
        end


        def setup_library
          require_relative '../../binding/xcode_project/setup/setup'
          
          # Use the full setup from the original setup.rb
          setup = ::SjuiTools::Binding::XcodeProject::Setup::Setup.new(Core::ProjectFinder.project_file_path)
          setup.run_full_setup
        end

        def setup_swiftui_project
          puts "=== Starting SwiftUI Project Setup ==="
          
          # Use CommonSetup for shared functionality
          require_relative '../../core/setup/common_setup'
          common_setup = ::SjuiTools::Core::Setup::CommonSetup.new(Core::ProjectFinder.project_file_path)
          
          # 1. Ensure workspace exists (for SPM)
          common_setup.ensure_workspace_exists
          
          # 2. Create directories for SwiftUI mode
          create_swiftui_directories
          
          # 3. Setup libraries (same as binding mode)
          common_setup.setup_libraries
          
          # 4. Setup membership exceptions
          common_setup.setup_membership_exceptions
          
          # 5. Cleanup project references
          common_setup.cleanup_project_references
          
          puts "=== SwiftUI Project Setup Completed Successfully! ==="
        end

        def create_swiftui_directories
          puts "Creating SwiftUI project directories..."
          
          # Load config to get directory names
          config = Core::ConfigManager.load_config
          source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          
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