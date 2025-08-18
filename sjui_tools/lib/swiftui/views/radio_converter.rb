#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class RadioConverter < BaseViewConverter
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
                if @component['fontSize']
                  add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
                end
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
            initial_value = (@component['checked'] == true || @component['checked'] == 'true') ? "\"#{id}\"" : '""'
            add_state_variable(state_var, "String", initial_value)
            
            # カスタムRadioButton実装
            add_line "HStack {"
            indent do
              # Use custom icons if provided
              if @component['selectedIcon'] || @component['icon']
                add_line "if #{state_var} == \"#{id}\" {"
                indent do
                  if @component['selectedIcon']
                    add_line "Image(\"#{@component['selectedIcon']}\")"
                    add_modifier_line ".resizable()"
                    add_modifier_line ".aspectRatio(contentMode: .fit)"
                    add_modifier_line ".frame(width: 20, height: 20)"
                  else
                    add_line "Image(systemName: \"largecircle.fill.circle\")"
                    add_modifier_line ".foregroundColor(.blue)"
                  end
                end
                add_line "} else {"
                indent do
                  if @component['icon']
                    add_line "Image(\"#{@component['icon']}\")"
                    add_modifier_line ".resizable()"
                    add_modifier_line ".aspectRatio(contentMode: .fit)"
                    add_modifier_line ".frame(width: 20, height: 20)"
                  else
                    add_line "Image(systemName: \"circle\")"
                    add_modifier_line ".foregroundColor(.blue)"
                  end
                end
                add_line "}"
              else
                add_line "Image(systemName: #{state_var} == \"#{id}\" ? \"largecircle.fill.circle\" : \"circle\")"
                add_modifier_line ".foregroundColor(.blue)"
              end
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
                # Escape double quotes in text for Swift string literal
                escaped_text = text.gsub('"', '\\"')
                add_line "Text(\"#{escaped_text}\")"
                
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