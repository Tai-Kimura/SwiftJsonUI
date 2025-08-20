# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    module Views
      class DynamicComponentConverter < BaseViewConverter
        def convert
          json_file = @component['jsonFile'] || @component['json_file'] || ''
          view_id = @component['id'] || @component['viewId'] || nil
          
          # DynamicComponent requires json_file
          if json_file.empty?
            add_line "Text(\"DynamicComponent requires jsonFile\")"
            add_modifier_line ".foregroundColor(.red)"
            apply_modifiers
            return generated_code
          end
          
          # Use DynamicView from SwiftJsonUI library
          if view_id
            add_line "DynamicView(jsonName: \"#{json_file}\", viewId: \"#{view_id}\")"
          else
            add_line "DynamicView(jsonName: \"#{json_file}\")"
          end
          
          # Apply common modifiers
          apply_modifiers
          
          generated_code
        end
      end
    end
  end
end