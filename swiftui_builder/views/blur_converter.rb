#!/usr/bin/env ruby

require_relative 'base_view_converter'

class BlurConverter < BaseViewConverter
  def initialize(component, indent_level = 0, converter_factory = nil)
    super(component, indent_level)
    @converter_factory = converter_factory
  end
  
  def convert
    children = @component['child'] || []
    style = @component['style'] || 'regular'
    
    # 子要素を生成
    if children.any?
      children.each do |child|
        if @converter_factory
          child_converter = @converter_factory.create_converter(child, @indent_level)
          child_code = child_converter.convert
          child_code.split("\n").each { |line| @generated_code << line }
        end
      end
    else
      add_line "Color.clear"
    end
    
    # ブラーエフェクトを適用
    add_modifier_line ".background(.ultraThinMaterial)"
    
    # スタイルに応じて調整
    case style
    when 'dark'
      add_modifier_line ".preferredColorScheme(.dark)"
    when 'light'
      add_modifier_line ".preferredColorScheme(.light)"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
end