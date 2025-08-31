# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'

module SjuiTools
  module CLI
    module Commands
      class Init
        def run(args)
          options = parse_options(args)
          
          # Check if MODE file exists (set by installer)
          installer_mode = nil
          mode_file = File.join(File.dirname(__FILE__), '../../../../MODE')
          if File.exist?(mode_file)
            installer_mode = File.read(mode_file).strip
          end
          
          # Detect or use specified mode
          mode = options[:mode] || installer_mode || Core::ConfigManager.detect_mode
          
          puts "Initializing SwiftJsonUI project in #{mode} mode..."
          
          # Create config file
          create_config_file(mode)
          
          # Create directory structure based on mode
          case mode
          when 'uikit'
            create_uikit_structure
          when 'swiftui'
            create_swiftui_structure
          when 'all'
            create_uikit_structure
            create_swiftui_structure
          end
          
          puts "Initialization complete!"
          puts
          if mode == 'swiftui'
            puts "SwiftUI mode initialized. Use SwiftUI-specific commands for your project."
          else
            puts "Next steps:"
            puts "  1. Run 'sjui setup' to install libraries and base files"
            puts "  2. Run 'sjui g view HomeView' to generate your first view"
          end
        end

        private

        def parse_options(args)
          options = {}
          
          OptionParser.new do |opts|
            opts.banner = "Usage: sjui init [options]"
            
            opts.on('--mode MODE', ['all', 'uikit', 'swiftui'], 
                    'Initialize mode (all, uikit, swiftui)') do |mode|
              options[:mode] = mode
            end
            
            opts.on('-h', '--help', 'Show this help message') do
              puts opts
              exit
            end
          end.parse!(args)
          
          options
        end

        def create_config_file(mode)
          config_file = 'sjui.config.json'
          
          if File.exist?(config_file)
            puts "Config file already exists: #{config_file}"
            # Check if source_directory needs to be updated
            existing_config = JSON.parse(File.read(config_file))
            if existing_config['source_directory'].to_s.empty?
              Core::ProjectFinder.setup_paths
              # Auto-detect source directory without checking config
              project_dir = Core::ProjectFinder.project_dir
              
              # If project_dir is nil, fallback to finding xcodeproj
              if project_dir.nil?
                xcodeproj = Dir.glob('*.xcodeproj').first || Dir.glob('../*.xcodeproj').first
                project_dir = xcodeproj ? File.dirname(File.expand_path(xcodeproj)) : Dir.pwd
              end
              
              common_names = ['Sources', 'Source', 'src', File.basename(project_dir)]
              
              source_dir = nil
              common_names.each do |name|
                path = File.join(project_dir, name)
                if Dir.exist?(path)
                  source_dir = name
                  break
                end
              end
              
              if source_dir && !source_dir.empty?
                existing_config['source_directory'] = source_dir
                File.write(config_file, JSON.pretty_generate(existing_config))
                puts "Updated source_directory to: #{source_dir}"
              end
            end
            return
          end
          
          # Find project info
          Core::ProjectFinder.setup_paths
          project_name = if Core::ProjectFinder.project_file_path
            File.basename(Core::ProjectFinder.project_file_path, '.*')
          else
            File.basename(Dir.pwd)
          end
          
          # Create base config based on mode
          if mode == 'swiftui'
            # SwiftUI-specific config with appropriate defaults
            config = {
              'mode' => mode,
              'project_name' => project_name,
              'project_file_name' => project_name,
              'source_directory' => project_name,  # For SwiftUI, typically the project name directory
              'layouts_directory' => 'Layouts',
              'styles_directory' => 'Styles',
              'view_directory' => 'View',
              'data_directory' => 'Data',  # Directory for data binding structs
              'viewmodel_directory' => 'ViewModel',  # Directory for ViewModels
              'resource_manager_directory' => 'ResourceManager',  # Directory for resource managers
              'string_files' => [
                "#{project_name}/Localizable.strings"
              ],
              'use_network' => true,  # SwiftUI mode can use network for API calls
              'hotloader' => {
                'ip' => '127.0.0.1',
                'port' => 8081,
                'watch_directories' => ['Layouts', 'Styles']
              }
            }
          else
            # UIKit mode or all mode config
            config = {
              'mode' => mode,
              'project_name' => project_name,
              'project_file_name' => project_name,
              'source_directory' => Core::ProjectFinder.find_source_directory || '',
              'layouts_directory' => 'Layouts',
              'styles_directory' => 'Styles',
              'view_directory' => 'View',
              'data_directory' => 'Data',  # Directory for data binding structs
              'viewmodel_directory' => 'ViewModel',  # Directory for ViewModels
              'bindings_directory' => 'Bindings',
              'hot_loader_directory' => project_name,
              'string_files' => [
                "#{project_name}/Localizable.strings"
              ],
              'use_network' => true,
              'hotloader' => {
                'ip' => '127.0.0.1',
                'port' => 8081,
                'watch_directories' => ['Layouts', 'Styles']
              }
            }
            
            # No SwiftUI-specific config needed for 'all' mode anymore
          end
          
          File.write(config_file, JSON.pretty_generate(config))
          puts "Created config file: #{config_file}"
        end

        def create_uikit_structure
          # Read config to get directory names
          config = Core::ConfigManager.load_config
          layouts_dir = config['layouts_directory'] || 'Layouts'
          
          directories = [
            layouts_dir,
            "#{layouts_dir}/Resources",  # Add Resources subfolder
            'Bindings',
            'View',
            'Data',
            'ViewModel',
            'Styles',
            'Core',
            'Core/Base',
            'Core/UI'
          ]
          
          create_directories(directories)
        end

        def create_swiftui_structure
          # Read config to get directory names
          config = Core::ConfigManager.load_config
          layouts_dir = config['layouts_directory'] || 'Layouts'
          
          directories = [
            layouts_dir,
            "#{layouts_dir}/Resources",  # Add Resources subfolder
            config['view_directory'] || 'View',
            config['data_directory'] || 'Data',
            config['viewmodel_directory'] || 'ViewModel',
            config['styles_directory'] || 'Styles'
          ]
          
          # SwiftUI doesn't need Generated directory anymore
          
          create_directories(directories)
        end

        def create_directories(directories)
          source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          
          directories.each do |dir|
            path = File.join(source_path, dir)
            unless Dir.exist?(path)
              FileUtils.mkdir_p(path)
              puts "Created directory: #{dir}"
            end
          end
        end
      end
    end
  end
end