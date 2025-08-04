# frozen_string_literal: true

require_relative '../../core/command_base'
require_relative '../../hotloader/server'

module SjuiTools
  module CLI
    module Commands
      class Hotload < Core::CommandBase
        def run(args)
          port = 8080
          
          # Parse arguments
          while arg = args.shift
            case arg
            when '--port', '-p'
              port = args.shift.to_i
            when '--help', '-h'
              show_help
              return
            else
              puts "Unknown option: #{arg}"
              show_help
              exit 1
            end
          end
          
          puts "Starting HotLoader server..."
          
          # Check if project exists
          unless project_exists?
            puts "Error: No iOS project found. Please run this command in a directory containing a .xcodeproj file."
            exit 1
          end
          
          # Start the server
          SjuiTools::HotLoader::Server.start(port: port)
        rescue Interrupt
          puts "\nShutting down HotLoader server..."
          exit 0
        rescue => e
          puts "Error: #{e.message}"
          puts e.backtrace if ENV['DEBUG']
          exit 1
        end
        
        private
        
        def show_help
          puts "Usage: sjui hotload [options]"
          puts
          puts "Options:"
          puts "  --port, -p PORT    Server port (default: 8080)"
          puts "  --help, -h         Show this help message"
          puts
          puts "Examples:"
          puts "  sjui hotload                 # Start server on default port 8080"
          puts "  sjui hotload --port 3000     # Start server on port 3000"
        end
      end
    end
  end
end