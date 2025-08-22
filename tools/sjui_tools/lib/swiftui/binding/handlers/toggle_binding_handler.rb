# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module SwiftUI
    module Binding
      class ToggleBindingHandler < ViewBindingHandler
        def handle_specific_binding(component, key, value)
          case key
          when 'on', 'checked'
            # Toggle state is handled in the Toggle initialization
            nil
          when 'enabled'
            if is_binding?(value)
              binding = parse_binding(value, 'Bool')
              ".disabled(!#{binding})"
            end
          else
            nil
          end
        end

        # Get the toggle state binding
        def get_state_binding(component)
          # Check for 'on' or 'checked' property
          state_value = component['on'] || component['checked']
          if is_binding?(state_value)
            parse_binding(state_value, 'Bool')
          else
            # Return a constant binding if not a binding expression
            ".constant(#{state_value || false})"
          end
        end

        # Get the toggle label
        def get_label(component)
          label = component['label'] || component['text'] || ''
          if is_binding?(label)
            parse_binding(label)
          else
            "\"#{label}\""
          end
        end
      end
    end
  end
end