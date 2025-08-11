# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module SwiftUI
    module Binding
      class LabelBindingHandler < ViewBindingHandler
        def handle_specific_binding(component, key, value)
          case key
          when 'text'
            # Text content is handled in the Text initialization
            # Return nil as it's not a modifier
            nil
          when 'fontColor'
            if is_binding?(value)
              binding = parse_binding(value, 'Color')
              ".foregroundColor(#{binding})"
            end
          when 'fontSize'
            if is_binding?(value)
              binding = parse_binding(value, 'CGFloat')
              ".font(.system(size: #{binding}))"
            end
          when 'font'
            if is_binding?(value)
              binding = parse_binding(value, 'String')
              # Handle font weight binding
              ".fontWeight(#{binding} == \"bold\" ? .bold : .regular)"
            end
          else
            nil
          end
        end

        # Get the text content (with binding support)
        def get_text_content(component)
          text_value = component['text']
          if is_binding?(text_value)
            # Full binding: @{propertyName}
            # For Text views, we need the actual value, not a binding
            # So we remove the $ prefix that parse_binding adds
            binding = parse_binding(text_value)
            if binding
              # Remove the $ prefix for Text views
              property_path = binding.sub(/^\$/, '')
              
              # Check if we need string interpolation for non-String types
              # We'll wrap it in string interpolation to handle all types
              "\"\\(#{property_path})\""
            else
              "\"\""
            end
          elsif text_value && text_value.include?('@{')
            # Text with interpolation: "Some text @{property} more text"
            # Extract all binding expressions
            interpolated = text_value.gsub(/@\{([^}]+)\}/) do |match|
              property_name = $1
              # For interpolated text, use viewModel.data directly without the $ prefix
              "\\(viewModel.data.#{property_name})"
            end
            "\"#{interpolated.gsub("\n", "\\n")}\""
          else
            "\"#{(text_value || '').gsub("\n", "\\n")}\""
          end
        end
      end
    end
  end
end