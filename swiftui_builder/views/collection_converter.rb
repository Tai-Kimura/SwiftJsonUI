#!/usr/bin/env ruby

require_relative 'base_view_converter'

class CollectionConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'collection'
    columns = @component['columns'] || 2
    
    # LazyVGridとして実装
    add_line "LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: #{columns}), spacing: #{@component['itemSpacing'] || 10}) {"
    indent do
      # セルのレイアウトファイルが指定されている場合はコメントとして追加
      if @component['cell_layout']
        add_line "// Cell layout: #{@component['cell_layout']}"
      end
      
      # デモ用のコンテンツ
      add_line "ForEach(0..<20) { index in"
      indent do
        add_line "Text(\"Item \\(index)\")"
        add_modifier_line ".frame(height: 100)"
        add_modifier_line ".frame(maxWidth: .infinity)"
        add_modifier_line ".background(Color.gray.opacity(0.3))"
        add_modifier_line ".cornerRadius(8)"
      end
      add_line "}"
    end
    add_line "}"
    
    # スクロール可能にする
    if @component['scrollEnabled'] != false
      # ScrollViewでラップする必要があることをコメントで示す
      add_modifier_line "// Note: Wrap in ScrollView for scrolling"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
end