# frozen_string_literal: true

require_relative 'version'
require_relative '../core/config_manager'
require_relative '../core/logger'

module SjuiTools
  module CLI
    class Main
      COMMANDS = {
        'init' => 'Initialize a new project',
        'setup' => 'Setup library and project structure',
        'generate' => 'Generate files (view, partial, collection, binding)',
        'g' => 'Alias for generate',
        'destroy' => 'Destroy files (view, partial, collection, binding)',
        'd' => 'Alias for destroy',
        'build' => 'Build UIKit/SwiftUI files',
        'convert' => 'Convert JSON to SwiftUI code',
        'watch' => 'Watch for file changes',
        'hotload' => 'Start HotLoader server',
        'server' => 'Alias for hotload',
        'validate' => 'Validate JSON files',
        'version' => 'Show version',
        'help' => 'Show this help message'
      }.freeze

      def run(args)
        # Parse global options
        parse_global_options(args)
        
        command = args.shift || 'help'
        
        # Handle shortcuts
        command = 'generate' if command == 'g'
        command = 'destroy' if command == 'd'
        command = 'hotload' if command == 'server'
        
        case command
        when 'init'
          require_relative 'commands/init'
          Commands::Init.new.run(args)
        when 'setup'
          require_relative 'commands/setup'
          Commands::Setup.new.run(args)
        when 'generate', 'g'
          require_relative 'commands/generate'
          Commands::Generate.new.run(args)
        when 'destroy', 'd'
          require_relative 'commands/destroy'
          Commands::Destroy.new.run(args)
        when 'build'
          require_relative 'commands/build'
          Commands::Build.new.run(args)
        when 'convert'
          require_relative 'commands/convert'
          Commands::Convert.new.run(args)
        when 'watch'
          require_relative 'commands/watch'
          Commands::Watch.new.run(args)
        when 'hotload', 'server'
          require_relative 'commands/hotload'
          Commands::Hotload.new.run(args)
        when 'validate'
          require_relative 'commands/validate'
          Commands::Validate.new.run(args)
        when 'version'
          puts "sjui version #{VERSION}"
        when 'help', '--help', '-h'
          show_help
        else
          puts "Unknown command: #{command}"
          puts
          show_help
          exit 1
        end
      rescue => e
        puts "Error: #{e.message}"
        puts e.backtrace if ENV['DEBUG']
        exit 1
      end

      private

      def parse_global_options(args)
        # Extract log level option if present
        log_level_index = args.index('--log-level')
        if log_level_index
          args.delete_at(log_level_index)
          if log_level_index < args.length
            log_level = args.delete_at(log_level_index)
            Core::Logger.set_level(log_level)
          else
            Core::Logger.error "Missing value for --log-level option"
            exit 1
          end
        end
        
        # Also check for shorthand versions
        if args.include?('--quiet') || args.include?('-q')
          args.delete('--quiet')
          args.delete('-q')
          Core::Logger.set_level(:error)
        elsif args.include?('--verbose') || args.include?('-v')
          args.delete('--verbose')
          args.delete('-v')
          Core::Logger.set_level(:debug)
        end
      end

      def show_help
        puts "SwiftJsonUI Unified Tools v#{VERSION}"
        puts
        puts "Usage: sjui COMMAND [options]"
        puts
        puts "Global Options:"
        puts "  --log-level LEVEL   Set log level (error, warn, info, debug)"
        puts "  --quiet, -q         Show only errors (same as --log-level error)"
        puts "  --verbose, -v       Show debug information (same as --log-level debug)"
        puts
        puts "Commands:"
        
        COMMANDS.each do |cmd, desc|
          puts "  #{cmd.ljust(12)} #{desc}"
        end
        
        puts
        puts "Examples:"
        puts "  sjui init                    # Initialize a new project"
        puts "  sjui setup                   # Setup project structure"
        puts "  sjui g view HomeView         # Generate a new view"
        puts "  sjui d view splash           # Destroy a view and its files"
        puts "  sjui build                   # Build UIKit/SwiftUI files"
        puts "  sjui build --quiet           # Build with only error output"
        puts "  sjui watch                   # Watch for changes"
        puts "  sjui hotload                 # Start HotLoader server"
        puts
        puts "For more information on a command, run:"
        puts "  sjui help COMMAND"
      end
    end
  end
end