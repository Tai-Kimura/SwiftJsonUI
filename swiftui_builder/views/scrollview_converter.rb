#!/usr/bin/env ruby

require_relative 'base_view_converter'

class ScrollViewConverter < BaseViewConverter
  def initialize(component, indent_level = 0, converter_factory = nil)
    super(component, indent_level)
    @converter_factory = converter_factory
  end

  def convert
    children = @component['child'] || []
    
    # スクロール方向の判定
    # orientation属性またはchild要素の配置から判定
    orientation = @component['orientation']
    
    # 子要素が1つでView/SafeAreaViewの場合、その orientation を確認
    if children.length == 1 && ['View', 'SafeAreaView'].include?(children.first['type'])
      child_orientation = children.first['orientation']
      orientation ||= child_orientation
    end
    
    # スクロール軸の設定
    if orientation == 'horizontal'
      axes = '.horizontal'
      stack_type = 'HStack'
    else
      # デフォルトは垂直スクロール
      axes = '.vertical'
      stack_type = 'VStack'
    end
    
    # インジケーターの表示設定
    show_indicators = if orientation == 'horizontal'
      @component['showsHorizontalScrollIndicator'] != false
    else
      @component['showsVerticalScrollIndicator'] != false
    end
    
    add_line "ScrollView(#{axes}, showsIndicators: #{show_indicators}) {"
    
    indent do
      if children.length == 1
        if @converter_factory
          child_converter = @converter_factory.create_converter(children.first, @indent_level)
          child_code = child_converter.convert
          child_code.split("\n").each { |line| @generated_code << line }
        end
      else
        add_line "#{stack_type}(spacing: 0) {"
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