# frozen_string_literal: true

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class LabelConverter < BaseViewConverter
        def convert
          # Get text handler for this component
          label_handler = @binding_handler.is_a?(SjuiTools::SwiftUI::Binding::LabelBindingHandler) ? 
                          @binding_handler : 
                          SjuiTools::SwiftUI::Binding::LabelBindingHandler.new
          
          # Get text content with binding support
          text_content = label_handler.get_text_content(@component)
          
          # Simply use the text content as-is
          # The binding handler already handles the correct format
          add_line "Text(#{text_content})"
          
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
            lines_value = @component['lines'].to_i
            if lines_value == 0
              # 0 means unlimited in UIKit, nil means unlimited in SwiftUI
              add_modifier_line ".lineLimit(nil)"
            else
              add_modifier_line ".lineLimit(#{lines_value})"
            end
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
          if @component['autoShrink']
            # minimumScaleFactorが指定されていればその値を、なければデフォルト値を使用
            scale_factor = @component['minimumScaleFactor'] || 0.5
            add_modifier_line ".minimumScaleFactor(#{scale_factor})"
            add_modifier_line ".lineLimit(1)"  # autoShrinkは通常1行での縮小を想定
          elsif @component['minimumScaleFactor']
            # minimumScaleFactorのみが指定されている場合
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
          if @component['partialAttributes'] && @component['partialAttributes'].is_a?(Array) && !@component['partialAttributes'].empty?
            # AttributedStringを使用した実装
            text = @component['text'] || ""
            
            # 最初のTextの行を削除（AttributedStringで置き換えるため）
            @generated_code = []
            
            add_line "Text({"
            indent do
              add_line "var attributedString = AttributedString(\"#{text.gsub("\n", "\\n")}\")"
              
              @component['partialAttributes'].each_with_index do |partial, index|
                if partial['range'] && partial['range'].is_a?(Array) && partial['range'].length == 2
                  start_index = partial['range'][0]
                  end_index = partial['range'][1]
                  
                  add_line ""
                  add_line "// Apply partial attribute #{index + 1}"
                  add_line "if let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: #{start_index}),"
                  add_line "   let endIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: #{end_index}) {"
                  indent do
                    add_line "let range = startIndex..<endIndex"
                    
                    if partial['fontColor']
                      color = hex_to_swiftui_color(partial['fontColor'])
                      add_line "attributedString[range].foregroundColor = #{color}"
                    end
                    
                    if partial['underline']
                      add_line "attributedString[range].underlineStyle = .single"
                      if partial['underline'].is_a?(Hash) && partial['underline']['lineStyle']
                        add_line "// underline lineStyle: #{partial['underline']['lineStyle']}"
                      end
                    end
                    
                    if partial['onclick']
                      add_line "// TODO: Add link for onclick: #{partial['onclick']}"
                      add_line "// attributedString[range].link = URL(string: \"app://#{partial['onclick']}\")"
                    end
                  end
                  add_line "}"
                end
              end
              
              add_line ""
              add_line "return attributedString"
            end
            add_line "}())"
            
            # 既存のモディファイアは引き続き適用可能
            return # 残りの処理をスキップして、通常のText処理を避ける
          end
          
          # Apply binding-specific modifiers
          apply_binding_modifiers
          
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