#!/usr/bin/env ruby

require_relative 'template_helper'

class BaseViewConverter
  include TemplateHelper
  def initialize(component, indent_level = 0)
    @component = component
    @indent_level = indent_level
    @generated_code = []
  end

  def convert
    raise NotImplementedError, "Subclasses must implement convert method"
  end

  protected

  def add_line(line)
    @generated_code << ("    " * @indent_level + line)
  end

  def add_modifier_line(modifier)
    add_line "    #{modifier}"
  end

  def indent(&block)
    @indent_level += 1
    yield
    @indent_level -= 1
  end

  def generated_code
    @generated_code.join("\n")
  end

  # 共通のモディファイア適用メソッド
  def apply_modifiers
    # サイズ
    if @component['width'] || @component['height']
      width = size_to_swiftui(@component['width'])
      height = size_to_swiftui(@component['height'])
      
      if width && height
        add_modifier_line ".frame(width: #{width}, height: #{height})"
      elsif width
        add_modifier_line ".frame(maxWidth: #{width})"
      elsif height
        add_modifier_line ".frame(height: #{height})"
      end
    end
    
    # 背景色
    if @component['background']
      processed_bg = process_template_value(@component['background'])
      if processed_bg.is_a?(Hash) && processed_bg[:template_var]
        add_modifier_line ".background(#{to_camel_case(processed_bg[:template_var])})"
      else
        color = hex_to_swiftui_color(@component['background'])
        add_modifier_line ".background(#{color})"
      end
    end
    
    # パディング（SwiftJsonUIの属性に対応）
    if @component['padding']
      add_modifier_line ".padding(#{@component['padding']})"
    elsif @component['paddingLeft'] || @component['paddingRight'] || @component['paddingTop'] || @component['paddingBottom']
      # 各方向のパディングを個別に適用
      if @component['paddingLeft']
        add_modifier_line ".padding(.leading, #{@component['paddingLeft']})"
      end
      if @component['paddingRight']
        add_modifier_line ".padding(.trailing, #{@component['paddingRight']})"
      end
      if @component['paddingTop']
        add_modifier_line ".padding(.top, #{@component['paddingTop']})"
      end
      if @component['paddingBottom']
        add_modifier_line ".padding(.bottom, #{@component['paddingBottom']})"
      end
    end
    
    # マージン（SwiftUIではパディングとして実装）
    if @component['leftMargin'] || @component['rightMargin'] || @component['topMargin'] || @component['bottomMargin']
      # マージンをパディングとして適用（簡易的な実装）
      if @component['rightMargin']
        add_modifier_line ".padding(.trailing, #{@component['rightMargin']})"
      end
      if @component['leftMargin']
        add_modifier_line ".padding(.leading, #{@component['leftMargin']})"
      end
      if @component['topMargin']
        add_modifier_line ".padding(.top, #{@component['topMargin']})"
      end
      if @component['bottomMargin']
        add_modifier_line ".padding(.bottom, #{@component['bottomMargin']})"
      end
    end
    
    # コーナー半径
    if @component['cornerRadius']
      processed_radius = process_template_value(@component['cornerRadius'])
      if processed_radius.is_a?(Hash) && processed_radius[:template_var]
        add_modifier_line ".cornerRadius(#{to_camel_case(processed_radius[:template_var])})"
      else
        add_modifier_line ".cornerRadius(#{@component['cornerRadius']})"
      end
    end
    
    # ボーダー
    if @component['borderWidth'] && @component['borderColor']
      processed_width = process_template_value(@component['borderWidth'])
      processed_color = process_template_value(@component['borderColor'])
      
      width_value = if processed_width.is_a?(Hash) && processed_width[:template_var]
        to_camel_case(processed_width[:template_var])
      else
        @component['borderWidth']
      end
      
      color_value = if processed_color.is_a?(Hash) && processed_color[:template_var]
        to_camel_case(processed_color[:template_var])
      else
        hex_to_swiftui_color(@component['borderColor'])
      end
      
      radius_value = if @component['cornerRadius']
        processed_radius = process_template_value(@component['cornerRadius'])
        if processed_radius.is_a?(Hash) && processed_radius[:template_var]
          to_camel_case(processed_radius[:template_var])
        else
          @component['cornerRadius']
        end
      else
        0
      end
      
      add_modifier_line ".overlay(RoundedRectangle(cornerRadius: #{radius_value}).stroke(#{color_value}, lineWidth: #{width_value}))"
    end
    
    # 透明度
    if @component['alpha']
      add_modifier_line ".opacity(#{@component['alpha']})"
    end
    
    # 表示/非表示
    if @component['hidden'] == true || @component['visibility'] == 'gone'
      add_modifier_line ".hidden()"
    elsif @component['visibility'] == 'invisible'
      add_modifier_line ".opacity(0)"
    end
    
    # シャドウ
    if @component['shadow']
      apply_shadow(@component['shadow'])
    end
  end

  def apply_shadow(shadow)
    if shadow.is_a?(String)
      # "color|offsetX|offsetY|opacity|radius" 形式
      parts = shadow.split('|')
      if parts.length >= 5
        color = hex_to_swiftui_color(parts[0])
        add_modifier_line ".shadow(color: #{color}.opacity(#{parts[3]}), radius: #{parts[4]}, x: #{parts[1]}, y: #{parts[2]})"
      end
    elsif shadow.is_a?(Hash)
      color = hex_to_swiftui_color(shadow['color'] || '000000')
      opacity = shadow['opacity'] || 0.3
      radius = shadow['radius'] || 10
      x = shadow['offsetX'] || 0
      y = shadow['offsetY'] || 0
      add_modifier_line ".shadow(color: #{color}.opacity(#{opacity}), radius: #{radius}, x: #{x}, y: #{y})"
    end
  end

  def hex_to_swiftui_color(hex)
    # 先頭の#を削除
    hex = hex.sub(/^#/, '')
    
    # 6桁のHEX値に変換
    if hex.length == 3
      hex = hex.chars.map { |c| c * 2 }.join
    end
    
    # RGB値を計算
    r = hex[0..1].to_i(16) / 255.0
    g = hex[2..3].to_i(16) / 255.0
    b = hex[4..5].to_i(16) / 255.0
    
    "Color(red: #{r}, green: #{g}, blue: #{b})"
  end

  def size_to_swiftui(size)
    case size
    when 'matchParent'
      '.infinity'
    when 'wrapContent'
      nil
    when nil
      nil
    else
      size.to_s
    end
  end

  def text_alignment_to_swiftui(alignment)
    # SwiftJsonUIでは "Left", "Right", "Center" (大文字始まり)
    case alignment
    when 'Center', 'center'
      '.center'
    when 'Left', 'left'
      '.leading'
    when 'Right', 'right'
      '.trailing'
    else
      '.leading'
    end
  end
end