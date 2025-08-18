#!/usr/bin/env ruby

module SjuiTools
  module SwiftUI
    module Views
      # Helper module for determining stack alignments
      module StackAlignmentHelper
        def get_hstack_alignment
          # HStackの垂直方向のアライメント
          # 子要素のalign属性も考慮する
          children = @component['child'] || []
          
          # 子要素にalignTop/Bottom/centerVertical/centerInParentがあるかチェック
          has_align_top = children.any? { |c| c['alignTop'] }
          has_align_bottom = children.any? { |c| c['alignBottom'] }
          has_center_vertical = children.any? { |c| c['centerVertical'] || c['centerInParent'] }
          
          # 優先順位: 個別の子要素のalign > gravity
          if has_center_vertical
            return '.center'
          elsif has_align_bottom
            return '.bottom'
          elsif has_align_top
            return '.top'
          end
          
          # gravityから垂直成分を取得（既存のロジック）
          gravity = @component['gravity'] || 'left|top'
          vertical = 'top'  # デフォルト
          
          if gravity.is_a?(Array)
            # 配列の場合、垂直方向の値を探す
            vertical = gravity.find { |g| ['top', 'center', 'bottom'].include?(g) } || 'top'
          elsif gravity.is_a?(String)
            if gravity.include?('|')
              parts = gravity.split('|')
              vertical = parts.find { |p| ['top', 'center', 'bottom'].include?(p) } || 'top'
            else
              # 単一値でも垂直方向の値なら使用（例: "bottom"だけでもOK）
              vertical = ['top', 'center', 'bottom'].include?(gravity) ? gravity : 'top'
            end
          end
          
          case vertical
          when 'top'
            '.top'
          when 'center'
            '.center'
          when 'bottom'
            '.bottom'
          else
            '.top'  # デフォルトは上揃え
          end
        end
        
        def get_vstack_alignment
          # VStackの水平方向のアライメント
          # 子要素のalign属性も考慮する
          children = @component['child'] || []
          
          # 子要素にalignLeft/Right/centerHorizontal/centerInParentがあるかチェック
          has_align_left = children.any? { |c| c['alignLeft'] }
          has_align_right = children.any? { |c| c['alignRight'] }
          has_center_horizontal = children.any? { |c| c['centerHorizontal'] || c['centerInParent'] }
          
          # 優先順位: 個別の子要素のalign > gravity
          if has_center_horizontal
            return '.center'
          elsif has_align_right
            return '.trailing'
          elsif has_align_left
            return '.leading'
          end
          
          # gravityから水平成分を取得（既存のロジック）
          gravity = @component['gravity'] || 'left|top'
          horizontal = 'left'  # デフォルト
          
          if gravity.is_a?(Array)
            # 配列の場合、水平方向の値を探す
            horizontal = gravity.find { |g| ['left', 'center', 'right'].include?(g) } || 'left'
          elsif gravity.is_a?(String)
            if gravity.include?('|')
              parts = gravity.split('|')
              horizontal = parts.find { |p| ['left', 'center', 'right'].include?(p) } || 'left'
            else
              # 単一値でも水平方向の値なら使用（例: "right"だけでもOK）
              horizontal = ['left', 'center', 'right'].include?(gravity) ? gravity : 'left'
            end
          end
          
          case horizontal
          when 'left'
            '.leading'
          when 'center'
            '.center'
          when 'right'
            '.trailing'
          else
            '.leading'  # デフォルトは左揃え
          end
        end
        
        def get_zstack_alignment_for_child(child)
          # 子要素のアライメント属性から判断
          horizontal = nil
          vertical = nil
          
          # 水平方向のアライメント
          if child['alignLeft']
            horizontal = 'leading'
          elsif child['alignRight']
            horizontal = 'trailing'
          elsif child['centerHorizontal'] || child['centerInParent']
            horizontal = 'center'
          end
          
          # 垂直方向のアライメント
          if child['alignTop']
            vertical = 'top'
            # alignTopだけの場合はleadingをデフォルトにする
            horizontal = horizontal || 'leading'
          elsif child['alignBottom']
            vertical = 'bottom'
            # alignBottomだけの場合はleadingをデフォルトにする
            horizontal = horizontal || 'leading'
          elsif child['centerVertical'] || child['centerInParent']
            vertical = 'center'
          end
          
          # alignLeft/Rightだけの場合はtopをデフォルトにする
          if horizontal && !vertical
            vertical = 'top'
          end
          
          # SwiftUIのアライメントに変換
          if horizontal && vertical
            case "#{vertical}_#{horizontal}"
            when 'top_leading'
              '.topLeading'
            when 'top_center'
              '.top'
            when 'top_trailing'
              '.topTrailing'
            when 'center_leading'
              '.leading'
            when 'center_center'
              '.center'
            when 'center_trailing'
              '.trailing'
            when 'bottom_leading'
              '.bottomLeading'
            when 'bottom_center'
              '.bottom'
            when 'bottom_trailing'
              '.bottomTrailing'
            else
              nil
            end
          elsif horizontal
            case horizontal
            when 'leading'
              '.leading'
            when 'trailing'
              '.trailing'
            when 'center'
              '.center'
            else
              nil
            end
          elsif vertical
            case vertical
            when 'top'
              '.top'
            when 'bottom'
              '.bottom'
            when 'center'
              '.center'
            else
              nil
            end
          else
            nil
          end
        end
        
        def get_zstack_alignment
          # ZStackのalignment決定ロジック
          # 明示的にalignment属性が指定されている場合
          if @component['alignment']
            case @component['alignment']
            when 'topLeading'
              '.topLeading'
            when 'top'
              '.top'
            when 'topTrailing'
              '.topTrailing'
            when 'leading', 'left'
              '.leading'
            when 'center'
              '.center'
            when 'trailing', 'right'
              '.trailing'
            when 'bottomLeading'
              '.bottomLeading'
            when 'bottom'
              '.bottom'
            when 'bottomTrailing'
              '.bottomTrailing'
            else
              '.topLeading'
            end
          elsif @component['child'] && @component['child'].is_a?(Array)
            # 子要素のアライメント属性から判断（最初に見つかったもの）
            children_with_align = @component['child'].select do |child|
              next false unless child.is_a?(Hash)
              child['alignTop'] || child['alignBottom'] || child['alignLeft'] || child['alignRight'] ||
              child['centerHorizontal'] || child['centerVertical'] || child['centerInParent']
            end
            
            if children_with_align.any?
              alignment = get_zstack_alignment_for_child(children_with_align.first)
              alignment || '.topLeading'
            else
              '.topLeading'
            end
          else
            '.topLeading'
          end
        end
      end
    end
  end
end