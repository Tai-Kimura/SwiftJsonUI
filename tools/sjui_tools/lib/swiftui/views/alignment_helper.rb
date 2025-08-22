# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    module Views
      module AlignmentHelper
        # センター配置の処理
        def apply_center_alignment
          if @component['centerInParent']
            # 親の中で中央配置（垂直・水平両方）
            # SwiftUIではStackのalignmentとSpacerで実現
            @needs_center_both = true
          elsif @component['centerHorizontal']
            # 水平方向の中央配置
            @needs_center_horizontal = true
          elsif @component['centerVertical']
            # 垂直方向の中央配置
            @needs_center_vertical = true
          end
        end
        
        # エッジ配置の処理
        def apply_edge_alignment
          # これらのプロパティは親のStackでSpacerを使って実現
          @align_top = @component['alignTop']
          @align_bottom = @component['alignBottom']
          @align_left = @component['alignLeft']
          @align_right = @component['alignRight']
        end
        
        # フレーム配置モディファイアの適用
        def apply_alignment_modifiers
          # centerInParentの場合
          if @needs_center_both
            add_modifier_line ".frame(maxWidth: .infinity, maxHeight: .infinity)"
          elsif @needs_center_horizontal
            add_modifier_line ".frame(maxWidth: .infinity)"
          elsif @needs_center_vertical
            add_modifier_line ".frame(maxHeight: .infinity)"
          end
        end
        
        # 親Stack用のアライメント取得
        def get_parent_alignment
          if @component['centerInParent']
            return '.center'
          end
          
          h_align = '.leading'  # デフォルト
          v_align = '.top'      # デフォルト
          
          # 水平方向
          if @component['centerHorizontal'] || @component['alignLeft'] == false && @component['alignRight'] == false
            h_align = '.center'
          elsif @component['alignRight']
            h_align = '.trailing'
          end
          
          # 垂直方向
          if @component['centerVertical'] || @component['alignTop'] == false && @component['alignBottom'] == false
            v_align = '.center'
          elsif @component['alignBottom']
            v_align = '.bottom'
          end
          
          # Alignment組み合わせ
          if v_align == '.top' && h_align == '.leading'
            '.topLeading'
          elsif v_align == '.top' && h_align == '.center'
            '.top'
          elsif v_align == '.top' && h_align == '.trailing'
            '.topTrailing'
          elsif v_align == '.center' && h_align == '.leading'
            '.leading'
          elsif v_align == '.center' && h_align == '.center'
            '.center'
          elsif v_align == '.center' && h_align == '.trailing'
            '.trailing'
          elsif v_align == '.bottom' && h_align == '.leading'
            '.bottomLeading'
          elsif v_align == '.bottom' && h_align == '.center'
            '.bottom'
          elsif v_align == '.bottom' && h_align == '.trailing'
            '.bottomTrailing'
          else
            '.topLeading'
          end
        end
      end
    end
  end
end