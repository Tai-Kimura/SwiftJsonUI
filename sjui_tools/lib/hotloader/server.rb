# frozen_string_literal: true

require 'sinatra/base'
require 'thin'
require 'rack/handler/thin'
require 'faye/websocket'
require 'json'
require 'eventmachine'
require_relative '../core/config_manager'
require_relative '../core/project_finder'
require_relative '../core/file_watcher'

module SjuiTools
  module HotLoader
    class Server < Sinatra::Base
      set :port, 8081
      set :bind, '0.0.0.0'
      set :public_folder, File.join(File.dirname(__FILE__), 'public')
      set :views, File.join(File.dirname(__FILE__), 'views')
      
      # WebSocket clients
      @@clients = []
      
      # Setup routes
      get '/' do
        puts "HTTP request to / from: #{request.ip}"
        erb :index
      end
      
      # Serve JavaScript files
      get '/js/layout_loader.js' do
        content_type 'application/javascript'
        File.read(File.join(File.dirname(__FILE__), 'layout_loader.js'))
      end
      
      get '/js/client.js' do
        content_type 'application/javascript'
        File.read(File.join(File.dirname(__FILE__), 'client.js'))
      end
      
      # API endpoints
      get '/layout/:name' do
        content_type :json
        
        config = Core::ConfigManager.load_config
        source_path = Core::ProjectFinder.get_full_source_path
        layouts_dir = File.join(source_path, config['layouts_directory'])
        
        # Find layout file
        layout_file = File.join(layouts_dir, "#{params[:name]}.json")
        
        if File.exist?(layout_file)
          File.read(layout_file)
        else
          status 404
          { error: "Layout not found: #{params[:name]}" }.to_json
        end
      end
      
      get '/layout/:folder/:name' do
        content_type :json
        
        config = Core::ConfigManager.load_config
        source_path = Core::ProjectFinder.get_full_source_path
        layouts_dir = File.join(source_path, config['layouts_directory'])
        
        # Find layout file in subfolder
        layout_file = File.join(layouts_dir, params[:folder], "#{params[:name]}.json")
        
        if File.exist?(layout_file)
          File.read(layout_file)
        else
          status 404
          { error: "Layout not found: #{params[:folder]}/#{params[:name]}" }.to_json
        end
      end
      
      # WebSocket endpoint
      get '/websocket' do
        puts "WebSocket request received from: #{request.ip}"
        puts "Headers: #{request.env.select {|k,v| k.start_with?('HTTP_')}.inspect}"
        
        if Faye::WebSocket.websocket?(request.env)
          puts "Valid WebSocket request detected"
          ws = Faye::WebSocket.new(request.env, nil, { 
            ping: 60,
            headers: {
              'Access-Control-Allow-Origin' => '*'
            }
          })
          
          ws.on :open do |event|
            @@clients << ws
            puts "WebSocket client connected from #{request.ip} (Total: #{@@clients.size})"
          end
          
          ws.on :close do |event|
            @@clients.delete(ws)
            puts "WebSocket client disconnected (Total: #{@@clients.size})"
          end
          
          ws.on :message do |event|
            # Handle incoming messages if needed
          end
          
          ws.rack_response
        else
          erb :index
        end
      end
      
      # Start server with file watching
      def self.start(options = {})
        port = options[:port] || 8081
        
        # Setup project paths
        unless Core::ProjectFinder.setup_paths
          puts "Error: Could not find project file"
          exit 1
        end
        
        config = Core::ConfigManager.load_config
        source_path = Core::ProjectFinder.get_full_source_path
        
        layouts_dir = File.join(source_path, config['layouts_directory'])
        styles_dir = File.join(source_path, config['styles_directory'])
        
        # Start file watcher
        watcher = Core::FileWatcher.new([layouts_dir, styles_dir], extensions: ['json']) do |file, type|
          puts "File #{type}: #{file}"
          notify_clients(file, type)
          
          # Run sjui build if layout file changed
          if file.start_with?(layouts_dir)
            puts "Layout file changed, running sjui build..."
            system("cd #{File.expand_path('../../../bin', __FILE__)} && ./sjui build")
          end
        end
        
        watcher.start
        
        # Configure server
        set :port, port
        
        # Get current IP address
        ip_address = get_local_ip || '0.0.0.0'
        
        # Start server
        puts "Starting HotLoader server on port #{port}..."
        puts "WebSocket endpoint: ws://#{ip_address}:#{port}/websocket"
        puts "Layout API: http://#{ip_address}:#{port}/layout/:name"
        puts "Press Ctrl+C to stop"
        
        # Run server with explicit Thin configuration
        EM.run do
          thin = Thin::Server.new(ip_address, port, self)
          thin.start
          puts "Thin server started on #{ip_address}:#{port}"
        end
      end
      
      private
      
      def self.get_local_ip
        # Try en0 interface first (common for macOS Wi-Fi)
        ip = `ipconfig getifaddr en0 2>/dev/null`.strip
        
        # If en0 is empty, try other interfaces
        if ip.empty?
          ip = `ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "169.254" | head -n1 | awk '{print $2}'`.strip
        end
        
        ip.empty? ? nil : ip
      end
      
      def self.notify_clients(file, type)
        message = {
          type: 'file_changed',
          file: file,
          change_type: type,
          timestamp: Time.now.to_i
        }.to_json
        
        @@clients.each do |client|
          client.send(message)
        end
        
        puts "Notified #{@@clients.size} clients"
      end
    end
  end
end