#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class ToggleConverter < BaseViewConverter
        def convert
          # Get toggle handler for this component
          toggle_handler = @binding_handler.is_a?(SjuiTools::SwiftUI::Binding::ToggleBindingHandler) ?
                           @binding_handler :
                           SjuiTools::SwiftUI::Binding::ToggleBindingHandler.new
          
          id = @component['id'] || 'toggle'
          text = @component['text'] || @component['label'] || ""
          
          # Get state binding from handler
          state_binding = if @component['isOn'] && is_binding?(@component['isOn'])
                           "$viewModel.data.#{extract_binding_property(@component['isOn'])}"
                         elsif @component['checked'] && is_binding?(@component['checked'])
                           toggle_handler.get_state_binding(@component)
                         else
                           # Create @State variable name
                           state_var = "#{id}IsOn"
                           # Add state variable to requirements
                           add_state_variable(state_var, "Bool", @component['isOn'] || @component['checked'] ? 'true' : 'false')
                           "$viewModel.#{state_var}"
                         end
          
          # Toggle
          add_line "Toggle(isOn: #{state_binding}) {"
          indent do
            add_line "Text(\"#{text}\")"
            
            # labelAttributes の処理
            if @component['labelAttributes']
              label_attrs = @component['labelAttributes']
              
              # fontSize
              if label_attrs['fontSize']
                add_modifier_line ".font(.system(size: #{label_attrs['fontSize']}))"
              elsif @component['fontSize']
                add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
              end
              
              # fontColor
              if label_attrs['fontColor'] || label_attrs['color']
                color = hex_to_swiftui_color(label_attrs['fontColor'] || label_attrs['color'])
                add_modifier_line ".foregroundColor(#{color})"
              elsif @component['fontColor']
                color = hex_to_swiftui_color(@component['fontColor'])
                add_modifier_line ".foregroundColor(#{color})"
              end
              
              # font
              if label_attrs['font']
                if label_attrs['font'] == 'bold'
                  add_modifier_line ".fontWeight(.bold)"
                else
                  add_modifier_line ".font(.custom(\"#{label_attrs['font']}\", size: #{label_attrs['fontSize'] || 17}))"
                end
              elsif @component['font']
                if @component['font'] == 'bold'
                  add_modifier_line ".fontWeight(.bold)"
                else
                  add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{@component['fontSize'] || 17}))"
                end
              end
            else
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
              if @component['font']
                if @component['font'] == 'bold'
                  add_modifier_line ".fontWeight(.bold)"
                else
                  add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{@component['fontSize'] || 17}))"
                end
              end
            end
          end
          add_line "}"
          
          # toggleStyle
          if @component['toggleStyle']
            case @component['toggleStyle']
            when 'switch'
              add_modifier_line ".toggleStyle(SwitchToggleStyle())"
            when 'button'
              add_modifier_line ".toggleStyle(ButtonToggleStyle())"
            when 'checkbox'
              add_modifier_line ".toggleStyle(CheckboxToggleStyle())"
            else
              add_modifier_line ".toggleStyle(DefaultToggleStyle())"
            end
          end
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def add_state_variable(name, type, default_value)
          @state_variables ||= []
          @state_variables << "@State private var #{name}: #{type} = #{default_value}"
        end
      end
    end
  end
end