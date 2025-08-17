#!/usr/bin/env ruby

require_relative 'color_helper'

module SjuiTools
  module SwiftUI
    module Views
      module ModifierHelper
        include ColorHelper
        private
        
        def apply_gradient
          colors = @component['gradient'].map { |color| hex_to_swiftui_color(color) }
          direction = @component['gradientDirection'] || 'Vertical'
          
          gradient_type = case direction
          when 'Horizontal'
            "startPoint: .leading, endPoint: .trailing"
          when 'Oblique'
            "startPoint: .topLeading, endPoint: .bottomTrailing"
          else
            "startPoint: .top, endPoint: .bottom"
          end
          
          add_modifier_line ".background(LinearGradient(colors: [#{colors.join(', ')}], #{gradient_type}))"
        end
        
        def apply_safe_area_insets
          positions = @component['safeAreaInsetPositions']
          
          # SafeAreaViewは常にSafeAreaを尊重する
          if @component['type'] == 'SafeAreaView'
            # SafeAreaViewの場合は.ignoresSafeArea()を適用しない
            return
          end
          
          # Viewタイプのみ、デフォルトでSafeAreaを無視
          # ScrollViewはcontentInsetAdjustmentBehaviorで制御される
          if @component['type'] == 'View' && !positions
            add_modifier_line ".ignoresSafeArea()"
            return
          end
          
          # positionsが指定されている場合の処理
          
          if positions.is_a?(Array)
            # 配列の場合、各エッジを処理
            edges = []
            edges << '.top' if positions.include?('top')
            edges << '.bottom' if positions.include?('bottom')
            edges << '.leading' if positions.include?('leading') || positions.include?('left')
            edges << '.trailing' if positions.include?('trailing') || positions.include?('right')
            
            if edges.any?
              add_modifier_line ".ignoresSafeArea(.all, edges: [#{edges.join(', ')}])"
            end
          elsif positions == 'all'
            add_modifier_line ".ignoresSafeArea()"
          elsif positions == 'none'
            # デフォルトでセーフエリアを尊重
          else
            add_line "// safeAreaInsetPositions: #{positions}"
          end
        end
      end
    end
  end
end