#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class CollectionConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'collection'
          columns = @component['columns'] || 2
          
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
          # Otherwise, if it ends with Cell but not ViewCell, add View
          view_name = if class_name.end_with?('CollectionViewCell')
                        class_name.sub(/CollectionViewCell$/, 'View')
                      elsif class_name.end_with?('Cell') && !class_name.end_with?('ViewCell')
                        class_name + 'View'
                      elsif !class_name.end_with?('View')
                        class_name + 'View'
                      else
                        class_name
                      end
          
          view_name
        end
        
        def generate_collection_content(cell_class_name, id)
          if cell_class_name
            # Generate ForEach with the cell view
            
            # Check if items property is specified (e.g., "@{items}")
            items_property = @component['items']
            
            if items_property && items_property.start_with?('@{') && items_property.end_with?('}')
              # Extract property name from @{propertyName}
              property_name = items_property[2...-1]
              
              # Extract the original class name for CollectionDataSource
              cell_class_info = @component['cellClasses']&.first
              original_class_name = if cell_class_info.is_a?(Hash)
                                      cell_class_info['className']
                                    elsif cell_class_info.is_a?(String)
                                      cell_class_info
                                    else
                                      cell_class_name.sub('View', '')
                                    end
              
              # Use the specified property with getCellData if it's a CollectionDataSource
              add_line "ForEach(Array(viewModel.data.#{property_name}.getCellData(for: \"#{original_class_name}\").enumerated()), id: \\.offset) { index, item in"
            else
              # Default to collectionDataSource
              # Extract the original class name from the cell classes
              cell_class_info = @component['cellClasses']&.first
              original_class_name = if cell_class_info.is_a?(Hash)
                                      cell_class_info['className']
                                    elsif cell_class_info.is_a?(String)
                                      cell_class_info
                                    else
                                      cell_class_name.sub('View', '')
                                    end
              
              add_line "ForEach(Array(viewModel.data.collectionDataSource.getCellData(for: \"#{original_class_name}\").enumerated()), id: \\.offset) { index, item in"
            end
            indent do
              # Create cell view with data initializer
              add_line "#{cell_class_name}(data: item)"
              
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