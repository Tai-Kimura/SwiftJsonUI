#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class RadioConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'radio'
          group = @component['group'] || 'defaultGroup'
          text = @component['text'] || ""
          
          # Create @State variable name for selection (グループごとに管理)
          state_var = "selected#{group.split('_').map(&:capitalize).join}"
          
          # Add state variable to requirements
          add_state_variable(state_var, "String", '""')
          
          # カスタムRadioButton実装
          add_line "HStack {"
          indent do
            add_line "Image(systemName: #{state_var} == \"#{id}\" ? \"largecircle.fill.circle\" : \"circle\")"
            add_modifier_line ".foregroundColor(.blue)"
            add_modifier_line ".onTapGesture {"
            indent do
              add_line "#{state_var} = \"#{id}\""
              if @component['onclick'] && @action_manager
                handler_name = @action_manager.register_action(@component['onclick'], 'radio')
                add_line "#{handler_name}()"
              elsif @component['onclick']
                add_line "// TODO: Implement #{@component['onclick']} action"
              end
            end
            add_line "}"
            
            if text && !text.empty?
              add_line "Text(\"#{text}\")"
              
              if @component['fontSize']
                add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
              end
              
              if @component['fontColor']
                color = hex_to_swiftui_color(@component['fontColor'])
                add_modifier_line ".foregroundColor(#{color})"
              end
            end
          end
          add_line "}"
          
          # Disabled state
          if @component['enabled'] == false
            add_modifier_line ".disabled(true)"
            add_modifier_line ".opacity(0.6)"
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