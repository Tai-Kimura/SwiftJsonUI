#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class ButtonConverter < BaseViewConverter
        def convert
          text = @component['text'] || "Button"
          # onclickを使用（SwiftJsonUIの属性）
          action = @component['onclick']
          
          # Buttonの基本構造（アクションを設定）
          add_line "Button(action: {"
          indent do
            if action
              # パラメータ付きメソッドの場合（例: "toggleMode:"）
              if action.include?(':')
                method_name = action.gsub(':', '')
                add_line "viewModel.#{method_name}(self)"
              else
                # パラメータなしメソッドの場合
                add_line "viewModel.#{action}()"
              end
            else
              add_line "// No action specified"
            end
          end
          add_line "}) {"
          
          indent do
            add_line "Text(\"#{text}\")"
            
            # fontColor
            if @component['fontColor']
              color = hex_to_swiftui_color(@component['fontColor'])
              add_modifier_line ".foregroundColor(#{color})"
            end
            
            # fontSize
            if @component['fontSize']
              add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
            end
            
            # font
            if @component['font'] == 'bold'
              add_modifier_line ".fontWeight(.bold)"
            elsif @component['font']
              add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{@component['fontSize'] || 17}))"
            end
          end
          add_line "}"
          
          # enabled属性
          if @component['enabled'] == false
            add_modifier_line ".disabled(true)"
          end
          
          # iOS 15+ configuration
          if @component['config'] && @component['config']['style']
            style = button_style_to_swiftui(@component['config']['style'])
            add_modifier_line ".buttonStyle(#{style})"
          end
          
          # 共通のモディファイアを適用（onTapGestureはここで追加される）
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def button_style_to_swiftui(style)
          case style
          when 'plain'
            '.plain'
          when 'bordered'
            '.bordered'
          when 'borderedProminent'
            '.borderedProminent'
          when 'borderless'
            '.borderless'
          else
            '.automatic'
          end
        end
      end
    end
  end
end