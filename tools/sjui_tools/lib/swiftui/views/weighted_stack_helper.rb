module SjuiTools
  module SwiftUI
    module Views
      module WeightedStackHelper
        # WeightedHStackを生成
        def generate_weighted_hstack(children, alignment)
          add_line "GeometryReader { geometry in"
          indent do
            add_line "HStack(alignment: #{alignment}, spacing: 0) {"
            indent do
              render_weighted_children(children, 'horizontal')
            end
            add_line "}"
          end
          add_line "}"
        end
        
        # WeightedVStackを生成
        def generate_weighted_vstack(children, alignment)
          add_line "GeometryReader { geometry in"
          indent do
            add_line "VStack(alignment: #{alignment}, spacing: 0) {"
            indent do
              render_weighted_children(children, 'vertical')
            end
            add_line "}"
          end
          add_line "}"
        end
        
        private
        
        # 重み付けされた子要素をレンダリング
        def render_weighted_children(children, orientation)
          # 固定サイズの子要素のサイズを格納
          fixed_sizes = []
          weighted_children = []
          total_weight = 0.0
          
          # 子要素を分類
          children.each_with_index do |child, index|
            weight = get_child_weight(child, orientation)
            if weight > 0
              weighted_children << { child: child, weight: weight, index: index }
              total_weight += weight
            else
              fixed_sizes << { child: child, index: index }
            end
          end
          
          # 固定サイズの子要素を先にレンダリング（サイズ測定のため）
          fixed_sizes.each do |item|
            child = item[:child]
            add_line "// Fixed size child"
            render_child_without_weight(child, orientation)
          end
          
          # 重み付けされた子要素をレンダリング
          if weighted_children.any? && total_weight > 0
            # 固定サイズの合計を計算するためのGeometryReaderを追加
            weighted_children.each do |item|
              child = item[:child]
              weight = item[:weight]
              weight_ratio = weight / total_weight
              
              add_line "// Weighted child (weight: #{weight})"
              render_weighted_child(child, orientation, weight_ratio)
            end
          end
        end
        
        # 子要素のweightを取得
        def get_child_weight(child, orientation)
          return 0 unless child.is_a?(Hash)
          
          # weightプロパティを確認
          if child['weight']
            return child['weight'].to_f
          end
          
          # 方向別のweightプロパティを確認
          if orientation == 'horizontal' && child['widthWeight']
            return child['widthWeight'].to_f
          elsif orientation == 'vertical' && child['heightWeight']
            return child['heightWeight'].to_f
          end
          
          0
        end
        
        # 重みなしの子要素をレンダリング
        def render_child_without_weight(child, orientation)
          child_copy = child.dup
          child_copy['parent_orientation'] = orientation
          
          child_converter = @converter_factory.create_converter(
            child_copy, 
            @indent_level, 
            @action_manager, 
            @converter_factory, 
            @view_registry
          )
          
          child_code = child_converter.convert
          child_lines = child_code.split("\n")
          child_lines.each { |line| add_line line }
          
          # State変数を継承
          if child_converter.respond_to?(:state_variables) && child_converter.state_variables
            @state_variables.concat(child_converter.state_variables)
          end
        end
        
        # 重み付けされた子要素をレンダリング
        def render_weighted_child(child, orientation, weight_ratio)
          child_copy = child.dup
          child_copy['parent_orientation'] = orientation
          
          # GeometryReaderでラップ
          if orientation == 'horizontal'
            # 水平方向の重み付け
            # 利用可能な幅を計算
            add_line "FixedSizeReader { fixedWidth in"
            indent do
              add_line "let availableWidth = geometry.size.width - fixedWidth"
              add_line "let childWidth = availableWidth * #{weight_ratio.round(4)}"
              
              child_converter = @converter_factory.create_converter(
                child_copy, 
                @indent_level + 1, 
                @action_manager, 
                @converter_factory, 
                @view_registry
              )
              
              child_code = child_converter.convert
              child_lines = child_code.split("\n")
              
              # 最初の行にframeモディファイアを追加
              if child_lines.any?
                first_line = child_lines.shift
                add_line first_line
                indent do
                  add_modifier_line ".frame(width: childWidth)"
                  # 残りの行を追加
                  child_lines.each { |line| add_line line.strip }
                end
              end
            end
            add_line "}"
          else
            # 垂直方向の重み付け
            add_line "FixedSizeReader { fixedHeight in"
            indent do
              add_line "let availableHeight = geometry.size.height - fixedHeight"
              add_line "let childHeight = availableHeight * #{weight_ratio.round(4)}"
              
              child_converter = @converter_factory.create_converter(
                child_copy, 
                @indent_level + 1, 
                @action_manager, 
                @converter_factory, 
                @view_registry
              )
              
              child_code = child_converter.convert
              child_lines = child_code.split("\n")
              
              # 最初の行にframeモディファイアを追加
              if child_lines.any?
                first_line = child_lines.shift
                add_line first_line
                indent do
                  add_modifier_line ".frame(height: childHeight)"
                  # 残りの行を追加
                  child_lines.each { |line| add_line line.strip }
                end
              end
            end
            add_line "}"
          end
          
          # State変数を継承
          if child_converter.respond_to?(:state_variables) && child_converter.state_variables
            @state_variables.concat(child_converter.state_variables)
          end
        end
      end
    end
  end
end