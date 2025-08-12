#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class TextFieldConverter < BaseViewConverter
        def convert
          # Get text field handler for this component
          textfield_handler = @binding_handler.is_a?(SjuiTools::SwiftUI::UIKit::TextFieldBindingHandler) ?
                             @binding_handler :
                             SjuiTools::SwiftUI::UIKit::TextFieldBindingHandler.new
          
          # hint (SwiftJsonUIではplaceholderではなくhint)
          hint = @component['hint'] || @component['placeholder'] || ""
          id = @component['id'] || "textField"
          
          # hintAttributes の処理
          if @component['hintAttributes']
            # SwiftUIではplaceholderのスタイルをカスタマイズすることが難しいため、コメントとして記録
            add_line "// hintAttributes: #{@component['hintAttributes'].to_json}"
          end
          
          # Get text binding
          text_binding = if @component['text'] && is_binding?(@component['text'])
                          textfield_handler.get_text_binding(@component)
                        else
                          # If no binding, create a constant binding with empty string
                          ".constant(\"\")"
                        end
          
          # Check if it should be a SecureField
          is_secure = textfield_handler.is_secure_field?(@component)
          
          # TextField or SecureField
          if is_secure
            add_line "SecureField(\"#{hint}\", text: #{text_binding})"
          else
            add_line "TextField(\"#{hint}\", text: #{text_binding})"
          end
          
          # fontSize
          if @component['fontSize']
            add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
          end
          
          # fontColor
          if @component['fontColor']
            color = hex_to_swiftui_color(@component['fontColor'])
            add_modifier_line ".foregroundColor(#{color})"
          end
          
          # font
          if @component['font'] == 'bold'
            add_modifier_line ".fontWeight(.bold)"
          elsif @component['font']
            add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{@component['fontSize'] || 17}))"
          end
          
          # textFieldStyle
          if @component['borderStyle']
            style = text_field_style(@component['borderStyle'])
            add_modifier_line ".textFieldStyle(#{style})"
          end
          
          # input type (keyboard type)
          if @component['input']
            keyboard_type = input_to_keyboard_type(@component['input'])
            add_modifier_line ".keyboardType(#{keyboard_type})"
          end
          
          # contentType (for auto-fill)
          if @component['contentType']
            content_type = map_content_type(@component['contentType'])
            add_modifier_line ".textContentType(#{content_type})"
          end
          
          # Secure text entry - input == 'password'
          if @component['input'] == 'password'
            # SecureFieldを使う必要があるため、最初から作り直す
            @generated_code = []
            add_line "SecureField(\"#{hint}\", text: $#{state_var})"
            # 再度スタイルを適用
            if @component['fontSize']
              add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
            end
            if @component['fontColor']
              color = hex_to_swiftui_color(@component['fontColor'])
              add_modifier_line ".foregroundColor(#{color})"
            end
          end
          
          # Disabled state
          if @component['enabled'] == false
            add_modifier_line ".disabled(true)"
          end
          
          # caretAttributes（カーソル色の設定）
          if @component['caretAttributes'] && @component['caretAttributes']['fontColor']
            caret_color = hex_to_swiftui_color(@component['caretAttributes']['fontColor'])
            add_modifier_line ".accentColor(#{caret_color})"
            add_line "// caretAttributes applied as accentColor"
          end
          
          # textPaddingLeft（テキストの左パディング）
          if @component['textPaddingLeft']
            add_modifier_line ".padding(.leading, #{@component['textPaddingLeft']})"
          end
          
          # Text change handler
          if @component['onTextChange'] && @action_manager
            handler_name = @action_manager.register_action(@component['onTextChange'], 'textfield')
            add_modifier_line ".onChange(of: #{state_var}) { newValue in"
            indent do
              add_line "#{handler_name}()"
            end
            add_line "}"
          end
          
          # 共通のモディファイアを適用
          # Apply binding-specific modifiers
          apply_binding_modifiers
          
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def text_field_style(style)
          case style
          when 'RoundedRect', 'roundedRect'
            '.roundedBorder'
          when 'none'
            '.plain'
          else
            '.automatic'
          end
        end
        
        def input_to_keyboard_type(input)
          case input
          when 'email'
            '.emailAddress'
          when 'password'
            '.default'  # SwiftUIではセキュア入力は別途設定
          when 'number'
            '.numberPad'
          when 'decimal'
            '.decimalPad'
          when 'URL'
            '.URL'
          when 'twitter'
            '.twitter'
          when 'webSearch'
            '.webSearch'
          when 'namePhonePad'
            '.namePhonePad'
          else
            '.default'
          end
        end
        
        def map_content_type(type)
          case type
          when 'username'
            '.username'
          when 'password'
            '.password'
          when 'email'
            '.emailAddress'
          when 'name'
            '.name'
          when 'tel'
            '.telephoneNumber'
          when 'streetAddress'
            '.streetAddressLine1'
          when 'postalCode'
            '.postalCode'
          else
            '.none'
          end
        end
        
        def add_state_variable(name, type, default_value)
          @state_variables ||= []
          @state_variables << "@State private var #{name}: #{type} = #{default_value}"
        end
      end
    end
  end
end