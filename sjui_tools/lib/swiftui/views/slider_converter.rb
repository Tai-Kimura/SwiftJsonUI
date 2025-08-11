#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class SliderConverter < BaseViewConverter
        def convert
          # Slider properties
          min_value = @component['minimumValue'] || 0
          max_value = @component['maximumValue'] || 1
          value = @component['value'] || min_value
          
          # range プロパティの処理（配列形式: [min, max]）
          if @component['range'].is_a?(Array) && @component['range'].length == 2
            min_value = @component['range'][0]
            max_value = @component['range'][1]
          end
          
          # Create @State variable name
          state_var = "sliderValue#{@component['id'] || ''}"
          state_var = state_var.gsub(/[^a-zA-Z0-9]/, '')
          
          # Add state variable to requirements
          add_state_variable(state_var, "Double", value.to_s)
          
          # Slider
          add_line "Slider(value: $#{state_var}, in: #{min_value}...#{max_value})"
          
          # Tint color
          if @component['tintColor']
            color = hex_to_swiftui_color(@component['tintColor'])
            add_modifier_line ".accentColor(#{color})"
          end
          
          # Disabled state
          if @component['enabled'] == false
            add_modifier_line ".disabled(true)"
          end
          
          # Value change handler
          if @component['onValueChanged'] && @action_manager
            handler_name = @action_manager.register_action(@component['onValueChanged'], 'slider')
            add_modifier_line ".onChange(of: #{state_var}) { newValue in"
            indent do
              add_line "#{handler_name}()"
            end
            add_line "}"
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