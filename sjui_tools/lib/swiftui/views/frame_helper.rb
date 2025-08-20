module SjuiTools
  module SwiftUI
    module Views
      module FrameHelper
        def apply_frame_constraints
          # サイズ制約（minWidth, maxWidth, minHeight, maxHeight）
          if @component['minWidth'] || @component['maxWidth'] || @component['minHeight'] || @component['maxHeight']
            min_width = @component['minWidth']
            max_width = @component['maxWidth']
            min_height = @component['minHeight'] 
            max_height = @component['maxHeight']
            
            frame_params = []
            frame_params << "minWidth: #{min_width}" if min_width
            frame_params << "maxWidth: #{max_width == 'matchParent' ? '.infinity' : max_width}" if max_width
            frame_params << "minHeight: #{min_height}" if min_height
            frame_params << "maxHeight: #{max_height == 'matchParent' ? '.infinity' : max_height}" if max_height
            
            # For labels and text components, add alignment to prevent centering
            if frame_params.any?
              if @component['type'] == 'Label' || @component['type'] == 'Text'
                frame_params << "alignment: .topLeading"
              end
              add_modifier_line ".frame(#{frame_params.join(', ')})"
            end
          end
        end
        
        def apply_frame_size
          # サイズ
          if @component['width'] || @component['height']
            # weightがある場合、width: 0 or height: 0は無視する
            should_ignore_width = (@component['width'] == 0 || @component['width'] == '0') && 
                                 (@component['weight'] || @component['widthWeight'])
            should_ignore_height = (@component['height'] == 0 || @component['height'] == '0') && 
                                  (@component['weight'] || @component['heightWeight'])
            
            # widthの処理
            if !should_ignore_width
              processed_width = process_template_value(@component['width'])
              if processed_width.is_a?(Hash) && processed_width[:template_var]
                width_value = to_camel_case(processed_width[:template_var])
              else
                width_value = size_to_swiftui(@component['width'])
              end
            else
              width_value = nil
            end
            
            # heightの処理
            if !should_ignore_height
              processed_height = process_template_value(@component['height'])
              if processed_height.is_a?(Hash) && processed_height[:template_var]
                height_value = to_camel_case(processed_height[:template_var])
              else
                height_value = size_to_swiftui(@component['height'])
              end
            else
              height_value = nil
            end
            
            # テンプレート変数の場合は型変換が必要
            if processed_width.is_a?(Hash) && processed_width[:template_var]
              width_param = "CGFloat(#{width_value})"
            else
              width_param = width_value
            end
            
            if processed_height.is_a?(Hash) && processed_height[:template_var]
              height_param = "CGFloat(#{height_value})"
            else
              height_param = height_value
            end
            
            if width_value && height_value
              # Check if either dimension is .infinity
              if width_value == '.infinity' && height_value == '.infinity'
                add_modifier_line ".frame(maxWidth: #{width_param}, maxHeight: #{height_param})"
              elsif width_value == '.infinity'
                # Split into two frame calls for maxWidth with fixed height
                add_modifier_line ".frame(maxWidth: #{width_param})"
                add_modifier_line ".frame(height: #{height_param})"
              elsif height_value == '.infinity'
                # Split into two frame calls for fixed width with maxHeight
                add_modifier_line ".frame(width: #{width_param})"
                add_modifier_line ".frame(maxHeight: #{height_param})"
              else
                add_modifier_line ".frame(width: #{width_param}, height: #{height_param})"
              end
            elsif width_value
              if width_value == '.infinity'
                add_modifier_line ".frame(maxWidth: #{width_param})"
              else
                add_modifier_line ".frame(width: #{width_param})"
              end
            elsif height_value
              if height_value == '.infinity'
                add_modifier_line ".frame(maxHeight: #{height_param})"
              else
                add_modifier_line ".frame(height: #{height_param})"
              end
            end
          end
        end
      end
    end
  end
end