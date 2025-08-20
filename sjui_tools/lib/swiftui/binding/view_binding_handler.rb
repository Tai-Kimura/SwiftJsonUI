# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    module Binding
      class ViewBindingHandler
        def initialize
          @binding_code = []
        end

        # Parse binding syntax @{propertyName} and return the binding code
        def parse_binding(value, data_type = 'String')
          return nil unless value.is_a?(String) && value.start_with?('@{') && value.end_with?('}')
          
          property_name = value[2..-2] # Remove @{ and }
          "$viewModel.data.#{property_name}"
        end

        # Check if a value is a binding expression
        def is_binding?(value)
          value.is_a?(String) && value.start_with?('@{') && value.end_with?('}')
        end

        # Handle common bindings that apply to all views
        def handle_common_binding(component, key, value)
          case key
          when 'visibility'
            if is_binding?(value)
              binding = parse_binding(value, 'String')
              case binding
              when nil
                nil
              else
                ".opacity(#{binding} == \"visible\" ? 1 : (#{binding} == \"invisible\" ? 0 : 0))"
              end
            end
          when 'background'
            if is_binding?(value)
              binding = parse_binding(value, 'Color')
              ".background(#{binding})"
            end
          when 'cornerRadius'
            if is_binding?(value)
              binding = parse_binding(value, 'CGFloat')
              ".cornerRadius(#{binding})"
            end
          when 'opacity', 'alpha'
            if is_binding?(value)
              binding = parse_binding(value, 'Double')
              ".opacity(#{binding})"
            end
          when 'disabled'
            if is_binding?(value)
              binding = parse_binding(value, 'Bool')
              ".disabled(#{binding})"
            end
          else
            nil
          end
        end

        # Handle specific bindings for each view type (override in subclasses)
        def handle_specific_binding(component, key, value)
          nil
        end

        # Process all bindings for a component
        def process_bindings(component)
          modifiers = []
          
          component.each do |key, value|
            # Try common bindings first
            modifier = handle_common_binding(component, key, value)
            modifiers << modifier if modifier
            
            # Try specific bindings
            modifier = handle_specific_binding(component, key, value)
            modifiers << modifier if modifier
          end
          
          modifiers
        end

        # Get the binding property value or the literal value
        def get_value(value, default = nil)
          if is_binding?(value)
            parse_binding(value)
          else
            value || default
          end
        end
      end
    end
  end
end