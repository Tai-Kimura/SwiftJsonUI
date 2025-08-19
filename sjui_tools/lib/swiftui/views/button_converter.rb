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
          # Check if we need to use StateAwareButton
          if @component['tapBackground'] || @component['hilightColor'] || 
             @component['disabledFontColor'] || @component['disabledBackground']
            return convert_state_aware_button
          end
          
          # Original convert method continues below
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
        
        def convert_state_aware_button
          text = @component['text'] || "Button"
          action = @component['onclick']
          
          # Use StateAwareButtonView for state-dependent styling
          add_line "StateAwareButtonView("
          indent do
            # Text
            escaped_text = text.gsub('"', '\\"')
            add_line "text: \"#{escaped_text}\","
            
            # Action
            if action
              if action.include?(':')
                method_name = action.gsub(':', '')
                add_line "action: { viewModel.#{method_name}(self) },"
              else
                add_line "action: { viewModel.#{action}() },"
              end
            else
              add_line "action: { },"
            end
            
            # Font properties
            if @component['fontSize']
              add_line "fontSize: #{@component['fontSize'].to_i},"
            end
            if @component['fontWeight']
              add_line "fontWeight: \"#{@component['fontWeight']}\","
            end
            
            # Color properties
            if @component['fontColor']
              add_line "fontColor: #{hex_to_swiftui_color(@component['fontColor'])},"
            end
            if @component['background']
              add_line "backgroundColor: #{hex_to_swiftui_color(@component['background'])},"
            end
            
            # State-dependent colors
            if @component['tapBackground']
              add_line "tapBackground: #{hex_to_swiftui_color(@component['tapBackground'])},"
            end
            if @component['hilightColor']
              add_line "hilightColor: #{hex_to_swiftui_color(@component['hilightColor'])},"
            end
            if @component['disabledFontColor']
              add_line "disabledFontColor: #{hex_to_swiftui_color(@component['disabledFontColor'])},"
            end
            if @component['disabledBackground']
              add_line "disabledBackground: #{hex_to_swiftui_color(@component['disabledBackground'])},"
            end
            
            # Other properties
            if @component['cornerRadius']
              add_line "cornerRadius: #{@component['cornerRadius'].to_i},"
            end
            
            # Padding
            if @component['padding']
              padding = @component['padding']
              if padding.is_a?(Array)
                case padding.length
                when 1
                  add_line "padding: EdgeInsets(top: #{padding[0]}, leading: #{padding[0]}, bottom: #{padding[0]}, trailing: #{padding[0]}),"
                when 2
                  add_line "padding: EdgeInsets(top: #{padding[0]}, leading: #{padding[1]}, bottom: #{padding[0]}, trailing: #{padding[1]}),"
                when 4
                  add_line "padding: EdgeInsets(top: #{padding[0]}, leading: #{padding[3]}, bottom: #{padding[2]}, trailing: #{padding[1]}),"
                end
              else
                add_line "padding: EdgeInsets(top: #{padding}, leading: #{padding}, bottom: #{padding}, trailing: #{padding}),"
              end
            end
            
            # Enabled state
            if @component['enabled'] != nil
              enabled_value = @component['enabled']
              if enabled_value.is_a?(String) && enabled_value.start_with?('@{') && enabled_value.end_with?('}')
                property_name = enabled_value[2...-1]
                add_line "isEnabled: viewModel.data.#{property_name}"
              elsif enabled_value == false
                add_line "isEnabled: false"
              elsif enabled_value == true
                add_line "isEnabled: true"
              end
            else
              add_line "isEnabled: true"
            end
          end
          add_line ")"
          
          # Apply frame constraints and margins
          apply_frame_constraints
          apply_frame_size
          apply_margins
          
          generated_code
        end
        
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