# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module SwiftUI
    module Binding
      class ImageBindingHandler < ViewBindingHandler
        def handle_specific_binding(component, key, value)
          case key
          when 'srcName', 'src'
            # Image source is handled in Image initialization
            nil
          when 'contentMode'
            if is_binding?(value)
              binding = parse_binding(value, 'String')
              # Map contentMode to SwiftUI ContentMode
              ".aspectRatio(contentMode: #{binding} == \"fill\" ? .fill : .fit)"
            end
          else
            nil
          end
        end

        # Get the image source (with binding support)
        def get_image_source(component)
          src_value = component['srcName'] || component['src']
          if is_binding?(src_value)
            # For binding, we need to handle it differently
            # SwiftUI Image doesn't directly support binding for the image name
            parse_binding(src_value)
          else
            "\"#{src_value || 'placeholder'}\""
          end
        end

        # Check if this is a system image
        def is_system_image?(component)
          component['systemImage'] == true || component['isSystemImage'] == true
        end
      end
    end
  end
end