#!/usr/bin/env ruby

require_relative 'base_view_converter'

class IconLabelConverter < BaseViewConverter
  def convert
    text = @component['text'] || ""
    icon = @component['icon'] || "star"
    iconPosition = @component['iconPosition'] || 'left'
    
    # HStackでアイコンとテキストを並べる
    add_line "HStack(spacing: #{@component['iconSpacing'] || 8}) {"
    indent do
      if iconPosition == 'left'
        add_icon(icon)
        add_text(text)
      else
        add_text(text)
        add_icon(icon)
      end
    end
    add_line "}"
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
  
  private
  
  def add_icon(icon)
    # システムアイコンかカスタムアイコンかを判定
    if icon.start_with?('system:')
      add_line "Image(systemName: \"#{icon.sub('system:', '')}\")"
    else
      add_line "Image(\"#{icon}\")"
    end
    
    # アイコンサイズ
    if @component['iconSize']
      add_modifier_line ".resizable()"
      add_modifier_line ".frame(width: #{@component['iconSize']}, height: #{@component['iconSize']})"
    end
    
    # アイコンカラー
    if @component['iconColor']
      color = hex_to_swiftui_color(@component['iconColor'])
      add_modifier_line ".foregroundColor(#{color})"
    end
  end
  
  def add_text(text)
    add_line "Text(\"#{text}\")"
    
    # fontSize
    if @component['fontSize']
      add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
    end
    
    # fontColor
    if @component['fontColor']
      color = hex_to_swiftui_color(@component['fontColor'])
      add_modifier_line ".foregroundColor(#{color})"
    end
    
    # font (bold対応)
    if @component['font'] == 'bold'
      add_modifier_line ".fontWeight(.bold)"
    elsif @component['font']
      add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{@component['fontSize'] || 17}))"
    end
  end
end