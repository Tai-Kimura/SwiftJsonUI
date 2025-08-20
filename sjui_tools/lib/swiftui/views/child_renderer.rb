#!/usr/bin/env ruby

module SjuiTools
  module SwiftUI
    module Views
      module ChildRenderer
        def render_child_element(child, index, orientation, weight_value, total_weight)
          # ZStackの場合、位置関係の処理
          if !orientation
            add_line "Group {"
          end
          
          # weightプロパティの処理
          has_weight = weight_value > 0
          
          # 親のorientationを子に伝える
          if has_weight && orientation
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
          
          # Wrap with VisibilityWrapper if visibility is set
          if child['visibility']
            render_child_with_visibility(child, orientation)
          else
            render_child_with_alignment(child, orientation)
          end
          
          # ZStackの場合、位置調整を適用
          if !orientation
            apply_zstack_positioning(child, index)
            add_line "}"  # Group終了
          end
        end
        
        def render_child_with_visibility(child, orientation)
          visibility_value = child['visibility']
          # Check if it's a binding
          if visibility_value.is_a?(String) && visibility_value.start_with?('@{') && visibility_value.end_with?('}')
            var_name = to_camel_case(visibility_value[2..-2])
            visibility_param = var_name
          else
            visibility_param = "\"#{visibility_value}\""
          end
          
          # Create child converter with extra indent level for content inside VisibilityWrapper
          child_converter = @converter_factory.create_converter(child, @indent_level + 1, @action_manager, @converter_factory, @view_registry)
          child_code = child_converter.convert
          
          # Add VisibilityWrapper wrapper
          add_line "VisibilityWrapper(#{visibility_param}) {"
          indent do
            child_code.split("\n").each { |line| @generated_code << line }
          end
          add_line "}"
          
          # Propagate state variables
          if child_converter.respond_to?(:state_variables) && child_converter.state_variables
            @state_variables.concat(child_converter.state_variables)
          end
        end
        
        def render_child_with_alignment(child, orientation)
          needs_wrapper = false
          wrapper_alignment = nil
          needs_spacer_before = false
          needs_spacer_after = false
          
          if orientation == 'horizontal'
            # In HStack: 
            # - alignTop/Bottom/centerVertical need VStack wrapper for individual vertical alignment
            # - alignLeft/Right/centerHorizontal use Spacers for horizontal positioning
            if child['alignTop']
              needs_wrapper = true
              wrapper_alignment = '.top'
            elsif child['alignBottom']
              needs_wrapper = true
              wrapper_alignment = '.bottom'
            elsif child['centerVertical']
              needs_wrapper = true
              wrapper_alignment = '.center'
            end
            
            # Horizontal positioning with spacers
            if child['alignRight']
              needs_spacer_before = true
            elsif child['alignLeft']
              needs_spacer_after = true
            elsif child['centerHorizontal'] || child['centerInParent']
              needs_spacer_before = true
              needs_spacer_after = true
            end
            
            # centerInParent also needs vertical centering
            if child['centerInParent']
              needs_wrapper = true
              wrapper_alignment = '.center'
            end
          elsif orientation == 'vertical'
            # In VStack:
            # - alignLeft/Right/centerHorizontal need HStack wrapper for individual horizontal alignment
            # - alignTop/Bottom/centerVertical use Spacers for vertical positioning
            if child['alignLeft']
              needs_wrapper = true
              wrapper_alignment = '.leading'
            elsif child['alignRight']
              needs_wrapper = true
              wrapper_alignment = '.trailing'
            elsif child['centerHorizontal']
              needs_wrapper = true
              wrapper_alignment = '.center'
            end
            
            # Vertical positioning with spacers
            if child['alignBottom']
              needs_spacer_before = true
            elsif child['alignTop']
              needs_spacer_after = true
            elsif child['centerVertical'] || child['centerInParent']
              needs_spacer_before = true
              needs_spacer_after = true
            end
            
            # centerInParent also needs horizontal centering
            if child['centerInParent']
              needs_wrapper = true
              wrapper_alignment = '.center'
            end
          end
          
          # Add spacer before if needed
          if needs_spacer_before
            add_line "Spacer()"
          end
          
          # Generate child code
          child_copy = prepare_child_for_rendering(child, orientation, needs_wrapper)
          
          child_converter = @converter_factory.create_converter(child_copy, @indent_level, @action_manager, @converter_factory, @view_registry)
          child_code = child_converter.convert
          child_lines = child_code.split("\n")
          
          # Wrap child if needed for alignment
          if needs_wrapper && wrapper_alignment
            wrap_child_for_alignment(child_lines, orientation, wrapper_alignment)
          else
            # No wrapper needed
            # Indent child code if inside Group (ZStack)
            if !orientation
              indent do
                child_lines.each { |line| @generated_code << "#{' ' * @indent_level * 4}#{line}" }
              end
            else
              child_lines.each { |line| @generated_code << line }
            end
          end
          
          # Add spacer after if needed
          if needs_spacer_after
            add_line "Spacer()"
          end
          
          # Propagate state variables
          if child_converter.respond_to?(:state_variables) && child_converter.state_variables
            @state_variables.concat(child_converter.state_variables)
          end
        end
        
        private
        
        def prepare_child_for_rendering(child, orientation, needs_wrapper)
          # Create a copy of child and remove alignment properties that we handle separately
          child_copy = child.dup
          if orientation == 'horizontal'
            # Remove vertical alignment properties that we handle with wrapper
            child_copy.delete('alignTop') if needs_wrapper
            child_copy.delete('alignBottom') if needs_wrapper
            child_copy.delete('centerVertical') if needs_wrapper
            # Remove horizontal alignment properties that we handle with spacers
            child_copy.delete('alignLeft')
            child_copy.delete('alignRight')
            child_copy.delete('centerHorizontal')
            child_copy.delete('centerInParent')
          elsif orientation == 'vertical'
            # Remove horizontal alignment properties that we handle with wrapper
            child_copy.delete('alignLeft') if needs_wrapper
            child_copy.delete('alignRight') if needs_wrapper  
            child_copy.delete('centerHorizontal') if needs_wrapper
            # Remove vertical alignment properties that we handle with spacers
            child_copy.delete('alignTop')
            child_copy.delete('alignBottom')
            child_copy.delete('centerVertical')
            child_copy.delete('centerInParent')
          end
          child_copy
        end
        
        def wrap_child_for_alignment(child_lines, orientation, wrapper_alignment)
          if orientation == 'horizontal'
            # Wrap in VStack for vertical alignment in HStack
            add_line "VStack {"
            indent do
              child_lines.each { |line| add_line line.strip unless line.strip.empty? }
            end
            add_line "}.frame(maxHeight: .infinity, alignment: #{wrapper_alignment})"
          elsif orientation == 'vertical'
            # Wrap in HStack for horizontal alignment in VStack
            add_line "HStack {"
            indent do
              child_lines.each { |line| add_line line.strip unless line.strip.empty? }
            end
            add_line "}.frame(maxWidth: .infinity, alignment: #{wrapper_alignment})"
          end
        end
      end
    end
  end
end