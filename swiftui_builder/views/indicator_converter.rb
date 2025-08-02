#!/usr/bin/env ruby

require_relative 'base_view_converter'

class IndicatorConverter < BaseViewConverter
  def convert
    # ProgressView（インジケーター）
    add_line "ProgressView()"
    
    # style
    if @component['style']
      style = indicator_style_to_swiftui(@component['style'])
      add_modifier_line ".progressViewStyle(#{style})"
    end
    
    # color
    if @component['color']
      color = hex_to_swiftui_color(@component['color'])
      add_modifier_line ".tint(#{color})"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
  
  private
  
  def indicator_style_to_swiftui(style)
    case style
    when 'large', 'Large'
      '.circular'
    when 'medium', 'Medium'
      '.circular'
    else
      '.circular'
    end
  end
end