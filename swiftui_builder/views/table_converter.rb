#!/usr/bin/env ruby

require_relative 'base_view_converter'

class TableConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'table'
    
    # SwiftUIのListとして実装
    add_line "List {"
    indent do
      # セルのレイアウトファイルが指定されている場合はコメントとして追加
      if @component['cell_layout']
        add_line "// Cell layout: #{@component['cell_layout']}"
      end
      
      # デモ用のコンテンツ
      add_line "ForEach(0..<10) { index in"
      indent do
        add_line "Text(\"Row \\(index)\")"
      end
      add_line "}"
    end
    add_line "}"
    
    # セパレーター非表示
    if @component['hideSeparator'] == true
      add_modifier_line ".listStyle(.plain)"
      add_modifier_line ".listRowSeparator(.hidden)"
    end
    
    # リストスタイル
    if @component['listStyle']
      style = table_style_to_swiftui(@component['listStyle'])
      add_modifier_line ".listStyle(#{style})"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
  
  private
  
  def table_style_to_swiftui(style)
    case style
    when 'grouped'
      '.grouped'
    when 'insetGrouped'
      '.insetGrouped'
    when 'sidebar'
      '.sidebar'
    else
      '.plain'
    end
  end
end