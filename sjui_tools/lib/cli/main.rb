# frozen_string_literal: true

require_relative 'version'
require_relative '../core/config_manager'

module SjuiTools
  module CLI
    class Main
      COMMANDS = {
        'init' => 'Initialize a new project',
        'setup' => 'Setup library and project structure',
        'generate' => 'Generate files (view, partial, collection, binding)',
        'g' => 'Alias for generate',
        'build' => 'Build binding files',
        'convert' => 'Convert JSON to SwiftUI code',
        'watch' => 'Watch for file changes',
        'hotload' => 'Start HotLoader server',
        'server' => 'Alias for hotload',
        'validate' => 'Validate JSON files',
        'version' => 'Show version',
        'help' => 'Show this help message'
      }.freeze

      def run(args)
        command = args.shift || 'help'
        
        # Handle shortcuts
        command = 'generate' if command == 'g'
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

      def show_help
        puts "SwiftJsonUI Unified Tools v#{VERSION}"
        puts
        puts "Usage: sjui COMMAND [options]"
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
        puts "  sjui build                   # Build binding files"
        puts "  sjui watch                   # Watch for changes"
        puts "  sjui hotload                 # Start HotLoader server"
        puts
        puts "For more information on a command, run:"
        puts "  sjui help COMMAND"
      end
    end
  end
end