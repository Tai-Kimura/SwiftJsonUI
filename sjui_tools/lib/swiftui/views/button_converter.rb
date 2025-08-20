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
          # Always use StateAwareButtonView for dynamic state change support
          convert_state_aware_button
        end
        
        private
        
        def convert_state_aware_button
          text = @component['text'] || "Button"
          action = @component['onclick']
          
          # Use StateAwareButtonView for state-dependent styling
          add_line "StateAwareButtonView("
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
              add_line "text: \"#{escaped_text}\","
            else
              # Regular text - escape double quotes
              escaped_text = text.gsub('"', '\\"')
              add_line "text: \"#{escaped_text}\","
            end
            
            # Add partialAttributes if present
            if @component['partialAttributes'] && @component['partialAttributes'].is_a?(Array) && !@component['partialAttributes'].empty?
              add_line "partialAttributes: ["
              indent do
                @component['partialAttributes'].each_with_index do |partial, index|
                  add_line "["
                  indent do
                    if partial['range'] && partial['range'].is_a?(Array) && partial['range'].length == 2
                      add_line "\"range\": [#{partial['range'][0]}, #{partial['range'][1]}],"
                    end
                    if partial['fontColor']
                      add_line "\"fontColor\": \"#{partial['fontColor']}\","
                    end
                    if partial['fontSize']
                      add_line "\"fontSize\": #{partial['fontSize']},"
                    end
                    if partial['fontWeight']
                      add_line "\"fontWeight\": \"#{partial['fontWeight']}\","
                    end
                    if partial['underline']
                      add_line "\"underline\": true,"
                    end
                    if partial['strikethrough']
                      add_line "\"strikethrough\": true,"
                    end
                    if partial['background']
                      add_line "\"background\": \"#{partial['background']}\","
                    end
                    if partial['onclick']
                      add_line "\"onclick\": \"#{partial['onclick']}\","
                    end
                    # Remove trailing comma from last item
                    @generated_code[-1] = @generated_code[-1].chomp(',')
                  end
                  add_line "]#{ index < @component['partialAttributes'].length - 1 ? ',' : '' }"
                end
              end
              add_line "],"
            end
            
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