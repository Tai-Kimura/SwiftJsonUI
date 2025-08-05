#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'
require_relative '../core/config_manager'

module SjuiTools
  module Hotloader
    class IpMonitor
      def initialize
        @running = false
        @current_ip = nil
        @check_interval = 5 # seconds
      end

      def start
        @running = true
        @monitor_thread = Thread.new do
          while @running
            check_and_update_ip
            sleep @check_interval
          end
        end
        puts "IP address monitoring started"
      end

      def stop
        @running = false
        @monitor_thread&.join
        puts "IP address monitoring stopped"
      end

      private

      def check_and_update_ip
        new_ip = get_local_ip
        
        if new_ip && new_ip != @current_ip
          @current_ip = new_ip
          update_config_ip(new_ip)
          update_documents_config(new_ip)
          puts "IP address updated: #{new_ip}"
        end
      rescue => e
        puts "Error checking IP: #{e.message}"
      end

      def get_local_ip
        # Try en0 interface first (common for macOS Wi-Fi)
        ip = `ipconfig getifaddr en0 2>/dev/null`.strip
        
        # If en0 is empty, try other interfaces
        if ip.empty?
          ip = `ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "169.254" | head -n1 | awk '{print $2}'`.strip
        end
        
        ip.empty? ? nil : ip
      end

      def update_config_ip(ip)
        Core::ConfigManager.update_hotloader_ip(ip)
      end

      def update_documents_config(ip)
        # Update sjui.config in app's Documents directory
        # This is for runtime configuration reading
        project_dir = Core::ProjectFinder.project_dir
        return unless project_dir

        # Find all sjui.config files in build directories
        Dir.glob("#{project_dir}/**/DerivedData/**/Documents/sjui.config").each do |config_path|
          begin
            if File.exist?(config_path)
              config = JSON.parse(File.read(config_path))
              config['hotloader'] ||= {}
              config['hotloader']['ip'] = ip
              File.write(config_path, JSON.pretty_generate(config))
            end
          rescue => e
            puts "Failed to update #{config_path}: #{e.message}"
          end
        end

        # Also update the template sjui.config that gets copied to Documents
        source_path = Core::ProjectFinder.get_full_source_path
        template_config = File.join(source_path, 'sjui.config')
        
        if File.exist?(template_config)
          begin
            config = JSON.parse(File.read(template_config))
            config['hotloader'] ||= {}
            config['hotloader']['ip'] = ip
            File.write(template_config, JSON.pretty_generate(config))
          rescue => e
            puts "Failed to update template config: #{e.message}"
          end
        end
      end
    end
  end
end