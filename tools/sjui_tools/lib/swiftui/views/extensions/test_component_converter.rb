# frozen_string_literal: true

require_relative '../base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      module Extensions
        class TestComponentConverter < BaseViewConverter
          def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
            super(component, indent_level, action_manager, binding_registry)
            @factory = converter_factory
            @registry = view_registry
          end
          
          def convert
            # Auto-detect container based on children or child
            is_container = (@component['children'] && !@component['children'].empty?) || (@component['child'] && !@component['child'].empty?)
            
            # Collect parameters
            params = []
            if @component['title']
              formatted_value = format_value(@component['title'], 'String')
              params << "title: #{formatted_value}" if formatted_value
            end
            if @component['subtitle']
              formatted_value = format_value(@component['subtitle'], 'String')
              params << "subtitle: #{formatted_value}" if formatted_value
            end
            
            if is_container
              # Container component with children
              if params.empty?
                add_line "TestComponent {"
              else
                add_line "TestComponent("
                indent do
                  params.each_with_index do |param, index|
                    if index == params.length - 1
                      add_line "#{param}"
                    else
                      add_line "#{param},"
                    end
                  end
                end
                add_line ") {"
              end
              
              # Process children
              indent do
                process_children
              end
              
              add_line "}"
            else
              # Non-container component
              if params.empty?
                add_line "TestComponent()"
              else
                add_line "TestComponent("
                indent do
                  params.each_with_index do |param, index|
                    if index == params.length - 1
                      add_line "#{param}"
                    else
                      add_line "#{param},"
                    end
                  end
                end
                add_line ")"
              end
            end
            
            # Apply default modifiers
            apply_modifiers
            
            generated_code
          end
          
          private
          
          def component_name
            "TestComponent"
          end
          
          # Process children components (handles both 'children' and 'child' keys)
          def process_children
            # Handle both 'children' and 'child' keys (both are arrays)
            child_array = @component['children'] || @component['child']
            
            if child_array && child_array.is_a?(Array)
              child_array.each do |child|
                child_converter = @factory.create_converter(child, @indent_level, @action_manager, @factory, @registry)
                @generated_code.concat(child_converter.convert.split("\n"))
              end
            end
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
