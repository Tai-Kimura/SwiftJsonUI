# frozen_string_literal: true

require_relative '../command_base'
require_relative '../../hotloader/server'
require_relative '../../hotloader/ip_monitor'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'

module SjuiTools
  module CLI
    module Commands
      class Hotload < CommandBase
        def run(args)
          subcommand = args.first
          
          case subcommand
          when 'listen'
            args.shift
            run_listen(args)
          when 'stop'
            args.shift
            run_stop(args)
          when 'status'
            args.shift
            run_status(args)
          when '--help', '-h', 'help'
            show_help
          else
            # Default to listen for backward compatibility
            run_listen(args)
          end
        rescue Interrupt
          puts "\nShutting down HotLoader..."
          exit 0
        rescue => e
          puts "Error: #{e.message}"
          puts e.backtrace if ENV['DEBUG']
          exit 1
        end
        
        private
        
        def run_listen(args)
          port = 8081
          
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
          
          puts "🚀 Starting HotLoader development environment..."
          
          # Setup paths first
          unless Core::ProjectFinder.setup_paths
            puts "Error: No iOS project found. Please run this command in a directory containing a .xcodeproj file."
            exit 1
          end
          
          # Start IP monitor
          puts "🔄 Starting IP address monitor..."
          @ip_monitor = SjuiTools::Hotloader::IpMonitor.new
          @ip_monitor.start
          
          # Start HotLoader server
          puts "🌐 Starting HotLoader server on port #{port}..."
          puts "📡 WebSocket endpoint: ws://localhost:#{port}/websocket"
          puts "📂 Layout API: http://localhost:#{port}/layout/:name"
          puts "\n✅ HotLoader is ready!"
          puts "Press Ctrl+C to stop all services"
          
          # Trap interrupt signal to clean up
          trap('INT') do
            puts "\n🛑 Shutting down HotLoader..."
            @ip_monitor&.stop
            exit 0
          end
          
          # Start the server
          SjuiTools::HotLoader::Server.start(port: port)
        end
        
        def run_stop(args)
          puts "🛑 Stopping HotLoader services..."
          
          # Kill HotLoader server processes
          puts "Stopping HotLoader server..."
          
          # Kill Ruby server on port 8081
          ruby_pids = `lsof -ti:8081`.strip.split("\n")
          ruby_pids.each do |pid|
            next if pid.empty?
            Process.kill('TERM', pid.to_i) rescue nil
          end
          
          # Kill processes by name
          system("pkill -f 'hotloader/server.rb' 2>/dev/null")
          system("pkill -f 'hotloader/ip_monitor.rb' 2>/dev/null")
          
          puts "✅ All HotLoader services stopped"
        end
        
        def run_status(args)
          puts "📊 HotLoader Status"
          puts "=" * 40
          
          # Check current IP from config
          config = Core::ConfigManager.get_hotloader_config
          current_ip = config['ip'] || '127.0.0.1'
          current_port = config['port'] || 8081
          
          puts "\n📱 Configuration:"
          puts "   IP Address: #{current_ip}"
          puts "   Port: #{current_port}"
          
          # Check Ruby server (port 8081)
          puts "\n🌐 HotLoader Server:"
          ruby_pids = `lsof -ti:#{current_port} 2>/dev/null`.strip
          if ruby_pids.empty?
            puts "   Status: Not running"
          else
            puts "   Status: Running"
            puts "   PID(s): #{ruby_pids.split("\n").join(', ')}"
            puts "   Endpoint: ws://#{current_ip}:#{current_port}/websocket"
          end
          
          # Check IP monitor process
          puts "\n🔄 IP Monitor:"
          monitor_pids = `pgrep -f 'hotloader/ip_monitor.rb' 2>/dev/null`.strip
          if monitor_pids.empty?
            puts "   Status: Not running"
          else
            puts "   Status: Running"
            puts "   PID(s): #{monitor_pids.split("\n").join(', ')}"
          end
        end
        
        def show_help
          puts "Usage: sjui hotload [COMMAND] [options]"
          puts
          puts "Commands:"
          puts "  listen             Start HotLoader development environment (default)"
          puts "  stop               Stop all HotLoader services"
          puts "  status             Show status of HotLoader services"
          puts
          puts "Options:"
          puts "  --port, -p PORT    Server port (default: 8081)"
          puts "  --help, -h         Show this help message"
          puts
          puts "Examples:"
          puts "  sjui hotload                   # Start HotLoader (same as 'listen')"
          puts "  sjui hotload listen            # Start HotLoader development environment"
          puts "  sjui hotload listen -p 3000    # Start on port 3000"
          puts "  sjui hotload stop              # Stop all services"
          puts "  sjui hotload status            # Check service status"
        end
      end
    end
  end
end