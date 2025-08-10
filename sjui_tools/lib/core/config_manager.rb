# frozen_string_literal: true

require 'json'
require_relative 'base_path'

module SjuiTools
  module Core
    class ConfigManager
      DEFAULT_CONFIG = {
        'mode' => 'binding',
        'project_name' => '',
        'project_file_name' => '',
        'source_directory' => '',
        'layouts_directory' => 'Layouts',
        'bindings_directory' => 'Bindings', 
        'view_directory' => 'View',
        'styles_directory' => 'Styles',
        'custom_view_types' => {},
        'hot_loader_directory' => '',
        'use_network' => true,
        'swiftui' => {
          'output_directory' => 'Generated'
        },
        'hotloader' => {
          'ip' => '127.0.0.1',
          'port' => 8081,
          'watch_directories' => ['Layouts', 'Styles']
        }
      }.freeze

      def self.load_config(config_file = nil)
        # Use provided config file or find default
        config_path = config_file || find_config_file
        
        # Load base config
        base_config = if config_path && File.exist?(config_path)
          begin
            file_content = File.read(config_path)
            JSON.parse(file_content)
          rescue JSON::ParserError => e
            puts "Warning: Failed to parse config file: #{e.message}"
            puts "Using default configuration."
            {}
          rescue => e
            puts "Warning: Failed to read config file: #{e.message}"
            puts "Using default configuration."
            {}
          end
        else
          {}
        end
        
        # Load environment-specific config if SJUI_ENVIRONMENT is set
        environment = ENV['SJUI_ENVIRONMENT']
        if environment && !environment.empty? && config_path
          env_config_file = config_path.sub(/\.json$/, ".#{environment}.json")
          if File.exist?(env_config_file)
            begin
              env_content = File.read(env_config_file)
              env_config = JSON.parse(env_content)
              # Deep merge environment config into base config
              base_config = deep_merge(base_config, env_config)
            rescue JSON::ParserError => e
              puts "Warning: Failed to parse #{environment} config: #{e.message}"
            rescue => e
              puts "Warning: Failed to read #{environment} config: #{e.message}"
            end
          end
        end
        
        # Merge with default config to ensure all keys exist
        deep_merge(DEFAULT_CONFIG, base_config)
      end

      # Find config file in project
      def self.find_config_file
        # First check current directory
        local_config = File.join(Dir.pwd, 'sjui.config.json')
        return local_config if File.exist?(local_config)
        
        # Check parent directories up to 3 levels
        current = Dir.pwd
        3.times do
          current = File.dirname(current)
          config_path = File.join(current, 'sjui.config.json')
          return config_path if File.exist?(config_path)
        end
        
        # Check sjui_tools config directory as fallback
        default_config = BasePath.config_path('default.json')
        return default_config if File.exist?(default_config)
        
        nil
      end

      # Auto-detect mode from project structure
      def self.detect_mode
        config = load_config
        return config['mode'] if config['mode'] && !config['mode'].empty?
        
        # Auto-detect based on project structure
        if File.exist?(File.join(Dir.pwd, 'Package.swift'))
          'swiftui'
        else
          'binding'
        end
      end

      private

      def self.deep_merge(hash1, hash2)
        result = hash1.dup
        hash2.each do |key, value|
          if result[key].is_a?(Hash) && value.is_a?(Hash)
            result[key] = deep_merge(result[key], value)
          else
            result[key] = value
          end
        end
        result
      end

      # Compatibility methods for binding_builder
      def self.get_source_directory
        config = load_config
        source_dir = config['source_directory']
        source_dir.nil? || source_dir.strip.empty? ? '' : source_dir
      end

      def self.get_layouts_directory
        load_config['layouts_directory']
      end

      def self.get_bindings_directory
        load_config['bindings_directory']
      end

      def self.get_view_directory
        load_config['view_directory']
      end

      def self.get_styles_directory
        load_config['styles_directory']
      end

      def self.get_project_file_name
        load_config['project_file_name']
      end

      def self.get_bindings_path(parent_dir)
        config = load_config
        source_dir = get_source_directory
        bindings_dir = config['bindings_directory']
        
        if source_dir.empty?
          File.join(parent_dir, bindings_dir)
        else
          File.join(parent_dir, source_dir, bindings_dir)
        end
      end

      def self.get_source_path(parent_dir)
        source_dir = get_source_directory
        
        if source_dir.empty?
          parent_dir
        else
          File.join(parent_dir, source_dir)
        end
      end

      def self.get_custom_view_types
        load_config['custom_view_types'] || {}
      end

      def self.update_hotloader_ip(ip)
        config_path = find_config_file
        unless config_path && File.exist?(config_path)
          puts "Warning: Config file not found, cannot update IP address"
          return
        end
        
        config = load_config
        config['hotloader'] ||= {}
        config['hotloader']['ip'] = ip
        
        File.write(config_path, JSON.pretty_generate(config))
        puts "Updated config file with IP: #{ip} -> #{config_path}"
      end

      def self.get_hotloader_config
        config = load_config
        config['hotloader'] || DEFAULT_CONFIG['hotloader']
      end

      def self.get_hot_loader_directory
        config = load_config
        hot_loader_dir = config['hot_loader_directory']
        
        if hot_loader_dir.nil? || hot_loader_dir.strip.empty?
          get_project_file_name
        else
          hot_loader_dir
        end
      end

      def self.get_use_network
        load_config.fetch('use_network', true)
      end
    end
  end
end