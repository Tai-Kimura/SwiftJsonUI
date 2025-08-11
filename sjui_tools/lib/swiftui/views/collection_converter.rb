#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class CollectionConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'collection'
          columns = @component['columns'] || 2
          cell_layout = @component['cell_layout']
          
          # cellClasses, headerClasses, footerClasses の処理
          cell_classes = @component['cellClasses']
          header_classes = @component['headerClasses']
          footer_classes = @component['footerClasses']
          
          # クラス情報をコメントとして記録
          if cell_classes
            add_line "// cellClasses: #{cell_classes}"
          end
          if header_classes
            add_line "// headerClasses: #{header_classes}"
          end
          if footer_classes
            add_line "// footerClasses: #{footer_classes}"
          end
          
          # データ設定の確認（itemsキーを使用）
          items_data = @component['items']
          has_items = !items_data.nil?
          
          # データ配列名の生成（@{items} → items）
          if items_data && items_data.is_a?(String) && items_data.start_with?('@{') && items_data.end_with?('}')
            data_var_name = items_data[2..-2]
          else
            data_var_name = 'items'
          end
          
          # LazyVGridとして実装
          add_line "LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: #{columns}), spacing: #{@component['itemSpacing'] || 10}) {"
          indent do
            if cell_layout
              # セルレイアウトが指定されている場合
              if has_items
                # itemsが指定されている場合は、その変数を使用
                add_line "ForEach(#{to_camel_case(data_var_name)}) { item in"
              else
                # itemsが指定されていない場合は空の配列
                add_line "ForEach([]) { item in"
              end
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
            else
              # セルレイアウトが指定されていない場合のデフォルトコンテンツ
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
    end
  end
end