#!/usr/bin/env ruby

require_relative 'base_view_converter'

class TableConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'table'
    cell_layout = @component['cell_layout']
    
    # データバインディングの確認
    has_binding = @component['binding'] && @component['binding']['data']
    binding_data = has_binding ? @component['binding']['data'] : nil
    
    # データ配列名の生成（@{items} → items）
    if binding_data && binding_data.start_with?('@{') && binding_data.end_with?('}')
      data_var_name = binding_data[2..-2]
    else
      data_var_name = 'items'
    end
    
    # SwiftUIのListとして実装
    add_line "List {"
    indent do
      if has_binding && cell_layout
        # データバインディングとセルレイアウトが指定されている場合
        add_line "ForEach(#{to_camel_case(data_var_name)}) { item in"
        indent do
          # セルレイアウトファイル名からビュー名を生成
          cell_view_name = cell_layout.split('/').last.sub(/^_/, '').split('_').map(&:capitalize).join + 'View'
          add_line "#{cell_view_name}(item: item)"
        end
        add_line "}"
      elsif cell_layout
        # セルレイアウトのみ指定されている場合（静的データ）
        add_line "// Cell layout: #{cell_layout}"
        add_line "// Note: Add data binding to use custom cell layout"
        add_line "ForEach(0..<10) { index in"
        indent do
          add_line "Text(\"Row \\(index)\")"
        end
        add_line "}"
      else
        # デフォルトのデモコンテンツ
        add_line "ForEach(0..<10) { index in"
        indent do
          add_line "Text(\"Row \\(index)\")"
        end
        add_line "}"
      end
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