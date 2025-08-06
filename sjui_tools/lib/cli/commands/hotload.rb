# frozen_string_literal: true

require_relative '../command_base'
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
          
          # Kill existing processes on the port first
          existing_pids = `lsof -ti:#{port} 2>/dev/null`.strip.split("\n")
          unless existing_pids.empty?
            puts "🛑 Stopping existing processes on port #{port}..."
            existing_pids.each do |pid|
              next if pid.empty?
              begin
                Process.kill('TERM', pid.to_i)
              rescue Errno::ESRCH
                # Process already dead
              end
            end
            sleep 1 # Give processes time to terminate
          end
          
          # Also kill any existing IP monitor processes
          system("pkill -f 'hotloader/ip_monitor.rb' 2>/dev/null")
          
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
          start_node_server(port)
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
          system("pkill -f 'hotloader/server.js' 2>/dev/null")
          system("pkill -f 'node.*server.js' 2>/dev/null")
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
        
        def start_node_server(port)
          # Check if node is installed
          unless system('which node > /dev/null 2>&1')
            puts "❌ Error: Node.js is not installed."
            puts "Please install Node.js from https://nodejs.org/"
            exit 1
          end
          
          # Get hotloader directory
          hotloader_dir = File.expand_path('../../hotloader', __dir__)
          server_js = File.join(hotloader_dir, 'server.js')
          package_json = File.join(hotloader_dir, 'package.json')
          
          unless File.exist?(server_js)
            puts "❌ Error: Node.js server file not found at #{server_js}"
            exit 1
          end
          
          # Install dependencies if needed
          if File.exist?(package_json) && !Dir.exist?(File.join(hotloader_dir, 'node_modules'))
            puts "📦 Installing Node.js dependencies..."
            Dir.chdir(hotloader_dir) do
              unless system('npm install')
                puts "❌ Error: Failed to install dependencies"
                exit 1
              end
            end
            
            # Clean up Xcode project after npm install
            cleanup_xcode_project_after_npm
          end
          
          # Start Node.js server
          Dir.chdir(hotloader_dir) do
            ENV['PORT'] = port.to_s
            exec("node server.js")
          end
        end
        
        def cleanup_xcode_project_after_npm
          puts "🧹 Cleaning up Xcode project after npm install..."
          
          # Find Xcode project
          project_file = Core::ProjectFinder.find_project_file
          return unless project_file
          
          require 'xcodeproj'
          project = Xcodeproj::Project.open(project_file)
          
          # Patterns to remove
          patterns_to_remove = [
            '.editorconfig',
            '.eslintrc',
            '.npmignore', 
            '.nycrc',
            'FUNDING.yml',
            '.prettierrc',
            '.babelrc',
            '.travis.yml',
            '.package-lock.json'
          ]
          
          removed_count = 0
          
          # Remove files matching patterns
          project.files.each do |file_ref|
            next unless file_ref.path
            
            # Check for exact matches
            if patterns_to_remove.any? { |pattern| File.basename(file_ref.path) == pattern }
              puts "  Removing from project: #{file_ref.path}"
              file_ref.remove_from_project
              removed_count += 1
              next
            end
            
            # Check for files inside node_modules
            if file_ref.path.include?('node_modules/')
              # Remove any dotfiles/dotdirectories inside node_modules
              if File.basename(file_ref.path).start_with?('.')
                puts "  Removing from project: #{file_ref.path}"
                file_ref.remove_from_project
                removed_count += 1
              end
            end
          end
          
          if removed_count > 0
            project.save
            puts "✅ Removed #{removed_count} files from Xcode project"
          else
            puts "✅ No cleanup needed"
          end
          
          # Also update membership exceptions for synchronized projects
          update_membership_exceptions_if_needed(project_file)
        rescue => e
          puts "⚠️  Warning: Could not clean up Xcode project: #{e.message}"
        end
        
        def update_membership_exceptions_if_needed(project_file)
          # Use PbxprojManager to update membership exceptions
          require_relative '../../binding/xcode_project/pbxproj_manager'
          
          manager = SjuiTools::Binding::XcodeProject::PbxprojManager.new(project_file)
          manager.setup_membership_exceptions
          puts "✅ Updated membership exceptions"
        rescue => e
          puts "⚠️  Warning: Could not update membership exceptions: #{e.message}"
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