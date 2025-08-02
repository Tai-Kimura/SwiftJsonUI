#!/usr/bin/env ruby

require_relative 'base_view_converter'

class ScrollViewConverter < BaseViewConverter
  def initialize(component, indent_level = 0, converter_factory = nil)
    super(component, indent_level)
    @converter_factory = converter_factory
  end

  def convert
    children = @component['child'] || []
    
    # スクロール方向の判定（デフォルトは垂直）
    # showsIndicatorは表示/非表示の設定なので、スクロール方向の判定には使わない
    axes_param = ''  # デフォルトは垂直スクロールのみ
    
    add_line "ScrollView(#{axes_param}showsIndicators: #{@component['showsVerticalScrollIndicator'] != false}) {"
    
    indent do
      if children.length == 1
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
    end
    add_line "}"
    
    # scrollEnabled
    if @component['scrollEnabled'] == false
      add_modifier_line ".disabled(true)"
    end
    
    # bounces
    if @component['bounces'] == false
      add_modifier_line "// Note: bounce behavior cannot be disabled in SwiftUI"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
end