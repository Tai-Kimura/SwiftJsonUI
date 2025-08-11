# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    class ViewRegistry
      def initialize
        @views = {}
        @view_order = []
        @relative_constraints = []
      end
      
      # ビューを登録
      def register_view(id, component)
        return unless id
        
        @views[id] = {
          component: component,
          index: @view_order.length
        }
        @view_order << id
        
        # 相対位置制約を収集
        collect_relative_constraints(id, component)
      end
      
      # 全ビューの相対位置を解決
      def resolve_positions
        # 各ビューの最終的な位置を計算
        positions = {}
        
        @view_order.each do |view_id|
          positions[view_id] = calculate_position(view_id)
        end
        
        positions
      end
      
      # 特定ビューの制約を取得
      def get_constraints_for(view_id)
        @relative_constraints.select { |c| c[:source] == view_id }
      end
      
      # ビューが別のビューに依存しているか確認
      def depends_on?(source_id, target_id)
        @relative_constraints.any? do |constraint|
          constraint[:source] == source_id && constraint[:target] == target_id
        end
      end
      
      # SwiftUIコード生成用のヘルパー
      def generate_alignment_modifiers(view_id)
        modifiers = []
        constraints = get_constraints_for(view_id)
        
        constraints.each do |constraint|
          modifier = generate_modifier_for_constraint(constraint)
          modifiers << modifier if modifier
        end
        
        modifiers
      end
      
      private
      
      def collect_relative_constraints(id, component)
        # 既存の制約をクリア（同じIDのビューが再登録される場合のため）
        @relative_constraints.reject! { |c| c[:source] == id }
        
        # alignTopOfView, alignBottomOfView, alignLeftOfView, alignRightOfView
        if component['alignTopOfView']
          @relative_constraints << {
            source: id,
            target: component['alignTopOfView'],
            type: :align_top_of,
            edge: :top
          }
        end
        
        if component['alignBottomOfView']
          @relative_constraints << {
            source: id,
            target: component['alignBottomOfView'],
            type: :align_bottom_of,
            edge: :bottom
          }
        end
        
        if component['alignLeftOfView']
          @relative_constraints << {
            source: id,
            target: component['alignLeftOfView'],
            type: :align_left_of,
            edge: :leading
          }
        end
        
        if component['alignRightOfView']
          @relative_constraints << {
            source: id,
            target: component['alignRightOfView'],
            type: :align_right_of,
            edge: :trailing
          }
        end
        
        # alignTopView, alignBottomView, alignLeftView, alignRightView
        # (これらは別の意味：指定ビューの上/下/左/右に配置)
        if component['alignTopView']
          @relative_constraints << {
            source: id,
            target: component['alignTopView'],
            type: :above,
            spacing: component['topMargin'] || 0
          }
        end
        
        if component['alignBottomView']
          @relative_constraints << {
            source: id,
            target: component['alignBottomView'],
            type: :below,
            spacing: component['bottomMargin'] || 0
          }
        end
        
        if component['alignLeftView']
          @relative_constraints << {
            source: id,
            target: component['alignLeftView'],
            type: :left_of,
            spacing: component['leftMargin'] || 0
          }
        end
        
        if component['alignRightView']
          @relative_constraints << {
            source: id,
            target: component['alignRightView'],
            type: :right_of,
            spacing: component['rightMargin'] || 0
          }
        end
      end
      
      def calculate_position(view_id)
        # ビューの位置を計算（依存関係を考慮）
        view_info = @views[view_id]
        return nil unless view_info
        
        position = {
          id: view_id,
          zIndex: view_info[:index]  # デフォルトのz順序
        }
        
        # 相対位置制約から位置を調整
        constraints = get_constraints_for(view_id)
        if constraints.any?
          # 最も優先度の高い制約を適用
          primary_constraint = constraints.first
          if primary_constraint
            target_position = @views[primary_constraint[:target]]
            if target_position
              # ターゲットビューとの相対位置を設定
              position[:relative_to] = primary_constraint[:target]
              position[:constraint_type] = primary_constraint[:type]
            end
          end
        end
        
        position
      end
      
      def generate_modifier_for_constraint(constraint)
        case constraint[:type]
        when :align_top_of
          # AlignmentGuideを使用
          ".alignmentGuide(.top) { d in d[.top] } // Align to #{constraint[:target]}"
        when :align_bottom_of
          ".alignmentGuide(.bottom) { d in d[.bottom] } // Align to #{constraint[:target]}"
        when :align_left_of
          ".alignmentGuide(.leading) { d in d[.leading] } // Align to #{constraint[:target]}"
        when :align_right_of
          ".alignmentGuide(.trailing) { d in d[.trailing] } // Align to #{constraint[:target]}"
        when :above
          ".offset(y: -#{constraint[:spacing] || 0}) // Above #{constraint[:target]}"
        when :below
          ".offset(y: #{constraint[:spacing] || 0}) // Below #{constraint[:target]}"
        when :left_of
          ".offset(x: -#{constraint[:spacing] || 0}) // Left of #{constraint[:target]}"
        when :right_of
          ".offset(x: #{constraint[:spacing] || 0}) // Right of #{constraint[:target]}"
        else
          nil
        end
      end
    end
  end
end