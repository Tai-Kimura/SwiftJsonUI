#!/usr/bin/env ruby

require_relative 'base_view_converter'
require_relative '../helpers/font_helper'

module SjuiTools
  module SwiftUI
    module Views
      class RadioConverter < BaseViewConverter
        include SjuiTools::SwiftUI::Helpers::FontHelper
        def convert
          id = @component['id'] || 'radio'
          items = @component['items'] || []
          text = @component['text'] || ""
          
          # Check if this is a radio group with items
          if items.any?
            # Get selection binding
            if @component['selectedValue'] && is_binding?(@component['selectedValue'])
              selection_binding = "viewModel.data.#{extract_binding_property(@component['selectedValue'])}"
            else
              state_var = "selected#{id.split('_').map(&:capitalize).join}"
              add_state_variable(state_var, "String", '""')
              selection_binding = state_var
            end
            
            # Create radio group with ForEach
            add_line "VStack(alignment: .leading, spacing: 8) {"
            indent do
              if text && !text.empty?
                # Escape double quotes in text for Swift string literal
                escaped_text = text.gsub('"', '\\"')
                add_line "Text(\"#{escaped_text}\")"
                # Apply font modifiers using helper
                apply_font_modifiers(@component, self)
              end
              
              items.each do |item|
                add_line "HStack {"
                indent do
                  add_line "Image(systemName: #{selection_binding} == \"#{item}\" ? \"largecircle.fill.circle\" : \"circle\")"
                  add_modifier_line ".foregroundColor(.blue)"
                  add_modifier_line ".onTapGesture {"
                  indent do
                    add_line "#{selection_binding} = \"#{item}\""
                  end
                  add_line "}"
                  # Escape double quotes in item text for Swift string literal
                  escaped_item = item.gsub('"', '\\"')
                  add_line "Text(\"#{escaped_item}\")"
                end
                add_line "}"
              end
            end
            add_line "}"
          else
            # Single radio button (old implementation)
            group = @component['group'] || 'defaultGroup'
            
            # Create @State variable name for selection (グループごとに管理)
            state_var = "selected#{group.split('_').map(&:capitalize).join}"
            
            # Add state variable to requirements
            add_state_variable(state_var, "String", '""')
            
            # カスタムRadioButton実装
            add_line "HStack {"
            indent do
              add_line "Image(systemName: viewModel.data.#{state_var} == \"#{id}\" ? \"largecircle.fill.circle\" : \"circle\")"
              add_modifier_line ".foregroundColor(.blue)"
              add_modifier_line ".onTapGesture {"
              indent do
                add_line "viewModel.data.#{state_var} = \"#{id}\""
                if @component['onclick'] && @action_manager
                  handler_name = @action_manager.register_action(@component['onclick'], 'radio')
                  add_line "#{handler_name}()"
                elsif @component['onclick']
                  add_line "// TODO: Implement #{@component['onclick']} action"
                end
              end
              add_line "}"
              
              if text && !text.empty?
                # Escape double quotes in text for Swift string literal
                escaped_text = text.gsub('"', '\\"')
                add_line "Text(\"#{escaped_text}\")"
                
                # Apply font modifiers using helper
                apply_font_modifiers(@component, self)
                
                if @component['fontColor']
                  color = hex_to_swiftui_color(@component['fontColor'])
                  add_modifier_line ".foregroundColor(#{color})"
                end
              end
            end
            add_line "}"
          end
          
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