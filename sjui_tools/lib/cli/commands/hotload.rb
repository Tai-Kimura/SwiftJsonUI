# frozen_string_literal: true

require_relative '../command_base'
require_relative '../../hotloader/server'
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
          
          puts "🚀 Starting HotLoader development environment..."
          
          # Setup paths first
          unless Core::ProjectFinder.setup_paths
            puts "Error: No iOS project found. Please run this command in a directory containing a .xcodeproj file."
            exit 1
          end
          
          script_dir = File.join(File.dirname(__FILE__), '../../../../scripts')
          ip_monitor_script = File.join(script_dir, 'ip_monitor.sh')
          
          # Update Info.plist with current IP
          puts "📱 Updating Info.plist with current IP address..."
          system("bash '#{ip_monitor_script}' update")
          
          # Stop any existing IP monitor
          system("bash '#{ip_monitor_script}' stop > /dev/null 2>&1")
          
          # Start IP monitor daemon
          puts "🔄 Starting IP monitor daemon..."
          system("bash '#{ip_monitor_script}' daemon")
          
          # Start HotLoader server
          puts "🌐 Starting HotLoader server on port #{port}..."
          puts "📡 WebSocket endpoint: ws://localhost:#{port}/websocket"
          puts "📂 Layout API: http://localhost:#{port}/layout/:name"
          puts "\n✅ HotLoader is ready!"
          puts "Press Ctrl+C to stop all services"
          
          # Start the server
          SjuiTools::HotLoader::Server.start(port: port)
        end
        
        def run_stop(args)
          puts "🛑 Stopping HotLoader services..."
          
          script_dir = File.join(File.dirname(__FILE__), '../../../../scripts')
          ip_monitor_script = File.join(script_dir, 'ip_monitor.sh')
          
          # Stop IP monitor daemon
          puts "Stopping IP monitor daemon..."
          system("bash '#{ip_monitor_script}' stop")
          
          # Kill HotLoader server processes
          puts "Stopping HotLoader server..."
          
          # Kill Ruby server on port 8080
          ruby_pids = `lsof -ti:8080`.strip.split("\n")
          ruby_pids.each do |pid|
            next if pid.empty?
            Process.kill('TERM', pid.to_i) rescue nil
          end
          
          # Kill Node.js processes on port 8081 (legacy)
          node_pids = `lsof -ti:8081`.strip.split("\n")
          node_pids.each do |pid|
            next if pid.empty?
            Process.kill('TERM', pid.to_i) rescue nil
          end
          
          # Kill processes by name
          system("pkill -f 'server.js' 2>/dev/null")
          system("pkill -f 'layout_loader.js' 2>/dev/null")
          system("pkill -f 'hotloader/server.rb' 2>/dev/null")
          
          puts "✅ All HotLoader services stopped"
        end
        
        def run_status(args)
          puts "📊 HotLoader Status"
          puts "=" * 40
          
          script_dir = File.join(File.dirname(__FILE__), '../../../../scripts')
          ip_monitor_script = File.join(script_dir, 'ip_monitor.sh')
          
          # Check IP monitor status
          puts "\n🔄 IP Monitor:"
          system("bash '#{ip_monitor_script}' status")
          
          # Check Ruby server (port 8080)
          puts "\n🌐 HotLoader Server (Ruby):"
          ruby_pids = `lsof -ti:8080 2>/dev/null`.strip
          if ruby_pids.empty?
            puts "   Status: Not running"
          else
            puts "   Status: Running"
            puts "   PID(s): #{ruby_pids.split("\n").join(', ')}"
            puts "   Port: 8080"
          end
          
          # Check Node.js server (port 8081 - legacy)
          puts "\n🌐 Legacy Node.js Server:"
          node_pids = `lsof -ti:8081 2>/dev/null`.strip
          if node_pids.empty?
            puts "   Status: Not running"
          else
            puts "   Status: Running"
            puts "   PID(s): #{node_pids.split("\n").join(', ')}"
            puts "   Port: 8081"
          end
          
          # Check for server.js and layout_loader.js processes
          server_js_pid = `pgrep -f 'node.*server.js' 2>/dev/null`.strip
          layout_loader_pid = `pgrep -f 'node.*layout_loader.js' 2>/dev/null`.strip
          
          if !server_js_pid.empty? || !layout_loader_pid.empty?
            puts "\n📄 Node.js Processes:"
            puts "   server.js: #{server_js_pid.empty? ? 'Not running' : "PID #{server_js_pid}"}"
            puts "   layout_loader.js: #{layout_loader_pid.empty? ? 'Not running' : "PID #{layout_loader_pid}"}"
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
          puts "  --port, -p PORT    Server port (default: 8080)"
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