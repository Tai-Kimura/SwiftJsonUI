#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      # Generated code button converter
      # Dynamic mode equivalent: Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Converters/ButtonConverter.swift
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
            
            # fontColor (デフォルトは白)
            if @component['fontColor']
              color = hex_to_swiftui_color(@component['fontColor'])
              add_modifier_line ".foregroundColor(#{color})"
            else
              add_modifier_line ".foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))"
            end
            
            # Apply padding to Text inside button (same as Dynamic mode)
            apply_padding_to_text
          end
          add_line "}"
          
          # Button's background and corner radius (using buttonStyle)
          if @component['background']
            color = hex_to_swiftui_color(@component['background'])
            add_modifier_line ".background(#{color})"
          end
          
          if @component['cornerRadius']
            add_modifier_line ".cornerRadius(#{@component['cornerRadius'].to_i})"
          end
          
          # Apply margins (outer spacing)
          apply_margins
          
          # enabled属性
          if @component['enabled'] == false
            add_modifier_line ".disabled(true)"
          end
          
          # opacity
          if @component['alpha']
            add_modifier_line ".opacity(#{@component['alpha']})"
          elsif @component['opacity']
            add_modifier_line ".opacity(#{@component['opacity']})"
          end
          
          # hidden
          if @component['hidden'] == true
            add_modifier_line ".hidden()"
          end
          
          generated_code
        end
        
        private
        
        def apply_padding_to_text
          # Apply padding to the Text inside the button (not to the button itself)
          if @component['padding']
            add_modifier_line ".padding(#{@component['padding'].to_i})"
          elsif @component['paddingTop'] || @component['paddingBottom'] || 
                @component['paddingLeft'] || @component['paddingRight']
            top = @component['paddingTop'] || @component['topPadding'] || 0
            bottom = @component['paddingBottom'] || @component['bottomPadding'] || 0
            left = @component['paddingLeft'] || @component['leftPadding'] || 0
            right = @component['paddingRight'] || @component['rightPadding'] || 0
            
            add_modifier_line ".padding(EdgeInsets(top: #{top}, leading: #{left}, bottom: #{bottom}, trailing: #{right}))"
          end
        end
        
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