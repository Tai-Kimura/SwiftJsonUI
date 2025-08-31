# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'set'
require_relative '../core/config_manager'
require_relative '../core/project_finder'
require_relative 'style_loader'

module SjuiTools
  module SwiftUI
    class DataModelUpdater
      def initialize
        @config = Core::ConfigManager.load_config
        @source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
        @layouts_dir = File.join(@source_path, @config['layouts_directory'] || 'Layouts')
        @data_dir = File.join(@source_path, @config['data_directory'] || 'Data')
        @styles_dir = File.join(@source_path, @config['styles_directory'] || 'Styles')
      end

      def update_data_models
        # Process all JSON files in Layouts directory (excluding Resources folder)
        json_files = Dir.glob(File.join(@layouts_dir, '**/*.json')).reject do |file|
          # Skip Resources folder
          file.include?(File.join(@layouts_dir, 'Resources'))
        end
        
        json_files.each do |json_file|
          process_json_file(json_file)
        end
      end

      private

      def process_json_file(json_file)
        json_content = File.read(json_file)
        json_data = JSON.parse(json_content)
        
        # Expand styles before extracting data and actions
        expanded_data = StyleLoader.load_and_merge(json_data, @styles_dir)
        
        # Extract data properties from expanded JSON
        data_properties = extract_data_properties(expanded_data)
        
        # Extract onclick actions from expanded JSON
        onclick_actions = extract_onclick_actions(expanded_data)
        
        # Always create/update data file, even if no properties
        # Get the view name from file path
        base_name = File.basename(json_file, '.json')
        
        # Update the Data model file
        update_data_file(base_name, data_properties, onclick_actions)
      end
      
      def extract_onclick_actions(json_data, actions = Set.new)
        if json_data.is_a?(Hash)
          # Check for onclick attribute
          if json_data['onclick'] && json_data['onclick'].is_a?(String)
            actions.add(json_data['onclick'])
          end
          
          # Process children
          if json_data['child']
            if json_data['child'].is_a?(Array)
              json_data['child'].each do |child|
                extract_onclick_actions(child, actions)
              end
            else
              extract_onclick_actions(json_data['child'], actions)
            end
          end
        elsif json_data.is_a?(Array)
          json_data.each do |item|
            extract_onclick_actions(item, actions)
          end
        end
        
        actions.to_a
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

      def update_data_file(base_name, data_properties, onclick_actions = [])
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
          # If file doesn't exist, create it with empty data structure
          unless File.exist?(data_file_path)
            # Create directory if needed
            FileUtils.mkdir_p(@data_dir)
          end
        end
        
        # Generate new content
        content = generate_data_content(view_name, data_properties, onclick_actions)
        
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

      def generate_data_content(view_name, data_properties, onclick_actions = [])
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
        
        # Add update function to allow dynamic property updates
        content += "\n"
        content += "    // Update properties from dictionary\n"
        content += "    mutating func update(dictionary: [String: Any]) {\n"
        
        if !data_properties.empty?
          data_properties.each do |prop|
            name = prop['name']
            class_type = prop['class']
            
            # Generate update code based on type
            content += "        if let value = dictionary[\"#{name}\"] {\n"
            
            case class_type
            when 'String'
              content += "            if let stringValue = value as? String {\n"
              content += "                self.#{name} = stringValue\n"
              content += "            }\n"
            when 'Int'
              content += "            if let intValue = value as? Int {\n"
              content += "                self.#{name} = intValue\n"
              content += "            }\n"
            when 'Double'
              content += "            if let doubleValue = value as? Double {\n"
              content += "                self.#{name} = doubleValue\n"
              content += "            }\n"
            when 'Bool'
              content += "            if let boolValue = value as? Bool {\n"
              content += "                self.#{name} = boolValue\n"
              content += "            }\n"
            when 'CGFloat'
              content += "            if let floatValue = value as? CGFloat {\n"
              content += "                self.#{name} = floatValue\n"
              content += "            } else if let doubleValue = value as? Double {\n"
              content += "                self.#{name} = CGFloat(doubleValue)\n"
              content += "            }\n"
            else
              # For custom types, try to cast directly
              content += "            if let typedValue = value as? #{class_type} {\n"
              content += "                self.#{name} = typedValue\n"
              content += "            }\n"
            end
            
            content += "        }\n"
          end
        else
          # No properties, but still include empty function body
          content += "        // No properties to update\n"
        end
        
        content += "    }\n"
        
        # Add toDictionary function with viewModel parameter
        content += "\n"
        content += "    // Convert properties to dictionary for Dynamic mode\n"
        content += "    func toDictionary(viewModel: #{view_name}ViewModel? = nil) -> [String: Any] {\n"
        content += "        var dict: [String: Any] = [:]\n"
        
        # Add data properties
        if !data_properties.empty?
          content += "        \n"
          content += "        // Data properties\n"
          data_properties.each do |prop|
            name = prop['name']
            class_type = prop['class']
            default_value = prop['defaultValue']
            
            # If it's optional, check for nil
            if default_value.nil? || default_value == 'nil'
              content += "        if let value = #{name} {\n"
              content += "            dict[\"#{name}\"] = value\n"
              content += "        }\n"
            else
              content += "        dict[\"#{name}\"] = #{name}\n"
            end
          end
        end
        
        # Add onclick closures if viewModel is provided
        if !onclick_actions.empty?
          content += "        \n"
          content += "        // Add onclick action closures if viewModel is provided\n"
          content += "        if let viewModel = viewModel {\n"
          onclick_actions.each do |action|
            content += "            dict[\"#{action}\"] = { [weak viewModel] in viewModel?.#{action}() }\n"
          end
          content += "        }\n"
        end
        
        if data_properties.empty? && onclick_actions.empty?
          content += "        // No properties to add\n"
        end
        
        content += "        \n"
        content += "        return dict\n"
        content += "    }\n"
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