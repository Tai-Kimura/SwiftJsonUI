//
//  CollectionConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI LazyVGrid or List
//

import SwiftUI
#if DEBUG


public struct CollectionConverter {
    
    /// Convert DynamicComponent to SwiftUI Collection (List or LazyVGrid)
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        let columns = component.columns ?? 2
        
        // Check if items is a binding reference (@{propertyName})
        var collectionData: [[String: Any]] = []
        if let itemsBinding = component.rawData["items"] as? String, 
           itemsBinding.hasPrefix("@{") && itemsBinding.hasSuffix("}") {
            // Extract property name from @{propertyName}
            let propertyName = String(itemsBinding.dropFirst(2).dropLast())
            
            // Try to get CollectionDataSource from viewModel data
            if let dataSource = viewModel.data[propertyName] as? CollectionDataSource {
                // Get the first cell class name from cellClasses
                let cellClassName: String? = {
                    if let cellClasses = component.cellClasses?.value {
                        if let classesArray = cellClasses as? [String] {
                            return classesArray.first
                        } else if let classesArray = cellClasses as? [[String: Any]] {
                            return classesArray.first?["className"] as? String
                        }
                    }
                    return nil
                }()
                
                if let cellClassName = cellClassName {
                    // Get cell data for the specified class
                    collectionData = dataSource.getCellData(for: cellClassName)
                }
            }
        }
        
        // Fallback to items as [String] for backward compatibility
        let items = component.items ?? []
        let isHorizontal = component.horizontalScroll ?? false
        
        if columns == 1 && !isHorizontal {
            // Single column - use List
            return AnyView(
                List {
                    // CollectionDataSource-driven content
                    if !collectionData.isEmpty {
                        ForEach(Array(collectionData.enumerated()), id: \.offset) { index, data in
                            // Build cell view based on cellClasses
                            buildCellView(data: data, component: component, viewModel: viewModel, viewId: viewId)
                        }
                    }
                    // Items-driven content (backward compatibility)
                    else if !items.isEmpty {
                        ForEach(0..<items.count, id: \.self) { index in
                            {
                                var text = Text(items[index])
                                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                                if let font = DynamicHelpers.fontFromComponent(component) {
                                    text = text.font(font)
                                }
                                return text
                            }()
                        }
                    }
                    // Child components
                    else if let children = component.childComponents {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        } else {
            // Multiple columns or horizontal scroll
            if isHorizontal {
                // Horizontal scroll - use LazyHGrid
                let gridRows = Array(repeating: GridItem(.flexible()), count: columns)
                
                return AnyView(
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: gridRows, spacing: component.columnSpacing ?? component.spacing ?? 10) {
                            // CollectionDataSource-driven content
                            if !collectionData.isEmpty {
                                ForEach(Array(collectionData.enumerated()), id: \.offset) { index, data in
                                    buildCellView(data: data, component: component, viewModel: viewModel, viewId: viewId)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            // Items-driven content (backward compatibility)
                            else if !items.isEmpty {
                                ForEach(0..<items.count, id: \.self) { index in
                                    Text(items[index])
                                        .font(DynamicHelpers.fontFromComponent(component))
                                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                                        .frame(maxHeight: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            // Child components
                            else if let children = component.childComponents {
                                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                                }
                            }
                        }
                        .padding(getContentInsets(from: component))
                    }
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            } else {
                // Vertical grid - use LazyVGrid
                let gridColumns = Array(repeating: GridItem(.flexible(), spacing: component.lineSpacing), count: columns)
                
                return AnyView(
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: component.columnSpacing ?? component.spacing ?? 10) {
                            // CollectionDataSource-driven content
                            if !collectionData.isEmpty {
                                ForEach(Array(collectionData.enumerated()), id: \.offset) { index, data in
                                    buildCellView(data: data, component: component, viewModel: viewModel, viewId: viewId)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            // Items-driven content (backward compatibility)
                            else if !items.isEmpty {
                                ForEach(0..<items.count, id: \.self) { index in
                                    Text(items[index])
                                        .font(DynamicHelpers.fontFromComponent(component))
                                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            // Child components
                            else if let children = component.childComponents {
                                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                                    DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                                }
                            }
                        }
                    .padding(getContentInsets(from: component))
                }
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            }
        }
    }
    
    private static func getContentInsets(from component: DynamicComponent) -> EdgeInsets {
        // Handle contentInsets
        if let contentInsets = component.contentInsets {
            if let array = contentInsets.value as? [CGFloat] {
                return EdgeInsets(
                    top: array.count > 0 ? array[0] : 0,
                    leading: array.count > 1 ? array[1] : 0,
                    bottom: array.count > 2 ? array[2] : 0,
                    trailing: array.count > 3 ? array[3] : 0
                )
            } else if let value = contentInsets.value as? CGFloat {
                return EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
            }
        }
        
        // Handle insetHorizontal and insetVertical
        let horizontal = component.insetHorizontal ?? 0
        let vertical = component.insetVertical ?? 0
        
        if horizontal > 0 || vertical > 0 {
            return EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
        }
        
        // Default padding
        return EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
    }
    
    /// Build cell view for collection data
    @ViewBuilder
    private static func buildCellView(
        data: [String: Any],
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        // For now, create a simple text view with the data
        // In the future, this could instantiate custom cell views based on cellClasses
        VStack(alignment: .leading, spacing: 4) {
            // Display each key-value pair from the data
            ForEach(Array(data.keys.sorted()), id: \.self) { key in
                if let value = data[key] {
                    HStack {
                        Text(key + ":")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(describing: value))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#endif // DEBUG
