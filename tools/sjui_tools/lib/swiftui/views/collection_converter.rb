#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class CollectionConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'collection'
          columns = @component['columns'] || 2
          
          # Add helper function for building cell views dynamically
          needs_build_helper = @component['items'] && 
                               @component['items'].start_with?('@{') && 
                               @component['items'].end_with?('}')
          
          if needs_build_helper
            generate_build_cell_view_helper
          end
          
          # cellClasses, headerClasses, footerClasses の処理
          cell_classes = @component['cellClasses'] || []
          header_classes = @component['headerClasses'] || []
          footer_classes = @component['footerClasses'] || []
          
          # Extract the first cell class name (SwiftUI will use this as the view name)
          cell_class_name = extract_view_name(cell_classes.first) if cell_classes.any?
          header_class_name = extract_view_name(header_classes.first) if header_classes.any?
          footer_class_name = extract_view_name(footer_classes.first) if footer_classes.any?
          
          # setTargetAsDataSource と setTargetAsDelegate
          if @component['setTargetAsDataSource']
            add_line "// setTargetAsDataSource: true"
          end
          if @component['setTargetAsDelegate']
            add_line "// setTargetAsDelegate: true"
          end
          
          # Create the main collection view structure
          # Use List for single column, LazyVGrid for multiple columns
          if columns == 1
            # Single column - use List
            add_line "List {"
            indent do
              # Header
              if header_class_name
                add_line "Section {"
                indent do
                  generate_collection_content(cell_class_name, id)
                end
                add_line "} header: {"
                indent do
                  add_line "#{header_class_name}()"
                end
                add_line "}"
                
                # Footer
                if footer_class_name
                  add_modifier_line ".listSectionSeparator(.hidden)"
                  add_line "Section {"
                  indent do
                    add_line "#{footer_class_name}()"
                  end
                  add_line "}"
                end
              else
                generate_collection_content(cell_class_name, id)
                
                # Footer without header
                if footer_class_name
                  add_line ""
                  add_line "#{footer_class_name}()"
                end
              end
            end
            add_line "}"
            add_modifier_line ".listStyle(PlainListStyle())"
          else
            # Multiple columns - use ScrollView with LazyVGrid
            add_line "ScrollView {"
            indent do
              # Header
              if header_class_name
                add_line "#{header_class_name}()"
                add_modifier_line ".padding(.horizontal)"
              end
              
              # Grid content
              add_line "LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: #{@component['itemSpacing'] || 10}), count: #{columns}), spacing: #{@component['itemSpacing'] || 10}) {"
              indent do
                generate_collection_content(cell_class_name, id)
              end
              add_line "}"
              add_modifier_line ".padding(.horizontal)"
              
              # Footer
              if footer_class_name
                add_line ""
                add_line "#{footer_class_name}()"
                add_modifier_line ".padding(.horizontal)"
              end
            end
            add_line "}"
          end
          
          # Apply common modifiers
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def extract_view_name(class_info)
          return nil unless class_info
          
          if class_info.is_a?(Hash)
            # Format: { "className": "InformationListCollectionViewCell" }
            class_name = class_info['className']
          elsif class_info.is_a?(String)
            # Format: "InformationListCollectionViewCell"
            class_name = class_info
          else
            return nil
          end
          
          # Convert UIKit cell class name to SwiftUI view name
          # If it ends with CollectionViewCell, replace with View
          # If it ends with Cell, replace with CellView
          # Otherwise add View
          view_name = if class_name.end_with?('CollectionViewCell')
                        class_name.sub(/CollectionViewCell$/, 'View')
                      elsif class_name.end_with?('cell')
                        # Handle lowercase 'cell' - convert to CellView with proper casing
                        class_name.sub(/cell$/, 'Cell') + 'View'
                      elsif class_name.end_with?('Cell')
                        # Handle uppercase 'Cell' - just add View
                        class_name + 'View'
                      elsif !class_name.end_with?('View')
                        class_name + 'View'
                      else
                        class_name
                      end
          
          view_name
        end
        
        def generate_collection_content_sections(property_name)
          # Generate ForEach for sections
          add_line "ForEach(Array(viewModel.data.#{property_name}.sections.enumerated()), id: \\.offset) { (sectionIndex, section) in"
          indent do
            # Generate cells for this section
            add_line "ForEach(Array(section.cells.enumerated()), id: \\.offset) { (cellIndex, cellData) in"
            indent do
              add_line "// Render cell based on viewName"
              add_line "let viewName = cellData.viewName"
              add_line "let data = cellData.data as? [String: Any] ?? [:]"
              add_line ""
              add_line "// Each cell view is determined by the viewName in the data"
              add_line "// The view should be created dynamically based on viewName"
              add_line "AnyView(buildCellView(viewName: viewName, data: data))"
              
              # Cell-specific modifiers
              if @component['cellHeight']
                add_modifier_line ".frame(height: #{@component['cellHeight']})"
              end
              
              # For grid layouts, ensure cells expand to fill width
              if @component['columns'] && @component['columns'] > 1
                add_modifier_line ".frame(maxWidth: .infinity)"
              end
            end
            add_line "}"
          end
          add_line "}"
        end
        
        def generate_collection_content(cell_class_name, id)
          # Check if items property is specified (e.g., "@{items}")
          items_property = @component['items']
          
          if items_property && items_property.start_with?('@{') && items_property.end_with?('}')
            # Extract property name from @{propertyName}
            property_name = items_property[2...-1]
            
            # Use section-based rendering
            generate_collection_content_sections(property_name)
          else
            # Legacy behavior for backward compatibility
            generate_collection_content_legacy(cell_class_name, id)
          end
        end
        
        def generate_collection_content_legacy(cell_class_name, id)
          if cell_class_name
            # Extract the original class name from the cell classes
            cell_class_info = @component['cellClasses']&.first
            original_class_name = if cell_class_info.is_a?(Hash)
                                    cell_class_info['className']
                                  elsif cell_class_info.is_a?(String)
                                    cell_class_info
                                  else
                                    cell_class_name.sub('View', '')
                                  end
            
            add_line "// Legacy non-section based collection"
            add_line "ForEach(Array(viewModel.data.collectionDataSource.getCellData(for: \"#{original_class_name}\").enumerated()), id: \\.offset) { (index: Int, item: [String: Any]) in"
            indent do
              add_line "#{cell_class_name}(data: item)"
              
              if @component['cellHeight']
                add_modifier_line ".frame(height: #{@component['cellHeight']})"
              end
              
              if @component['columns'] && @component['columns'] > 1
                add_modifier_line ".frame(maxWidth: .infinity)"
              end
            end
            add_line "}"
          else
            # No cell class specified - show placeholder
            add_line "// No cellClasses specified"
            add_line "ForEach(0..<10, id: \\.self) { index in"
            indent do
              add_line "Text(\"Item \\(index)\")"
              add_modifier_line ".frame(maxWidth: .infinity)"
              add_modifier_line ".frame(height: 80)"
              add_modifier_line ".background(Color.gray.opacity(0.1))"
              add_modifier_line ".cornerRadius(8)"
            end
            add_line "}"
          end
        end
        
        def generate_build_cell_view_helper
          add_line ""
          add_line "@ViewBuilder"
          add_line "func buildCellView(viewName: String, data: [String: Any]) -> some View {"
          indent do
            add_line "// This function should instantiate the appropriate view based on viewName"
            add_line "// For now, return a placeholder"
            add_line "switch viewName {"
            
            # Try to generate cases based on possible view names if we have cellClasses
            if @component['cellClasses']
              cell_classes = @component['cellClasses']
              cell_classes.each do |cell_class|
                view_name = extract_view_name(cell_class)
                add_line "case \"#{view_name}\":"
                indent do
                  add_line "#{view_name}(data: data)"
                end
              end
            end
            
            add_line "default:"
            indent do
              add_line "Text(\"Unknown view: \\(viewName)\")"
              add_modifier_line ".foregroundColor(.red)"
            end
            add_line "}"
          end
          add_line "}"
        end
        
        def to_camel_case(str)
          return str if str.nil? || str.empty?
          
          # Handle snake_case to camelCase
          parts = str.split('_')
          parts[0] + parts[1..-1].map(&:capitalize).join
        end
      end
    end
  end
end