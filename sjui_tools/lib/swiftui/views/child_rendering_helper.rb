module SjuiTools
  module SwiftUI
    module Views
      module ChildRenderingHelper
        # 子要素をレンダリングする共通処理
        def render_child_element(child, orientation, index, weight_value = 0, total_weight = 0)
          # ZStackの場合、位置関係の処理
          if !orientation
            # 通常のZStackでの子要素をグループ化
            add_line "Group {"
          end
          
          # weightプロパティの処理（weight値が渡された場合のみ）
          if weight_value > 0 && total_weight > 0 && orientation
            apply_weight_to_child(child, orientation, weight_value, total_weight)
          elsif weight_value > 0 && orientation
            # weightがあるが総重量がない場合（Block 2のケース）
            child['parent_orientation'] = orientation
          end
          
          # Wrap with VisibilityWrapper if visibility is set
          child_converter = apply_visibility_wrapper(child)
          if !child_converter
            # Normal child without visibility wrapper
            render_child_with_alignment(child, orientation)
          end
          
          # Propagate state variables
          if child_converter && child_converter.respond_to?(:state_variables) && child_converter.state_variables
            @state_variables.concat(child_converter.state_variables)
          end
          
          # ZStackの場合、位置調整を適用
          if !orientation
            indent do
              apply_zstack_positioning(child, index)
            end
            add_line "}"  # Group終了
          end
        end
        
        private
        
        # weightベースのサイズを子要素に適用
        def apply_weight_to_child(child, orientation, weight_value, total_weight)
          child['parent_orientation'] = orientation
          # weightベースのサイズを直接設定
          if orientation == 'horizontal'
            width_ratio = weight_value / total_weight
            child['_weight_frame'] = ".frame(width: geometry.size.width * #{width_ratio.round(4)})"
          elsif orientation == 'vertical'
            height_ratio = weight_value / total_weight
            child['_weight_frame'] = ".frame(height: geometry.size.height * #{height_ratio.round(4)})"
          end
        end
        
        # アライメント処理を含む子要素のレンダリング
        def render_child_with_alignment(child, orientation)
          # Handle alignment properties for HStack and VStack
          alignment_info = calculate_alignment_needs(child, orientation)
          needs_wrapper = alignment_info[:needs_wrapper]
          wrapper_alignment = alignment_info[:wrapper_alignment]
          needs_spacer_before = alignment_info[:needs_spacer_before]
          needs_spacer_after = alignment_info[:needs_spacer_after]
          
          # Add spacer before if needed
          if needs_spacer_before
            add_line "Spacer()"
          end
          
          # Generate child code
          child_copy = remove_alignment_properties(child, orientation, needs_wrapper)
          
          child_converter = @converter_factory.create_converter(child_copy, @indent_level, @action_manager, @converter_factory, @view_registry)
          child_code = child_converter.convert
          child_lines = child_code.split("\n")
          
          # Wrap child if needed for alignment
          wrap_child_for_alignment(child_lines, orientation, needs_wrapper, wrapper_alignment)
          
          # Add spacer after if needed
          if needs_spacer_after
            add_line "Spacer()"
          end
          
          # Propagate state variables
          if child_converter.respond_to?(:state_variables) && child_converter.state_variables
            @state_variables.concat(child_converter.state_variables)
          end
        end
      end
    end
  end
end