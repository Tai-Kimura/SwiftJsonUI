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
        
        guard let dataSource = dataSource, !sections.isEmpty else {
            // Return empty view if no data source or sections
            return AnyView(
                Text("No collection data")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
        
        // Section-based rendering
        let showsIndicators = component.showsVerticalScrollIndicator ?? true
        return AnyView(
            ScrollView(.vertical, showsIndicators: showsIndicators) {
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
        
        // Load and render the cell view
        DynamicView(
            jsonName: jsonFileName,
            viewId: cellClassName,
            data: data
        )
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
        
        // Load and render the header view
        DynamicView(
            jsonName: jsonFileName,
            viewId: headerClassName,
            data: data
        )
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
        
        // Load and render the footer view
        DynamicView(
            jsonName: jsonFileName,
            viewId: footerClassName,
            data: data
        )
    }
}

#endif // DEBUG