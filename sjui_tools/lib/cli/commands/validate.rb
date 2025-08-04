# frozen_string_literal: true

require 'json'
require_relative '../../core/command_base'
require_relative '../../core/project_finder'
require_relative '../../core/config_manager'

module SjuiTools
  module CLI
    module Commands
      class Validate < Core::CommandBase
        def run(args)
          files = []
          verbose = false
          
          # Parse arguments
          while arg = args.shift
            case arg
            when '--verbose', '-v'
              verbose = true
            when '--help', '-h'
              show_help
              return
            else
              files << arg
            end
          end
          
          # Check if project exists
          unless project_exists?
            puts "Error: No iOS project found. Please run this command in a directory containing a .xcodeproj file."
            exit 1
          end
          
          # Setup paths
          Core::ProjectFinder.setup_paths
          config = Core::ConfigManager.load_config
          source_path = Core::ProjectFinder.get_full_source_path
          
          # If no files specified, validate all JSON files in layouts directory
          if files.empty?
            layouts_dir = File.join(source_path, config['layouts_directory'])
            files = Dir.glob(File.join(layouts_dir, '**/*.json'))
          else
            # Convert relative paths to absolute
            files = files.map do |file|
              if File.absolute_path?(file)
                file
              else
                File.expand_path(file)
              end
            end
          end
          
          errors = []
          
          files.each do |file|
            next unless File.exist?(file)
            
            begin
              content = File.read(file)
              JSON.parse(content)
              puts "✓ Valid: #{file}" if verbose
            rescue JSON::ParserError => e
              errors << { file: file, error: e.message }
              puts "✗ Invalid: #{file}"
              puts "  #{e.message}" if verbose
            end
          end
          
          if errors.empty?
            puts "All #{files.size} file(s) are valid JSON." unless verbose
            exit 0
          else
            puts "\n#{errors.size} file(s) have JSON errors:"
            errors.each do |error|
              puts "  - #{error[:file]}"
              puts "    #{error[:error]}" if verbose
            end
            exit 1
          end
        end
        
        private
        
        def show_help
          puts "Usage: sjui validate [files...] [options]"
          puts
          puts "Options:"
          puts "  --verbose, -v      Show detailed error messages"
          puts "  --help, -h         Show this help message"
          puts
          puts "Examples:"
          puts "  sjui validate                           # Validate all JSON files in layouts directory"
          puts "  sjui validate Layouts/main.json        # Validate specific file"
          puts "  sjui validate Layouts/**/*.json        # Validate files matching pattern"
        end
      end
    end
  end
end