#!/usr/bin/env ruby

require_relative 'base_view_converter'

class SliderConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'slider'
    min_value = @component['minimumValue'] || 0.0
    max_value = @component['maximumValue'] || 1.0
    value = @component['value'] || 0.5
    
    # @Stateプロパティ
    add_line "@State private var #{id}Value: Double = #{value}"
    
    # Slider
    add_line "Slider(value: $#{id}Value, in: #{min_value}...#{max_value})"
    
    # tintColor
    if @component['tintColor']
      color = hex_to_swiftui_color(@component['tintColor'])
      add_modifier_line ".tint(#{color})"
    end
    
    # onValueChanged
    if @component['onValueChanged']
      add_modifier_line ".onChange(of: #{id}Value) { newValue in"
      indent do
        add_line "// TODO: Implement #{@component['onValueChanged']} action"
      end
      add_line "}"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
end