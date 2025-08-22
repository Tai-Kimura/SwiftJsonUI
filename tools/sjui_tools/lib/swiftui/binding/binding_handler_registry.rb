# frozen_string_literal: true

require_relative 'view_binding_handler'
require_relative 'handlers/label_binding_handler'
require_relative 'handlers/text_field_binding_handler'
require_relative 'handlers/button_binding_handler'
require_relative 'handlers/toggle_binding_handler'
require_relative 'handlers/image_binding_handler'

module SjuiTools
  module SwiftUI
    module Binding
      class BindingHandlerRegistry
        def initialize
          @handlers = {}
          register_default_handlers
        end

        def register_handler(component_type, handler_class)
          @handlers[component_type.downcase] = handler_class
        end

        def get_handler(component_type)
          handler_class = @handlers[component_type.downcase]
          if handler_class
            handler_class.new
          else
            # Return base handler for unknown types
            ViewBindingHandler.new
          end
        end

        private

        def register_default_handlers
          # Text components
          register_handler('Label', LabelBindingHandler)
          register_handler('Text', LabelBindingHandler)
          
          # Input components
          register_handler('TextField', TextFieldBindingHandler)
          register_handler('SecureField', TextFieldBindingHandler)
          register_handler('TextView', TextFieldBindingHandler)
          register_handler('TextEditor', TextFieldBindingHandler)
          
          # Button
          register_handler('Button', ButtonBindingHandler)
          
          # Toggle/Switch
          register_handler('Toggle', ToggleBindingHandler)
          register_handler('Switch', ToggleBindingHandler)
          register_handler('Check', ToggleBindingHandler)
          
          # Image
          register_handler('Image', ImageBindingHandler)
          register_handler('NetworkImage', ImageBindingHandler)
          
          # Add more handlers as needed
        end
      end
    end
  end
end