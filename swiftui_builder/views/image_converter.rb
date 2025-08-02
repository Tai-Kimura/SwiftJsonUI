#!/usr/bin/env ruby

require_relative 'base_view_converter'

class ImageConverter < BaseViewConverter
  def convert
    if @component['src']
      processed_src = process_template_value(@component['src'])
      if processed_src.is_a?(Hash) && processed_src[:template_var]
        # テンプレート変数の場合
        add_line "Image(#{to_camel_case(processed_src[:template_var])})"
      else
        # 通常の画像名
        add_line "Image(\"#{@component['src']}\")"
      end
    else
      # デフォルトのシステムイメージ
      add_line "Image(systemName: \"photo\")"
    end
    
    add_modifier_line ".resizable()"
    
    # contentMode
    if @component['contentMode']
      content_mode = map_content_mode(@component['contentMode'])
      add_modifier_line ".aspectRatio(contentMode: #{content_mode})"
    else
      add_modifier_line ".aspectRatio(contentMode: .fit)"
    end
    
    # CircleImageの場合
    if @component['type'] == 'CircleImage'
      add_modifier_line ".clipShape(Circle())"
    end
    
    # canTap & onclick
    if @component['canTap'] && @component['onclick']
      add_modifier_line ".onTapGesture {"
      indent do
        add_line "// TODO: Implement #{@component['onclick']} action"
      end
      add_line "}"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
  
  private
  
  def map_content_mode(mode)
    case mode
    when 'AspectFill', 'aspectFill'
      '.fill'
    when 'AspectFit', 'aspectFit'
      '.fit'
    when 'center'
      '.fit'  # SwiftUIには直接的なcenterモードがないため
    else
      '.fit'
    end
  end
end