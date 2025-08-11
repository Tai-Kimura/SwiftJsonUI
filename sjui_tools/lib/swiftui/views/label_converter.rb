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
          
          # fontColor (enabled状態に応じて色を変更)
          if @component['enabled'] == false && @component['disabledFontColor']
            # 無効状態のフォント色
            color = hex_to_swiftui_color(@component['disabledFontColor'])
            add_modifier_line ".foregroundColor(#{color})"
          elsif @component['fontColor']
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
          
          # underline（下線）とlineStyle
          if @component['underline']
            # underlineがHashで詳細設定がある場合
            if @component['underline'].is_a?(Hash) && @component['underline']['lineStyle']
              line_style = @component['underline']['lineStyle']
              case line_style
              when 'Single', 'single'
                add_modifier_line ".underline()"
              when 'Double', 'double'
                add_modifier_line ".underline()"
                add_line "// Note: Double underline not directly supported, using single"
              when 'Thick', 'thick'
                add_modifier_line ".underline()"
                add_line "// Note: Thick underline style applied as regular underline"
              when 'Dashed', 'dashed'
                add_modifier_line ".underline(pattern: .dash)"
              when 'Dotted', 'dotted'
                add_modifier_line ".underline(pattern: .dot)"
              else
                add_modifier_line ".underline()"
              end
            else
              # booleanまたは通常の下線
              add_modifier_line ".underline()"
            end
          elsif @component['lineStyle']
            # 独立したlineStyleプロパティ
            case @component['lineStyle']
            when 'Single', 'single'
              add_modifier_line ".underline()"
            when 'Dashed', 'dashed'
              add_modifier_line ".underline(pattern: .dash)"
            when 'Dotted', 'dotted'
              add_modifier_line ".underline(pattern: .dot)"
            else
              add_line "// lineStyle: #{@component['lineStyle']} - Not directly supported"
            end
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
          
          # linkable プロパティ（リンクとして動作）
          if @component['linkable'] == true || @component['linkable'] == 'true'
            # Linkとしてラップするためのコメント
            add_line "// linkable: true - Consider wrapping in Link or adding .onTapGesture"
            if @component['url']
              add_modifier_line ".onTapGesture {"
              indent do
                add_line "if let url = URL(string: \"#{@component['url']}\") {"
                add_line "    UIApplication.shared.open(url)"
                add_line "}"
              end
              add_line "}"
            end
          end
          
          # partialAttributes（部分的なテキストスタイリング）
          if @component['partialAttributes'] && @component['partialAttributes'].is_a?(Array)
            add_line "// partialAttributes detected - Consider using AttributedString"
            add_line "// Note: SwiftUI requires AttributedString for partial text styling"
            @component['partialAttributes'].each do |partial|
              if partial['range'] && partial['range'].is_a?(Array)
                add_line "// Range: [#{partial['range'][0]}, #{partial['range'][1]}]"
                add_line "//   fontColor: #{partial['fontColor']}" if partial['fontColor']
                add_line "//   underline: #{partial['underline']}" if partial['underline']
                add_line "//   onclick: #{partial['onclick']}" if partial['onclick']
              end
            end
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