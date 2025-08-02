#!/usr/bin/env ruby

require_relative 'base_view_converter'

class ProgressConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'progress'
    progress = @component['progress'] || 0.5
    
    # @Stateプロパティ
    add_line "@State private var #{id}Value: Double = #{progress}"
    
    # ProgressView
    add_line "ProgressView(value: #{id}Value)"
    
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
end