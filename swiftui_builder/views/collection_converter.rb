#!/usr/bin/env ruby

require_relative 'base_view_converter'

class CollectionConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'collection'
    columns = @component['columns'] || 2
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
    
    # LazyVGridとして実装
    add_line "LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: #{columns}), spacing: #{@component['itemSpacing'] || 10}) {"
    indent do
      if has_binding && cell_layout
        # データバインディングとセルレイアウトが指定されている場合
        add_line "ForEach(#{to_camel_case(data_var_name)}) { item in"
        indent do
          # セルレイアウトファイル名からビュー名を生成
          cell_view_name = cell_layout.split('/').last.sub(/^_/, '').split('_').map(&:capitalize).join + 'View'
          add_line "#{cell_view_name}(item: item)"
          
          # Collectionのセル固有のモディファイア
          if @component['cellHeight']
            add_modifier_line ".frame(height: #{@component['cellHeight']})"
          end
          add_modifier_line ".frame(maxWidth: .infinity)"
        end
        add_line "}"
      elsif cell_layout
        # セルレイアウトのみ指定されている場合（静的データ）
        add_line "// Cell layout: #{cell_layout}"
        add_line "// Note: Add data binding to use custom cell layout"
        add_line "ForEach(0..<20) { index in"
        indent do
          add_line "Text(\"Item \\(index)\")"
          add_modifier_line ".frame(height: 100)"
          add_modifier_line ".frame(maxWidth: .infinity)"
          add_modifier_line ".background(Color.gray.opacity(0.3))"
          add_modifier_line ".cornerRadius(8)"
        end
        add_line "}"
      else
        # デフォルトのデモコンテンツ
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