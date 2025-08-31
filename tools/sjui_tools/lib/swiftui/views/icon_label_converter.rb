#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class IconLabelConverter < BaseViewConverter
        def convert
          text = @component['text'] || ""
          iconOn = @component['icon_on']
          iconOff = @component['icon_off']
          iconPosition = @component['iconPosition'] || 'left'
          onclick = @component['onclick']
          
          # IconLabelViewまたはIconLabelButtonを使用
          if onclick
            add_line "IconLabelButton("
          else
            add_line "IconLabelView("
          end
          
          indent do
            # text
            add_line "text: \"#{text}\","
            
            # icons
            if iconOn
              add_line "iconOn: \"#{iconOn}\","
            end
            
            if iconOff
              add_line "iconOff: \"#{iconOff}\","
            end
            
            # iconPosition
            case iconPosition.downcase
            when 'top'
              add_line "iconPosition: .top,"
            when 'right'
              add_line "iconPosition: .right,"
            when 'bottom'
              add_line "iconPosition: .bottom,"
            else # left or default
              add_line "iconPosition: .left,"
            end
            
            # iconSize
            if @component['iconSize']
              add_line "iconSize: #{@component['iconSize']},"
            end
            
            # iconMargin
            if @component['iconMargin']
              add_line "iconMargin: #{@component['iconMargin']},"
            end
            
            # fontSize
            if @component['fontSize']
              add_line "fontSize: #{@component['fontSize']},"
            end
            
            # fontColor
            if @component['fontColor']
              color = get_swiftui_color(@component['fontColor'])
              add_line "fontColor: #{color},"
            end
            
            # selectedFontColor
            if @component['selectedFontColor']
              color = get_swiftui_color(@component['selectedFontColor'])
              add_line "selectedFontColor: #{color},"
            end
            
            # fontName
            if @component['font'] && @component['font'] != 'bold'
              add_line "fontName: \"#{@component['font']}\","
            end
            
            # action for button (最後のパラメータなのでカンマなし)
            if onclick && @action_manager
              handler_name = @action_manager.register_action(onclick, 'icon_label')
              add_line "action: {"
              indent do
                add_line "#{handler_name}()"
              end
              add_line "}"
            elsif onclick
              add_line "action: {"
              indent do
                add_line "// #{onclick} action"
              end
              add_line "}"
            else
              # 最後のカンマを削除
              if @generated_code.last.end_with?(',')
                @generated_code[-1] = @generated_code.last.chomp(',')
              end
            end
          end
          add_line ")"
          
          # Apply common modifiers
          apply_modifiers
          
          generated_code
        end
      end
    end
  end
end