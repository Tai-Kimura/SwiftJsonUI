# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../core/config_manager'
require_relative '../core/project_finder'

module SjuiTools
  module SwiftUI
    class DataModelUpdater
      def initialize
        @config = Core::ConfigManager.load_config
        @source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
        @layouts_dir = File.join(@source_path, @config['layouts_directory'] || 'Layouts')
        @data_dir = File.join(@source_path, @config['data_directory'] || 'Data')
      end

      def update_data_models
        # Process all JSON files in Layouts directory
        json_files = Dir.glob(File.join(@layouts_dir, '**/*.json'))
        
        json_files.each do |json_file|
          process_json_file(json_file)
        end
      end

      private

      def process_json_file(json_file)
        json_content = File.read(json_file)
        json_data = JSON.parse(json_content)
        
        # Extract data properties from JSON
        data_properties = extract_data_properties(json_data)
        
        return if data_properties.empty?
        
        # Get the view name from file path
        base_name = File.basename(json_file, '.json')
        
        # Update the Data model file
        update_data_file(base_name, data_properties)
      end

      def extract_data_properties(json_data, properties = [])
        if json_data.is_a?(Hash)
          # Check for data section
          if json_data['data'] && json_data['data'].is_a?(Array)
            json_data['data'].each do |data_item|
              if data_item.is_a?(Hash)
                properties << data_item
              end
            end
          end
          
          # Process children
          if json_data['child']
            if json_data['child'].is_a?(Array)
              json_data['child'].each do |child|
                extract_data_properties(child, properties)
              end
            else
              extract_data_properties(json_data['child'], properties)
            end
          end
        elsif json_data.is_a?(Array)
          json_data.each do |item|
            extract_data_properties(item, properties)
          end
        end
        
        properties
      end

      def update_data_file(base_name, data_properties)
        # Convert base_name to PascalCase for searching
        pascal_view_name = to_pascal_case(base_name)
        
        # Check for existing file with different casing
        existing_file = find_existing_data_file(pascal_view_name)
        
        if existing_file
          # Extract the actual struct name from the existing file
          existing_struct_name = extract_struct_name(existing_file)
          if existing_struct_name
            # Use the exact struct name from the existing file
            view_name = existing_struct_name.sub(/Data$/, '')
          else
            # Fallback to pascal case if we can't extract the name
            view_name = pascal_view_name
          end
          data_file_path = existing_file
        else
          # For new files, use pascal case
          view_name = pascal_view_name
          data_file_path = File.join(@data_dir, "#{view_name}Data.swift")
          # If file doesn't exist, skip (it should be created by generator)
          return unless File.exist?(data_file_path)
        end
        
        # Generate new content
        content = generate_data_content(view_name, data_properties)
        
        # Write the updated content
        File.write(data_file_path, content)
        puts "  Updated Data model: #{data_file_path}"
      end
      
      def find_existing_data_file(view_name)
        # Try exact match first
        exact_path = File.join(@data_dir, "#{view_name}Data.swift")
        return exact_path if File.exist?(exact_path)
        
        # Try case-insensitive search
        Dir.glob(File.join(@data_dir, '*Data.swift')).find do |file|
          File.basename(file, '.swift').downcase == "#{view_name}Data".downcase
        end
      end
      
      def extract_struct_name(file_path)
        content = File.read(file_path)
        if match = content.match(/struct\s+(\w+Data)\s*{/)
          match[1]
        else
          nil
        end
      end

      def generate_data_content(view_name, data_properties)
        content = <<~SWIFT
        import Foundation
        import SwiftUI
        import SwiftJsonUI

        struct #{view_name}Data {
            // Data properties from JSON
        SWIFT
        
        if data_properties.empty?
          content += "    // No data properties defined in JSON\n"
        else
          # Add each property with correct type and default value
          data_properties.each do |prop|
            name = prop['name']
            class_type = prop['class']  # Use class name directly
            default_value = prop['defaultValue']
            
            # If no default value or nil, make it optional
            if default_value.nil? || default_value == 'nil'
              content += "    var #{name}: #{class_type}? = nil\n"
            else
              formatted_value = format_default_value(default_value, class_type)
              content += "    var #{name}: #{class_type} = #{formatted_value}\n"
            end
          end
        end
        
        content += "}\n"
        content
      end

      def format_default_value(value, json_class)
        if json_class == 'String'
          # For String class, add quotes
          "\"#{value}\""
        else
          # For all other cases, use value as-is (it should be a Swift expression string)
          value
        end
      end

      def to_pascal_case(str)
        # Handle various naming patterns
        snake = str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                   .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                   .downcase
        snake.split(/[_\-]/).map(&:capitalize).join
      end
    end
  end
end