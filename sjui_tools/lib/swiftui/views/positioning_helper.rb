module SjuiTools
  module SwiftUI
    module Views
      module PositioningHelper
        def apply_zstack_positioning(child, index)
          # 各子要素の位置を調整
          # SwiftJsonUIの各種margin属性を使用してoffsetを計算
          offset_x = 0
          offset_y = 0
          
          # 個別のmargin属性から位置を計算
          left_margin = child['leftMargin'] || 0
          right_margin = child['rightMargin'] || 0
          top_margin = child['topMargin'] || 0
          bottom_margin = child['bottomMargin'] || 0
          
          # 相対配置属性の処理（alignTopOfView, alignBottomOfView, alignLeftOfView, alignRightOfView）
          # または代替形式（alignTopView, alignBottomView, alignLeftView, alignRightView）
          has_relative_positioning = child['alignTopOfView'] || child['alignBottomOfView'] || 
                                    child['alignLeftOfView'] || child['alignRightOfView'] ||
                                    child['alignTopView'] || child['alignBottomView'] ||
                                    child['alignLeftView'] || child['alignRightView']
          
          if has_relative_positioning && @view_registry && child['id']
            # ViewRegistryから相対配置のモディファイアを取得
            modifiers = @view_registry.generate_alignment_modifiers(child['id'])
            modifiers.each do |modifier|
              add_modifier_line modifier
            end
          end
          
          # 通常のoffset計算（相対配置がない場合、または追加の調整として）
          if !has_relative_positioning
            # 通常のoffset計算
            # ZStackでは左上を基準にoffsetを計算
            offset_x = left_margin - right_margin
            offset_y = top_margin - bottom_margin
            
            # SwiftJsonUIの位置属性を処理
            # centerInParent
            if child['centerInParent']
              # ZStackのalignmentで処理されるため、追加のoffsetは不要
            end
            
            # centerVertical / centerHorizontal
            if child['centerVertical'] && !child['centerInParent']
              # 垂直方向のみセンタリング（offsetのy成分をリセット）
              offset_y = 0
            end
            
            if child['centerHorizontal'] && !child['centerInParent']
              # 水平方向のみセンタリング（offsetのx成分をリセット）
              offset_x = 0
            end
            
            # offsetを適用
            if offset_x != 0 || offset_y != 0
              add_modifier_line ".offset(x: #{offset_x}, y: #{offset_y})"
            end
          end
          
          # z-indexの処理（デフォルトは描画順序）
          add_modifier_line ".zIndex(#{index})"
        end
      end
    end
  end
end