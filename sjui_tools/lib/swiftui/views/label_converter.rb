# frozen_string_literal: true

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class LabelConverter < BaseViewConverter
        def convert
          text = @component['text'] || ""
          
          # @{...}形式のテンプレート処理
          if text.start_with?('@{') && text.end_with?('}')
            # @{...}の中身を取り出す
            template_content = text[2...-1]
            
            # 文字列補間形式を含む場合
            if template_content.include?('\\(')
              # SwiftUIの文字列補間形式として処理
              # viewModel.プレフィックスを追加して変数を置換
              interpolated = template_content.gsub(/\\?\((\w+)\)/) do |match|
                "\\(viewModel.#{$1})"
              end
              add_line "Text(\"#{interpolated}\")"
            else
              # 単純な変数参照
              add_line "Text(viewModel.#{to_camel_case(template_content)})"
            end
          else
            # 通常のテキスト
            add_line "Text(\"#{text}\")"
          end
          
          # SwiftJsonUIの属性に基づいたモディファイア
          # fontSize
          if @component['fontSize']
            add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
          end
          
          # fontColor
          if @component['fontColor']
            color = hex_to_swiftui_color(@component['fontColor'])
            add_modifier_line ".foregroundColor(#{color})"
          end
          
          # font (bold対応)
          if @component['font'] == 'bold'
            add_modifier_line ".fontWeight(.bold)"
          elsif @component['font']
            add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{@component['fontSize'] || 17}))"
          end
          
          # textAlign
          if @component['textAlign']
            alignment = text_alignment_to_swiftui(@component['textAlign'])
            add_modifier_line ".multilineTextAlignment(#{alignment})"
          end
          
          # lines
          if @component['lines']
            add_modifier_line ".lineLimit(#{@component['lines']})"
          end
          
          # lineHeightMultiple
          if @component['lineHeightMultiple']
            add_modifier_line ".lineSpacing(#{(@component['lineHeightMultiple'].to_f - 1) * (@component['fontSize'] || 17)})"
          end
          
          # autoShrink & minimumScaleFactor
          if @component['autoShrink'] && @component['minimumScaleFactor']
            add_modifier_line ".minimumScaleFactor(#{@component['minimumScaleFactor']})"
          end
          
          # edgeInset (パディングとして適用)
          if @component['edgeInset']
            add_modifier_line ".padding(#{@component['edgeInset']})"
          end
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end

        private

        def text_alignment_to_swiftui(alignment)
          case alignment.downcase
          when 'left', 'leading'
            '.leading'
          when 'right', 'trailing'
            '.trailing'
          when 'center'
            '.center'
          else
            '.leading'
          end
        end
      end
    end
  end
end