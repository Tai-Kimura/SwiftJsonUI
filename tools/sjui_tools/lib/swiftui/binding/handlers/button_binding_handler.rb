# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module SwiftUI
    module Binding
      class ButtonBindingHandler < ViewBindingHandler
        def handle_specific_binding(component, key, value)
          case key
          when 'text'
            # Button text is handled in the Button label
            nil
          when 'enabled'
            if is_binding?(value)
              binding = parse_binding(value, 'Bool')
              ".disabled(!#{binding})"
            end
          when 'fontColor'
            if is_binding?(value)
              binding = parse_binding(value, 'Color')
              ".foregroundColor(#{binding})"
            end
          else
            nil
          end
        end

        # Get the button text (with binding support)
        def get_button_text(component)
          text_value = component['text']
          if is_binding?(text_value)
            parse_binding(text_value)
          else
            "\"#{text_value || ''}\""
          end
        end

        # Get the action name for the button
        def get_action(component)
          onclick = component['onclick']
          if onclick
            "viewModel.#{onclick}()"
          else
            "{}"
          end
        end
      end
    end
  end
end