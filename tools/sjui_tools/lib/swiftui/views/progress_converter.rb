#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class ProgressConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'progress'
          progress = @component['progress'] || 0.5
          
          # Get progress value (binding or static)
          progress_value = if @component['progress'] && is_binding?(@component['progress'])
                            "viewModel.data.#{extract_binding_property(@component['progress'])}"
                          else
                            # Create @State variable name
                            state_var = "#{id}Value"
                            # Add state variable to requirements
                            add_state_variable(state_var, "Double", progress.to_s)
                            state_var
                          end
          
          # ProgressView
          add_line "ProgressView(value: #{progress_value})"
          
          # progressTintColor
          if @component['progressTintColor']
            color = hex_to_swiftui_color(@component['progressTintColor'])
            add_modifier_line ".tint(#{color})"
          end
          
          # trackTintColor（SwiftUIでは背景として実装）
          if @component['trackTintColor']
            color = hex_to_swiftui_color(@component['trackTintColor'])
            add_modifier_line ".background(#{color})"
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