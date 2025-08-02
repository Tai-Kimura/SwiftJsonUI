#!/usr/bin/env ruby

require_relative 'base_view_converter'

class GradientViewConverter < BaseViewConverter
  def initialize(component, indent_level = 0, converter_factory = nil)
    super(component, indent_level)
    @converter_factory = converter_factory
  end
  
  def convert
    children = @component['child'] || []
    
    # 子要素を生成
    if children.empty?
      add_line "Color.clear"
    elsif children.length == 1
      if @converter_factory
        child_converter = @converter_factory.create_converter(children.first, @indent_level)
        child_code = child_converter.convert
        child_code.split("\n").each { |line| @generated_code << line }
      end
    else
      add_line "VStack(spacing: 0) {"
      indent do
        children.each do |child|
          if @converter_factory
            child_converter = @converter_factory.create_converter(child, @indent_level)
            child_code = child_converter.convert
            child_code.split("\n").each { |line| @generated_code << line }
          end
        end
      end
      add_line "}"
    end
    
    # グラデーション背景を適用
    if @component['gradient']
      apply_gradient_background
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
  
  private
  
  def apply_gradient_background
    colors = @component['gradient'].map { |color| hex_to_swiftui_color(color) }
    direction = @component['gradientDirection'] || 'Vertical'
    
    gradient_type = case direction
    when 'Horizontal'
      "startPoint: .leading, endPoint: .trailing"
    when 'Oblique'
      "startPoint: .topLeading, endPoint: .bottomTrailing"
    else
      "startPoint: .top, endPoint: .bottom"
    end
    
    add_modifier_line ".background(LinearGradient(colors: [#{colors.join(', ')}], #{gradient_type}))"
  end
end