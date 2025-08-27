#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class CollectionConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'collection'
          columns = @component['columns'] || 2
          layout = @component['layout'] || 'vertical'
          is_horizontal = layout == 'horizontal'
          
          # Check if sections are defined
          sections = @component['sections'] || []
          
          # Legacy: cellClasses, headerClasses, footerClasses の処理
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
          elsif is_horizontal
            # Horizontal scroll collection
            shows_indicators = @component['showsHorizontalScrollIndicator'] != false
            add_line "ScrollView(.horizontal, showsIndicators: #{shows_indicators}) {"
            indent do
              # Check if we have sections defined
              if @component['sections'] && !@component['sections'].empty?
                # For horizontal sections, use HStack
                add_line "HStack(spacing: #{@component['itemSpacing'] || 10}) {"
                indent do
                  @component['sections'].each_with_index do |section, index|
                    cell_view_name = extract_view_name(section['cell']) if section['cell']
                    
                    if cell_view_name
                      property_name = extract_property_name(@component['items'])
                      if property_name
                        add_line "if let cellsData = viewModel.data.#{property_name}.sections[#{index}].cells?.data {"
                        indent do
                          add_line "ForEach(Array(cellsData.enumerated()), id: \\.offset) { cellIndex, cellData in"
                          indent do
                            add_line "#{cell_view_name}(data: cellData)"
                            
                            if @component['cellWidth']
                              add_modifier_line ".frame(width: #{@component['cellWidth']})"
                            else
                              add_modifier_line ".frame(width: 150)"  # Default width for horizontal items
                            end
                          end
                          add_line "}"
                        end
                        add_line "}"
                      end
                    end
                  end
                end
                add_line "}"
                add_modifier_line ".padding(.horizontal)"
              end
            end
            add_line "}"
          else
            # Multiple columns - use ScrollView with LazyVGrid
            shows_indicators = @component['showsVerticalScrollIndicator'] != false
            add_line "ScrollView(.vertical, showsIndicators: #{shows_indicators}) {"
            indent do
              # Check if we have sections defined
              if @component['sections'] && !@component['sections'].empty?
                # For sections, render header before grid, cells in grid, footer after grid
                @component['sections'].each_with_index do |section, index|
                  header_view_name = extract_view_name(section['header']) if section['header']
                  cell_view_name = extract_view_name(section['cell']) if section['cell']
                  footer_view_name = extract_view_name(section['footer']) if section['footer']
                  
                  # Header outside grid
                  if header_view_name
                    add_line "#{header_view_name}()"
                    add_modifier_line ".padding(.horizontal)"
                  end
                  
                  # Grid with cells - use section columns if specified, otherwise use component columns
                  section_columns = section['columns'] || columns
                  add_line "LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: #{@component['itemSpacing'] || 10}), count: #{section_columns}), spacing: #{@component['itemSpacing'] || 10}) {"
                  indent do
                    property_name = extract_property_name(@component['items'])
                    if property_name && cell_view_name
                      add_line "if let cellsData = viewModel.data.#{property_name}.sections[#{index}].cells?.data {"
                      indent do
                        add_line "ForEach(Array(cellsData.enumerated()), id: \\.offset) { cellIndex, cellData in"
                        indent do
                          add_line "#{cell_view_name}(data: cellData)"
                          
                          if @component['cellHeight']
                            add_modifier_line ".frame(height: #{@component['cellHeight']})"
                          end
                          
                          add_modifier_line ".frame(maxWidth: .infinity)"
                        end
                        add_line "}"
                      end
                      add_line "}"
                    end
                  end
                  add_line "}"
                  add_modifier_line ".padding(.horizontal)"
                  
                  # Footer outside grid
                  if footer_view_name
                    add_line ""
                    add_line "#{footer_view_name}()"
                    add_modifier_line ".padding(.horizontal)"
                  end
                end
              else
                # Legacy behavior - header/footer from cellClasses
                if header_class_name
                  add_line "#{header_class_name}()"
                  add_modifier_line ".padding(.horizontal)"
                end
                
                add_line "LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: #{@component['itemSpacing'] || 10}), count: #{columns}), spacing: #{@component['itemSpacing'] || 10}) {"
                indent do
                  generate_collection_content(cell_class_name, id)
                end
                add_line "}"
                add_modifier_line ".padding(.horizontal)"
                
                if footer_class_name
                  add_line ""
                  add_line "#{footer_class_name}()"
                  add_modifier_line ".padding(.horizontal)"
                end
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
          # If sections are defined in JSON, use those
          if @component['sections'] && !@component['sections'].empty?
            # Generate based on predefined sections structure
            @component['sections'].each_with_index do |section, index|
              cell_view_name = extract_view_name(section['cell']) if section['cell']
              header_view_name = extract_view_name(section['header']) if section['header']
              footer_view_name = extract_view_name(section['footer']) if section['footer']
              
              # Generate section - use section-specific columns if specified
              section_columns = section['columns'] || @component['columns'] || 2
              if section_columns == 1
                # List-style section with header/footer
                add_line "Section {"
                indent do
                  # Cells
                  if cell_view_name
                    add_line "if let cellsData = viewModel.data.#{property_name}.sections[#{index}].cells?.data {"
                    indent do
                      add_line "ForEach(Array(cellsData.enumerated()), id: \\.offset) { cellIndex, cellData in"
                      indent do
                        add_line "#{cell_view_name}(data: cellData)"
                      end
                      add_line "}"
                    end
                    add_line "}"
                  end
                end
                
                # Header
                if header_view_name
                  add_line "} header: {"
                  indent do
                    add_line "#{header_view_name}()"
                  end
                end
                
                add_line "}"
                
                # Footer (as separate section in List)
                if footer_view_name
                  add_line "Section {"
                  indent do
                    add_line "#{footer_view_name}()"
                  end
                  add_line "}"
                end
              else
                # Grid-style sections don't work the same way - cells go in the grid
                # This shouldn't happen in grid layout with sections
                add_line "// Warning: Section-based rendering in grid layout"
                if cell_view_name
                  add_line "if let cellsData = viewModel.data.#{property_name}.sections[#{index}].cells?.data {"
                  indent do
                    add_line "ForEach(Array(cellsData.enumerated()), id: \\.offset) { cellIndex, cellData in"
                    indent do
                      add_line "#{cell_view_name}(data: cellData)"
                      
                      if @component['cellHeight']
                        add_modifier_line ".frame(height: #{@component['cellHeight']})"
                      end
                      
                      if @component['columns'] && @component['columns'] > 1
                        add_modifier_line ".frame(maxWidth: .infinity)"
                      end
                    end
                    add_line "}"
                  end
                  add_line "}"
                end
              end
            end
          else
            # Fallback to dynamic sections from data (when sections not defined in JSON)
            add_line "ForEach(Array(viewModel.data.#{property_name}.sections.enumerated()), id: \\.offset) { sectionIndex, section in"
            indent do
              # Generate cells for this section - need to dynamically instantiate view based on viewName
              add_line "if let cellsData = section.cells?.data, let viewName = section.cells?.viewName {"
              indent do
                add_line "ForEach(Array(cellsData.enumerated()), id: \\.offset) { cellIndex, cellData in"
                indent do
                  # Since we don't know the view name at compile time, we need to use AnyView or a ViewBuilder
                  add_line "// TODO: Implement dynamic view instantiation based on viewName"
                  add_line "Text(\"\\(viewName): \\(cellIndex)\")"
                  
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
            add_line "}"
          end
        end
        
        def extract_property_name(items_property)
          return nil unless items_property
          
          if items_property.start_with?('@{') && items_property.end_with?('}')
            items_property[2...-1]
          else
            nil
          end
        end
        
        def generate_collection_content(cell_class_name, id)
          # Check if items property is specified (e.g., "@{items}")
          property_name = extract_property_name(@component['items'])
          
          if property_name
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