# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module SwiftUI
    module Binding
      class TextFieldBindingHandler < ViewBindingHandler
        def handle_specific_binding(component, key, value)
          case key
          when 'text'
            if is_binding?(value)
              # Text binding is handled in the TextField initialization
              # Return nil as it's not a modifier
              nil
            end
          when 'enabled'
            if is_binding?(value)
              binding = parse_binding(value, 'Bool')
              ".disabled(!#{binding})"
            end
          when 'secure'
            if is_binding?(value)
              # SecureField needs to be handled differently
              # Store this information for the converter to use
              nil
            end
          else
            nil
          end
        end

        # Special method to get the text binding for TextField
        def get_text_binding(component)
          text_value = component['text']
          if is_binding?(text_value)
            parse_binding(text_value)
          else
            # Return a constant binding if not a binding expression
            ".constant(\"#{text_value || ''}\")"
          end
        end

        # Check if this should be a SecureField
        def is_secure_field?(component)
          component['secure'] == true || component['secure'] == 'true'
        end
      end
    end
  end
end