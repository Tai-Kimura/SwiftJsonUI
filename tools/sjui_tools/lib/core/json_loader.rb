# frozen_string_literal: true

require 'json'

module SjuiTools
  module Core
    class JsonLoader
      def self.load_file(file_path)
        return nil unless File.exist?(file_path)
        
        begin
          content = File.read(file_path)
          JSON.parse(content)
        rescue JSON::ParserError => e
          raise "Failed to parse JSON file #{file_path}: #{e.message}"
        rescue => e
          raise "Failed to read file #{file_path}: #{e.message}"
        end
      end

      def self.save_file(file_path, data, pretty: true)
        json_content = if pretty
          JSON.pretty_generate(data)
        else
          JSON.generate(data)
        end
        
        File.write(file_path, json_content)
      rescue => e
        raise "Failed to write JSON file #{file_path}: #{e.message}"
      end

      # Load and merge multiple JSON files
      def self.load_and_merge(*file_paths)
        result = {}
        
        file_paths.each do |path|
          next unless File.exist?(path)
          data = load_file(path)
          result = deep_merge(result, data) if data.is_a?(Hash)
        end
        
        result
      end

      # Validate JSON structure against a schema
      def self.validate_structure(data, required_keys: [], optional_keys: [])
        missing_keys = required_keys - data.keys
        unless missing_keys.empty?
          raise "Missing required keys: #{missing_keys.join(', ')}"
        end
        
        unknown_keys = data.keys - (required_keys + optional_keys)
        unless unknown_keys.empty?
          puts "Warning: Unknown keys found: #{unknown_keys.join(', ')}"
        end
        
        true
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
    end
  end
end