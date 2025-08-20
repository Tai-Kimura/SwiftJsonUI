module SjuiTools
  module SwiftUI
    module Views
      module VisibilityHelper
        def apply_visibility_wrapper(child)
          if child['visibility']
            visibility_value = child['visibility']
            # Check if it's a binding
            if visibility_value.is_a?(String) && visibility_value.start_with?('@{') && visibility_value.end_with?('}')
              var_name = to_camel_case(visibility_value[2..-2])
              visibility_param = var_name
            else
              visibility_param = "\"#{visibility_value}\""
            end
            
            # Create child converter with extra indent level for content inside VisibilityWrapper
            child_converter = @converter_factory.create_converter(child, @indent_level + 1, @action_manager, @converter_factory, @view_registry)
            child_code = child_converter.convert
            
            # Add VisibilityWrapper wrapper
            add_line "VisibilityWrapper(#{visibility_param}) {"
            indent do
              child_code.split("\n").each { |line| @generated_code << line }
            end
            add_line "}"
            
            # Return the child_converter for state propagation
            child_converter
          else
            nil
          end
        end
      end
    end
  end
end