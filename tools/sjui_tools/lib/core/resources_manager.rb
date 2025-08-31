# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative 'config_manager'
require_relative 'project_finder'
require_relative 'logger'

module SjuiTools
  module Core
    class ResourcesManager
      def initialize
        @config = ConfigManager.load_config
        @source_path = ProjectFinder.get_full_source_path || Dir.pwd
        @layouts_dir = File.join(@source_path, @config['layouts_directory'] || 'Layouts')
        @resources_dir = File.join(@layouts_dir, 'Resources')
        @extracted_strings = {}
        @not_defined_strings = []
      end
      
      # Extract strings from JSON data
      def extract_strings_from_json(json_data, file_name)
        @extracted_strings[file_name] ||= {}
        extract_strings_recursive(json_data, file_name)
      end
      
      # Clear extracted strings
      def clear_extracted_strings
        @extracted_strings = {}
        @not_defined_strings = []
      end
      
      # Get all extracted strings
      def get_extracted_strings
        {
          'strings' => @extracted_strings,
          'not_defined' => @not_defined_strings.uniq
        }
      end
      
      private
      
      def extract_strings_recursive(data, file_name)
        return unless data.is_a?(Hash)
        
        # Check for 'text' key
        if data['text'].is_a?(String) && !data['text'].empty?
          process_string_value(data['text'], file_name)
        end
        
        # Check for partial_attributes array
        if data['partial_attributes'].is_a?(Array)
          data['partial_attributes'].each do |attr|
            if attr.is_a?(Hash) && attr['range'].is_a?(Hash) && attr['range']['text'].is_a?(String)
              process_string_value(attr['range']['text'], file_name)
            end
          end
        end
        
        # Recursively process children and other nested structures
        data.each_value do |value|
          if value.is_a?(Hash)
            extract_strings_recursive(value, file_name)
          elsif value.is_a?(Array)
            value.each { |item| extract_strings_recursive(item, file_name) if item.is_a?(Hash) }
          end
        end
      end
      
      def process_string_value(text, file_name)
        # Skip binding values (wrapped in @{})
        return if text.match?(/^@\{.*\}$/)
        
        # Check if it's snake_case
        if text.match?(/^[a-z]+(_[a-z]+)*$/)
          @extracted_strings[file_name][text] = text
        else
          # Direct string value - add to not_defined
          @not_defined_strings << text
        end
      end
      
      # TODO: Implement methods for managing resource files
    end
  end
end