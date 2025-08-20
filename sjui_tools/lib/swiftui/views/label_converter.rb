# frozen_string_literal: true

require_relative 'base_view_converter'
require_relative '../helpers/font_helper'

module SjuiTools
  module SwiftUI
    module Views
      # Generated code label/text converter
      # Dynamic mode equivalent: Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Converters/TextConverter.swift
      class LabelConverter < BaseViewConverter
        include SjuiTools::SwiftUI::Helpers::FontHelper
        def convert
          # Get text handler for this component
          label_handler = @binding_handler.is_a?(SjuiTools::SwiftUI::Binding::LabelBindingHandler) ? 
                          @binding_handler : 
                          SjuiTools::SwiftUI::Binding::LabelBindingHandler.new
          
          # Get text content with binding support
          text_content = label_handler.get_text_content(@component)
          
          # Use PartialAttributedText for all text rendering
          add_line "PartialAttributedText("
          indent do
            add_line "#{text_content},"
            
            # Add partialAttributes if present
            if @component['partialAttributes'] && @component['partialAttributes'].is_a?(Array) && !@component['partialAttributes'].empty?
              add_line "partialAttributesDict: ["
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
            
            # Add fontSize
            if @component['fontSize']
              add_line "fontSize: #{@component['fontSize']},"
            end
            
            # Add fontWeight
            if @component['fontWeight']
              add_line "fontWeight: \"#{@component['fontWeight']}\","
            end
            
            # Add fontColor
            if @component['enabled'] == false && @component['disabledFontColor']
              color = hex_to_swiftui_color(@component['disabledFontColor'])
              add_line "fontColor: #{color},"
            elsif @component['fontColor']
              color = hex_to_swiftui_color(@component['fontColor'])
              add_line "fontColor: #{color},"
            end
            
            # Add underline
            if @component['underline']
              add_line "underline: true,"
            end
            
            # Add strikethrough
            if @component['strikethrough']
              add_line "strikethrough: true,"
            end
            
            # Add lineSpacing
            if @component['lineHeightMultiple']
              line_spacing = (@component['lineHeightMultiple'].to_f - 1) * (@component['fontSize'] || 17).to_i
              add_line "lineSpacing: #{line_spacing},"
            elsif @component['lineSpacing']
              add_line "lineSpacing: #{@component['lineSpacing'].to_f},"
            end
            
            # Add lineLimit
            if @component['lines']
              lines_value = @component['lines'].to_i
              if lines_value == 0
                add_line "lineLimit: nil,"
              else
                add_line "lineLimit: #{lines_value},"
              end
            elsif @component['autoShrink']
              add_line "lineLimit: 1,"
            end
            
            # Add textAlignment
            if @component['textAlign']
              alignment = text_alignment_to_swiftui(@component['textAlign'])
              add_line "textAlignment: #{alignment},"
            end
            
            # Add onClickHandler if there are onclick actions in partialAttributes
            if @component['partialAttributes'] && @component['partialAttributes'].is_a?(Array)
              has_onclick = @component['partialAttributes'].any? { |attr| attr['onclick'] }
              if has_onclick
                add_line "onClickHandler: { action in"
                indent do
                  # Generate switch statement for all onclick actions
                  add_line "switch action {"
                  @component['partialAttributes'].each do |attr|
                    if attr['onclick']
                      add_line "case \"#{attr['onclick']}\":"
                      indent do
                        add_line "viewModel.#{attr['onclick']}()"
                      end
                    end
                  end
                  add_line "default:"
                  indent do
                    add_line "break"
                  end
                  add_line "}"
                end
                add_line "},"
              end
            end
            
            # Remove trailing comma from last parameter
            @generated_code[-1] = @generated_code[-1].chomp(',')
          end
          add_line ")"
          
          # lineBreakMode (SwiftJsonUI uses short forms: Char, Clip, Word, Head, Middle, Tail)
          if @component['lineBreakMode']
            mode = case @component['lineBreakMode']
                   when 'Head'
                     '.head'
                   when 'Middle'
                     '.middle'
                   when 'Tail'
                     '.tail'
                   when 'Clip'
                     '.tail'
                   else
                     nil
                   end
            add_modifier_line ".truncationMode(#{mode})" if mode
          end
          
          # autoShrink & minimumScaleFactor
          if @component['autoShrink']
            scale_factor = @component['minimumScaleFactor'] || 0.5
            add_modifier_line ".minimumScaleFactor(#{scale_factor})"
          elsif @component['minimumScaleFactor']
            add_modifier_line ".minimumScaleFactor(#{@component['minimumScaleFactor']})"
          end
          
          # edgeInset (padding)
          if @component['edgeInset']
            add_modifier_line ".padding(#{@component['edgeInset'].to_i})"
          end
          
          # linkable
          if @component['linkable'] == true || @component['linkable'] == 'true'
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
          
          # Apply frame modifiers for weighted views FIRST
          # If this label has a weight in a horizontal/vertical container, make it fill the appropriate dimension
          if @component['weight'] && @component['weight'].to_f > 0
            parent_orientation = @component['parent_orientation']
            
            if parent_orientation == 'horizontal'
              # In horizontal stack with weight - fill width
              add_modifier_line ".frame(maxWidth: .infinity)"
            elsif parent_orientation == 'vertical'
              # In vertical stack with weight - fill height
              add_modifier_line ".frame(maxHeight: .infinity)"
            end
          end
          
          # Apply padding (internal spacing) first
          apply_padding
          
          # Apply frame size (width/height) after padding
          apply_frame_size
          
          # Apply background and corner radius AFTER padding
          # This ensures the background includes the padding area
          if @component['background']
            color = hex_to_swiftui_color(@component['background'])
            add_modifier_line ".background(#{color})"
          end
          
          if @component['cornerRadius']
            add_modifier_line ".cornerRadius(#{@component['cornerRadius'].to_i})"
          end
          
          # Apply margins (external spacing)
          apply_margins
          
          # Apply other modifiers (opacity, hidden, etc.)
          apply_other_modifiers
          
          # Apply binding-specific modifiers
          apply_binding_modifiers
          
          generated_code
        end

        private
        
        def apply_other_modifiers
          # Apply opacity
          if @component['alpha']
            add_modifier_line ".opacity(#{@component['alpha']})"
          elsif @component['opacity']
            add_modifier_line ".opacity(#{@component['opacity']})"
          end
          
          # Apply hidden
          if @component['hidden'] == true
            add_modifier_line ".hidden()"
          end
          
          # Apply disabled
          if @component['enabled'] == false
            add_modifier_line ".disabled(true)"
          end
        end

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