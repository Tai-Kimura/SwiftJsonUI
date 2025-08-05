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
          
          puts "Setting up SwiftJsonUI project..."
          
          # Setup library if Xcode project (this handles everything)
          if Core::ProjectFinder.project_file_path&.end_with?('.xcodeproj')
            setup_library
          else
            puts "Error: No Xcode project found"
            exit 1
          end
          
          puts "\nSetup complete!"
          puts "Next steps:"
          puts "  1. Run 'sjui g view HomeView' to generate your first view"
          puts "  2. Build your project to download the SwiftJsonUI dependencies"
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
      end
    end
  end
end