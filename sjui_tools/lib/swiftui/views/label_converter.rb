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
              # 改行文字をエスケープ
              escaped_interpolated = interpolated.gsub("\n", "\\n")
              add_line "Text(\"#{escaped_interpolated}\")"
            else
              # 単純な変数参照
              add_line "Text(viewModel.#{to_camel_case(template_content)})"
            end
          else
            # 通常のテキスト - 改行文字をエスケープ
            escaped_text = text.gsub("\n", "\\n")
            add_line "Text(\"#{escaped_text}\")"
          end
          
          # SwiftJsonUIの属性に基づいたモディファイア
          # fontSize
          if @component['fontSize']
            add_modifier_line ".font(.system(size: #{@component['fontSize'].to_i}))"
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
            add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{(@component['fontSize'] || 17).to_i}))"
          end
          
          # textAlign
          if @component['textAlign']
            alignment = text_alignment_to_swiftui(@component['textAlign'])
            add_modifier_line ".multilineTextAlignment(#{alignment})"
          end
          
          # lines
          if @component['lines']
            add_modifier_line ".lineLimit(#{@component['lines'].to_i})"
          end
          
          # lineHeightMultiple
          if @component['lineHeightMultiple']
            add_modifier_line ".lineSpacing(#{(@component['lineHeightMultiple'].to_f - 1) * (@component['fontSize'] || 17).to_i}))"
          end
          
          # lineSpacing (直接指定)
          if @component['lineSpacing']
            add_modifier_line ".lineSpacing(#{@component['lineSpacing'].to_f})"
          end
          
          # underline（下線）
          if @component['underline']
            add_modifier_line ".underline()"
          end
          
          # lineBreakMode (SwiftJsonUI uses short forms: Char, Clip, Word, Head, Middle, Tail)
          if @component['lineBreakMode']
            # In SwiftUI, only truncation modes are available as modifiers
            # Word wrapping and char wrapping are default behaviors
            mode = case @component['lineBreakMode']
                   when 'Head'
                     '.head'
                   when 'Middle'
                     '.middle'
                   when 'Tail'
                     '.tail'
                   when 'Clip'
                     # SwiftUI doesn't have direct clip mode, use tail truncation
                     '.tail'
                   when 'Word', 'Char'
                     # These are wrapping modes, not truncation modes
                     # SwiftUI handles wrapping automatically
                     nil
                   else
                     nil
                   end
            add_modifier_line ".truncationMode(#{mode})" if mode
          end
          
          # autoShrink & minimumScaleFactor
          if @component['autoShrink'] && @component['minimumScaleFactor']
            add_modifier_line ".minimumScaleFactor(#{@component['minimumScaleFactor']})"
          end
          
          # edgeInset (パディングとして適用)
          if @component['edgeInset']
            add_modifier_line ".padding(#{@component['edgeInset'].to_i})"
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