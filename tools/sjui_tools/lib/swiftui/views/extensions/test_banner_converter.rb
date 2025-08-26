# frozen_string_literal: true

require_relative '../base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      module Extensions
        class TestBannerConverter < BaseViewConverter
          def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
            super(component, indent_level, action_manager, binding_registry)
            @factory = converter_factory
            @registry = view_registry
          end
          
          def convert
            result = []
            
            # Auto-detect container based on children or child
            is_container = (@component['children'] && !@component['children'].empty?) || (@component['child'] && !@component['child'].empty?)

            # Generate component with parameters
            component_line = "#{indent}TestBanner("
            
            # Collect parameters
            params = []
            if @component['message']
              formatted_value = format_value(@component['message'], 'String')
              params << "message: #{formatted_value}" if formatted_value
            end
            if @component['type']
              formatted_value = format_value(@component['type'], 'String')
              params << "type: #{formatted_value}" if formatted_value
            end
            if @component.key?('dismissible')
              formatted_value = format_value(@component['dismissible'], 'Bool')
              params << "dismissible: #{formatted_value}" if formatted_value != nil
            end
            
            if is_container
              # Container component with children
              if params.empty?
                result << "#{indent}TestBanner {"
              else
                result << component_line
                @indent_level += 1
                params.each_with_index do |param, index|
                  if index == params.length - 1
                    result << "#{indent}#{param}"
                  else
                    result << "#{indent}#{param},"
                  end
                end
                @indent_level -= 1
                result << "#{indent}) {"
              end
              
              # Process children
              process_children(result)
              
              result << "#{indent}}"
            else
              # Non-container component
              if params.empty?
                result << "#{indent}TestBanner()"
              else
                result << component_line
                @indent_level += 1
                params.each_with_index do |param, index|
                  if index == params.length - 1
                    result << "#{indent}#{param}"
                  else
                    result << "#{indent}#{param},"
                  end
                end
                @indent_level -= 1
                result << "#{indent})"
              end
            end
            
            # Apply default modifiers
            apply_common_modifiers(result)
            
            result
          end
          
          private
          
          def component_name
            "TestBanner"
          end
          
          # Process children components (handles both 'children' and 'child' keys)
          def process_children(result)
            @indent_level += 1
            
            # Handle both 'children' and 'child' keys (both are arrays)
            child_array = @component['children'] || @component['child']
            
            if child_array && child_array.is_a?(Array)
              child_array.each do |child|
                child_converter = @factory.create_converter(child, @indent_level, @action_manager, @factory, @registry)
                result.concat(child_converter.convert)
              end
            end
            
            @indent_level -= 1
          end
          
          # Helper method to format value based on type
          def format_value(value, type)
            case type.downcase
            when 'string'
              return nil unless value
              '"' + value.to_s + '"'
            when 'int', 'integer'
              return nil unless value
              value.to_s
            when 'double', 'float'
              return nil unless value
              value.to_s
            when 'bool', 'boolean'
              return nil if value.nil?
              value.to_s.downcase
            when 'color'
              format_color_value(value)
            when 'edgeinsets'
              format_edge_insets_value(value)
            else
              return nil unless value
              value.to_s
            end
          end
          
          def format_color_value(value)
            return nil unless value
            if value.is_a?(String) && value.start_with?('#')
              # Parse hex color
              hex = value.delete('#')
              r = hex[0..1].to_i(16) / 255.0
              g = hex[2..3].to_i(16) / 255.0
              b = hex[4..5].to_i(16) / 255.0
              "Color(red: #{r}, green: #{g}, blue: #{b})"
            elsif value.is_a?(Hash)
              r = value['red'] || value['r'] || 0
              g = value['green'] || value['g'] || 0
              b = value['blue'] || value['b'] || 0
              "Color(red: #{r}, green: #{g}, blue: #{b})"
            else
              "Color.#{value}"
            end
          end
          
          def format_edge_insets_value(value)
            return nil unless value
            if value.is_a?(Hash)
              top = value['top'] || 0
              leading = value['leading'] || value['left'] || 0
              bottom = value['bottom'] || 0
              trailing = value['trailing'] || value['right'] || 0
              "EdgeInsets(top: #{top}, leading: #{leading}, bottom: #{bottom}, trailing: #{trailing})"
            elsif value.is_a?(Numeric)
              "EdgeInsets(top: #{value}, leading: #{value}, bottom: #{value}, trailing: #{value})"
            else
              nil
            end
          end
        end
      end
    end
  end
end
