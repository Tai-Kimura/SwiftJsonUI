#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class IndicatorConverter < BaseViewConverter
        def convert
          # Check hidesWhenStopped property
          hides_when_stopped = @component['hidesWhenStopped'] != false  # default true
          is_animating = @component['isAnimating'] != false  # default true
          
          # If hidesWhenStopped is true and not animating, don't show the indicator
          if hides_when_stopped && !is_animating
            add_line "EmptyView()"
          else
            # ProgressView（インジケーター）
            add_line "ProgressView()"
            
            # style
            if @component['style']
              style = indicator_style_to_swiftui(@component['style'])
              add_modifier_line ".progressViewStyle(#{style})"
            end
            
            # color, tintColor, or tint
            if @component['color'] || @component['tintColor'] || @component['tint']
              color = hex_to_swiftui_color(@component['color'] || @component['tintColor'] || @component['tint'])
              add_modifier_line ".tint(#{color})"
            end
          end
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def indicator_style_to_swiftui(style)
          case style
          when 'large', 'Large'
            '.circular'
          when 'medium', 'Medium'
            '.circular'
          else
            '.circular'
          end
        end
      end
    end
  end
end