module SjuiTools
  module SwiftUI
    module Views
      module AlignmentWrapperHelper
        def wrap_child_for_alignment(child_lines, orientation, needs_wrapper, wrapper_alignment)
          if needs_wrapper && wrapper_alignment
            if orientation == 'horizontal'
              # Wrap in VStack for vertical alignment in HStack
              # Use frame alignment instead of Spacers
              add_line "VStack {"
              indent do
                child_lines.each { |line| add_line line.strip unless line.strip.empty? }
              end
              add_line "}.frame(maxHeight: .infinity, alignment: #{wrapper_alignment})"
            elsif orientation == 'vertical'
              # Wrap in HStack for horizontal alignment in VStack
              # Use frame alignment instead of Spacers
              add_line "HStack {"
              indent do
                child_lines.each { |line| add_line line.strip unless line.strip.empty? }
              end
              add_line "}.frame(maxWidth: .infinity, alignment: #{wrapper_alignment})"
            end
          else
            # No wrapper needed
            # Add child code directly (already has proper indentation)
            child_lines.each { |line| @generated_code << line }
          end
        end
        
        def remove_alignment_properties(child, orientation, needs_wrapper)
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
        
        def calculate_alignment_needs(child, orientation)
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
          
          {
            needs_wrapper: needs_wrapper,
            wrapper_alignment: wrapper_alignment,
            needs_spacer_before: needs_spacer_before,
            needs_spacer_after: needs_spacer_after
          }
        end
      end
    end
  end
end