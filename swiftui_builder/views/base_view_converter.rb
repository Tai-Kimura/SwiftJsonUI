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
      # widthの処理
      processed_width = process_template_value(@component['width'])
      if processed_width.is_a?(Hash) && processed_width[:template_var]
        width_value = to_camel_case(processed_width[:template_var])
      else
        width_value = size_to_swiftui(@component['width'])
      end
      
      # heightの処理
      processed_height = process_template_value(@component['height'])
      if processed_height.is_a?(Hash) && processed_height[:template_var]
        height_value = to_camel_case(processed_height[:template_var])
      else
        height_value = size_to_swiftui(@component['height'])
      end
      
      # テンプレート変数の場合は型変換が必要
      if processed_width.is_a?(Hash) && processed_width[:template_var]
        width_param = "CGFloat(#{width_value})"
      else
        width_param = width_value
      end
      
      if processed_height.is_a?(Hash) && processed_height[:template_var]
        height_param = "CGFloat(#{height_value})"
      else
        height_param = height_value
      end
      
      if width_value && height_value
        add_modifier_line ".frame(width: #{width_param}, height: #{height_param})"
      elsif width_value
        if width_value == '.infinity'
          add_modifier_line ".frame(maxWidth: #{width_param})"
        else
          add_modifier_line ".frame(width: #{width_param})"
        end
      elsif height_value
        add_modifier_line ".frame(height: #{height_param})"
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
    if @component['padding'] || @component['paddings']
      padding = @component['padding'] || @component['paddings']
      if padding.is_a?(Array)
        case padding.length
        when 1
          add_modifier_line ".padding(#{padding[0]})"
        when 2
          add_modifier_line ".padding(.vertical, #{padding[0]})"
          add_modifier_line ".padding(.horizontal, #{padding[1]})"
        when 4
          add_modifier_line ".padding(.top, #{padding[0]})"
          add_modifier_line ".padding(.horizontal, #{padding[1]})"
          add_modifier_line ".padding(.bottom, #{padding[2]})"
        end
      else
        add_modifier_line ".padding(#{padding})"
      end
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
    if @component['margin'] || @component['margins']
      margin = @component['margin'] || @component['margins']
      if margin.is_a?(Array)
        case margin.length
        when 1
          add_modifier_line ".padding(#{margin[0]})"
        when 2
          add_modifier_line ".padding(.vertical, #{margin[0]})"
          add_modifier_line ".padding(.horizontal, #{margin[1]})"
        when 4
          add_modifier_line ".padding(.top, #{margin[0]})"
          add_modifier_line ".padding(.horizontal, #{margin[1]})"
          add_modifier_line ".padding(.bottom, #{margin[2]})"
        end
      else
        add_modifier_line ".padding(#{margin})"
      end
    elsif @component['leftMargin'] || @component['rightMargin'] || @component['topMargin'] || @component['bottomMargin']
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
    
    # クリッピング
    if @component['clipToBounds'] == true
      add_modifier_line ".clipped()"
    end
    
    # 最小/最大サイズ
    if @component['minWidth'] || @component['maxWidth'] || @component['minHeight'] || @component['maxHeight']
      frame_params = []
      frame_params << "minWidth: #{@component['minWidth']}" if @component['minWidth']
      frame_params << "maxWidth: #{size_to_swiftui(@component['maxWidth']) || @component['maxWidth']}" if @component['maxWidth']
      frame_params << "minHeight: #{@component['minHeight']}" if @component['minHeight']
      frame_params << "maxHeight: #{size_to_swiftui(@component['maxHeight']) || @component['maxHeight']}" if @component['maxHeight']
      add_modifier_line ".frame(#{frame_params.join(', ')})"
    end
    
    # アスペクト比
    if @component['aspectWidth'] && @component['aspectHeight']
      ratio = @component['aspectWidth'].to_f / @component['aspectHeight'].to_f
      add_modifier_line ".aspectRatio(#{ratio}, contentMode: .fit)"
    end
    
    # ユーザーインタラクション
    if @component['userInteractionEnabled'] == false
      add_modifier_line ".disabled(true)"
    end
    
    # 中央配置
    if @component['centerInParent'] == true
      add_modifier_line ".frame(maxWidth: .infinity, maxHeight: .infinity)"
    end
    
    # weight（親がStack内の場合に使用）
    if @component['weight']
      weight = @component['weight'].to_f
      if weight > 0
        add_modifier_line ".frame(maxWidth: .infinity)"
        add_modifier_line ".frame(maxHeight: .infinity)"
      end
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
  
  # @Stateプロパティを返すメソッド（サブクラスでオーバーライド可能）
  def state_properties
    []
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
    when Numeric
      size.to_s
    when String
      # 数値文字列かどうかチェック
      if size =~ /^\d+(\.\d+)?$/
        size
      else
        # それ以外の文字列（変数名など）
        size
      end
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