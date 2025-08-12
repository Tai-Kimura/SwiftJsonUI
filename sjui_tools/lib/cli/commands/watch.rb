# frozen_string_literal: true

require 'optparse'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'
require_relative '../../core/file_watcher'

module SjuiTools
  module CLI
    module Commands
      class Watch
        def run(args)
          options = parse_options(args)
          
          # Detect mode
          mode = options[:mode] || Core::ConfigManager.detect_mode
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            puts "Error: Could not find project file"
            exit 1
          end
          
          puts "Starting watch mode (#{mode})..."
          puts "Press Ctrl+C to stop"
          
          case mode
          when 'uikit', 'all'
            watch_uikit
          when 'swiftui'
            watch_swiftui
          else
            puts "Error: Unknown mode: #{mode}"
            exit 1
          end
        end

        private

        def parse_options(args)
          options = {}
          
          OptionParser.new do |opts|
            opts.banner = "Usage: sjui watch [options]"
            
            opts.on('--mode MODE', ['all', 'uikit', 'swiftui'], 
                    'Watch mode (all, uikit, swiftui)') do |mode|
              options[:mode] = mode
            end
            
            opts.on('-h', '--help', 'Show this help message') do
              puts opts
              exit
            end
          end.parse!(args)
          
          options
        end

        def watch_uikit
          config = Core::ConfigManager.load_config
          source_path = Core::ProjectFinder.get_full_source_path
          
          layouts_dir = File.join(source_path, config['layouts_directory'])
          styles_dir = File.join(source_path, config['styles_directory'])
          
          require_relative '../../uikit/json_loader'
          
          # Initial build
          puts "Running initial build..."
          loader = UIKit::JsonLoader.new
          loader.start_analyze
          
          # Setup file watcher
          watcher = Core::FileWatcher.new([layouts_dir, styles_dir], extensions: ['json']) do |file, type|
            puts "\nFile #{type}: #{file}"
            puts "Rebuilding binding files..."
            
            loader = UIKit::JsonLoader.new
            loader.start_analyze
          end
          
          watcher.start
          
          # Keep the process running
          begin
            sleep
          rescue Interrupt
            puts "\nStopping watch mode..."
            watcher.stop
          end
        end

        def watch_swiftui
          puts "SwiftUI watch mode not yet implemented"
          # TODO: Implement SwiftUI watch
        end
      end
    end
  end
end