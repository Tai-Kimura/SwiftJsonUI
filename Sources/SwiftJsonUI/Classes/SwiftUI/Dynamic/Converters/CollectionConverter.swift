//
//  CollectionConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI LazyVGrid or List
//

import SwiftUI
#if DEBUG

// MARK: - String Extension for camelCase to snake_case conversion
extension String {
    func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self
            .replacingOccurrences(of: acronymPattern, with: "$1_$2", options: .regularExpression)
            .replacingOccurrences(of: normalPattern, with: "$1_$2", options: .regularExpression)
            .lowercased()
    }
}

public struct CollectionConverter {
    
    /// Convert DynamicComponent to SwiftUI Collection (List or LazyVGrid)
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        let globalColumns = component.columns ?? 2
        let sections = component.sections ?? []
        
        // Check if items is a binding reference (@{propertyName})
        var dataSource: CollectionDataSource? = nil
        
        if let itemsBinding = component.rawData["items"] as? String, 
           itemsBinding.hasPrefix("@{") && itemsBinding.hasSuffix("}") {
            // Extract property name from @{propertyName}
            let propertyName = String(itemsBinding.dropFirst(2).dropLast())
            
            // Try to get CollectionDataSource from viewModel data
            dataSource = viewModel.data[propertyName] as? CollectionDataSource
        }
        
        // Determine if we should use section-based rendering
        let useSections = !sections.isEmpty && dataSource != nil
        
        if useSections {
            // Section-based rendering
            return renderSectionBasedCollection(
                component: component,
                sections: sections,
                dataSource: dataSource!,
                globalColumns: globalColumns,
                viewModel: viewModel,
                viewId: viewId
            )
        } else {
            // Legacy rendering (backward compatibility)
            return renderLegacyCollection(
                component: component,
                globalColumns: globalColumns,
                viewModel: viewModel,
                viewId: viewId
            )
        }
    }
    
    /// Render collection using the new section-based structure
    private static func renderSectionBasedCollection(
        component: DynamicComponent,
        sections: [[String: Any]],
        dataSource: CollectionDataSource,
        globalColumns: Int,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> AnyView {
        return AnyView(
            ScrollView {
                VStack(spacing: 10) {
                    // Iterate through sections
                    ForEach(0..<min(sections.count, dataSource.sections.count), id: \.self) { sectionIndex in
                        let sectionConfig = sections[sectionIndex]
                        let sectionData = dataSource.sections[sectionIndex]
                        
                        // Determine columns for this section
                        let sectionColumns = sectionConfig["columns"] as? Int ?? globalColumns
                        
                        VStack(spacing: 10) {
                            // Header
                            if let headerName = sectionConfig["header"] as? String,
                               let headerData = sectionData.header {
                                buildHeaderView(
                                    headerClassName: headerName,
                                    data: headerData.data,
                                    viewModel: viewModel,
                                    viewId: viewId
                                )
                            }
                            
                            // Cells
                            if let cellName = sectionConfig["cell"] as? String,
                               let cellsData = sectionData.cells {
                                if sectionColumns == 1 {
                                    // List-style for single column
                                    VStack(spacing: 8) {
                                        ForEach(0..<cellsData.data.count, id: \.self) { cellIndex in
                                            buildCellView(
                                                cellClassName: cellName,
                                                data: cellsData.data[cellIndex],
                                                component: component,
                                                viewModel: viewModel,
                                                viewId: viewId
                                            )
                                        }
                                    }
                                } else {
                                    // Grid for multiple columns
                                    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: component.lineSpacing ?? 10), count: sectionColumns)
                                    
                                    LazyVGrid(columns: gridColumns, spacing: component.columnSpacing ?? component.spacing ?? 10) {
                                        ForEach(0..<cellsData.data.count, id: \.self) { cellIndex in
                                            buildCellView(
                                                cellClassName: cellName,
                                                data: cellsData.data[cellIndex],
                                                component: component,
                                                viewModel: viewModel,
                                                viewId: viewId
                                            )
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                            }
                            
                            // Footer
                            if let footerName = sectionConfig["footer"] as? String,
                               let footerData = sectionData.footer {
                                buildFooterView(
                                    footerClassName: footerName,
                                    data: footerData.data,
                                    viewModel: viewModel,
                                    viewId: viewId
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
            }
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    /// Legacy rendering for backward compatibility
    private static func renderLegacyCollection(
        component: DynamicComponent,
        globalColumns: Int,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> AnyView {
        // Legacy collection data extraction
        var collectionData: [[String: Any]] = []
        var cellClassName: String? = nil
        
        if let itemsBinding = component.rawData["items"] as? String,
           itemsBinding.hasPrefix("@{") && itemsBinding.hasSuffix("}") {
            let propertyName = String(itemsBinding.dropFirst(2).dropLast())
            
            if let dataSource = viewModel.data[propertyName] as? CollectionDataSource {
                // For legacy, just get the first section's cells if available
                if let firstSection = dataSource.sections.first,
                   let cells = firstSection.cells {
                    collectionData = cells.data
                    cellClassName = cells.viewName
                }
            }
        }
        
        // Extract header and footer class names for legacy
        let headerClassName: String? = {
            if let headerClasses = component.headerClasses?.value {
                if let classesArray = headerClasses as? [String] {
                    return classesArray.first
                } else if let classesArray = headerClasses as? [[String: Any]] {
                    return classesArray.first?["className"] as? String
                }
            }
            return nil
        }()
        
        let footerClassName: String? = {
            if let footerClasses = component.footerClasses?.value {
                if let classesArray = footerClasses as? [String] {
                    return classesArray.first
                } else if let classesArray = footerClasses as? [[String: Any]] {
                    return classesArray.first?["className"] as? String
                }
            }
            return nil
        }()
        
        // Fallback to items as [String] for backward compatibility
        let items = component.items ?? []
        let isHorizontal = component.horizontalScroll ?? false
        
        if globalColumns == 1 && !isHorizontal {
            // Single column - use List
            return AnyView(
                List {
                    // CollectionDataSource-driven content
                    if !collectionData.isEmpty {
                        ForEach(Array(collectionData.enumerated()), id: \.offset) { index, data in
                            if let className = cellClassName {
                                buildCellView(
                                    cellClassName: className,
                                    data: data,
                                    component: component,
                                    viewModel: viewModel,
                                    viewId: viewId
                                )
                            }
                        }
                    }
                    // Items-driven content (backward compatibility)
                    else if !items.isEmpty {
                        ForEach(0..<items.count, id: \.self) { index in
                            Text(items[index])
                                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                                .font(DynamicHelpers.fontFromComponent(component))
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
            // Grid layout
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: component.lineSpacing ?? 10), count: globalColumns)
            
            return AnyView(
                ScrollView {
                    VStack(spacing: 10) {
                        // Header
                        if let headerClassName = headerClassName {
                            buildHeaderView(
                                headerClassName: headerClassName,
                                data: [:],
                                viewModel: viewModel,
                                viewId: viewId
                            )
                        }
                        
                        LazyVGrid(columns: gridColumns, spacing: component.columnSpacing ?? component.spacing ?? 10) {
                            // CollectionDataSource-driven content
                            if !collectionData.isEmpty {
                                ForEach(Array(collectionData.enumerated()), id: \.offset) { index, data in
                                    if let className = cellClassName {
                                        buildCellView(
                                            cellClassName: className,
                                            data: data,
                                            component: component,
                                            viewModel: viewModel,
                                            viewId: viewId
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
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
                        
                        // Footer
                        if let footerClassName = footerClassName {
                            buildFooterView(
                                footerClassName: footerClassName,
                                data: [:],
                                viewModel: viewModel,
                                viewId: viewId
                            )
                        }
                    }
                    .padding(getContentInsets(from: component))
                }
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
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
        cellClassName: String,
        data: [String: Any],
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        // Convert cell class name to JSON file name (e.g., "ImageCell" -> "image_cell")
        let jsonFileName = cellClassName
            .replacingOccurrences(of: "Cell", with: "_cell")
            .replacingOccurrences(of: "View", with: "_view")
            .camelCaseToSnakeCase()
        
        // Create a child viewModel with the cell data
        let cellViewModel = DynamicViewModel(jsonName: jsonFileName)
        
        // Merge the cell data into the viewModel's data
        for (key, value) in data {
            cellViewModel.data[key] = value
        }
        
        // Load and render the cell view
        DynamicView(
            jsonName: jsonFileName,
            viewId: cellClassName,
            data: data
        )
        .environmentObject(cellViewModel)
    }
    
    /// Build header view for collection
    @ViewBuilder
    private static func buildHeaderView(
        headerClassName: String,
        data: [String: Any],
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        // Convert header class name to JSON file name
        let jsonFileName = headerClassName
            .replacingOccurrences(of: "Header", with: "_header")
            .replacingOccurrences(of: "View", with: "_view")
            .camelCaseToSnakeCase()
        
        let headerViewModel = DynamicViewModel(jsonName: jsonFileName)
        
        // Merge the header data into the viewModel's data
        for (key, value) in data {
            headerViewModel.data[key] = value
        }
        
        // Load and render the header view
        DynamicView(
            jsonName: jsonFileName,
            viewId: headerClassName,
            data: data
        )
        .environmentObject(headerViewModel)
    }
    
    /// Build footer view for collection
    @ViewBuilder
    private static func buildFooterView(
        footerClassName: String,
        data: [String: Any],
        viewModel: DynamicViewModel,
        viewId: String?
    ) -> some View {
        // Convert footer class name to JSON file name
        let jsonFileName = footerClassName
            .replacingOccurrences(of: "Footer", with: "_footer")
            .replacingOccurrences(of: "View", with: "_view")
            .camelCaseToSnakeCase()
        
        let footerViewModel = DynamicViewModel(jsonName: jsonFileName)
        
        // Merge the footer data into the viewModel's data
        for (key, value) in data {
            footerViewModel.data[key] = value
        }
        
        // Load and render the footer view
        DynamicView(
            jsonName: jsonFileName,
            viewId: footerClassName,
            data: data
        )
        .environmentObject(footerViewModel)
    }
}

#endif // DEBUG