#!/usr/bin/env ruby

require_relative 'base_view_converter'

class NetworkImageConverter < BaseViewConverter
  def convert
    url = @component['url'] || ""
    
    # AsyncImageを使用（iOS 15+）
    add_line "AsyncImage(url: URL(string: \"#{url}\")) { image in"
    indent do
      add_line "image"
      add_modifier_line ".resizable()"
      
      # contentMode
      if @component['contentMode']
        content_mode = map_content_mode(@component['contentMode'])
        add_modifier_line ".aspectRatio(contentMode: #{content_mode})"
      else
        add_modifier_line ".aspectRatio(contentMode: .fit)"
      end
    end
    add_line "} placeholder: {"
    indent do
      # プレースホルダー
      if @component['placeholder']
        add_line "Image(\"#{@component['placeholder']}\")"
      else
        add_line "ProgressView()"
      end
    end
    add_line "}"
    
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
      '.fit'
    else
      '.fit'
    end
  end
end