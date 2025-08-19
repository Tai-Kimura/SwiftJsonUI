#!/usr/bin/env ruby

require_relative 'base_view_converter'
require_relative '../helpers/font_helper'

module SjuiTools
  module SwiftUI
    module Views
      # Generated code button converter
      # Dynamic mode equivalent: Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Converters/ButtonConverter.swift
      class ButtonConverter < BaseViewConverter
        include SjuiTools::SwiftUI::Helpers::FontHelper
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
            # Process text with binding support
            if text.include?('@{')
              # Text with interpolation: "Some text @{property} more text"
              interpolated = text.gsub(/@\{([^}]+)\}/) do |match|
                property_name = $1
                # For interpolated text, use viewModel.data directly
                "\\(viewModel.data.#{property_name})"
              end
              escaped_text = interpolated.gsub('"', '\\"').gsub("\n", "\\n")
              add_line "Text(\"#{escaped_text}\")"
            else
              # Regular text - escape double quotes
              escaped_text = text.gsub('"', '\\"')
              add_line "Text(\"#{escaped_text}\")"
            end
            
            # Apply font modifiers using helper
            apply_font_modifiers(@component, self)
            
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
          
          # Apply frame modifiers (size constraints)
          apply_frame_constraints
          apply_frame_size
          
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
          if @component['enabled'] != nil
            enabled_value = @component['enabled']
            if enabled_value.is_a?(String) && enabled_value.start_with?('@{') && enabled_value.end_with?('}')
              # Data binding
              property_name = enabled_value[2...-1]
              add_modifier_line ".disabled(!viewModel.data.#{property_name})"
            elsif enabled_value == false
              add_modifier_line ".disabled(true)"
            elsif enabled_value == true
              # Explicitly enabled, no need to add disabled modifier
            end
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
            padding = @component['padding']
            # Handle array padding values (from style files)
            if padding.is_a?(Array)
              case padding.length
              when 1
                add_modifier_line ".padding(#{padding[0].to_i})"
              when 2
                # Vertical, Horizontal padding
                add_modifier_line ".padding(.horizontal, #{padding[1].to_i})"
                add_modifier_line ".padding(.vertical, #{padding[0].to_i})"
              when 4
                # Top, Right, Bottom, Left
                add_modifier_line ".padding(.top, #{padding[0].to_i})"
                add_modifier_line ".padding(.trailing, #{padding[1].to_i})"
                add_modifier_line ".padding(.bottom, #{padding[2].to_i})"
                add_modifier_line ".padding(.leading, #{padding[3].to_i})"
              end
            else
              add_modifier_line ".padding(#{padding.to_i})"
            end
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