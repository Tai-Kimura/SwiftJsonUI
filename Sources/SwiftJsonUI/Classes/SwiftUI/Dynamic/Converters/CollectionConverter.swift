//
//  CollectionConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI LazyVGrid or List
//

import SwiftUI

public struct CollectionConverter {
    
    /// Convert DynamicComponent to SwiftUI Collection (List or LazyVGrid)
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        let columns = component.columns ?? 2
        let items = component.items ?? []
        let isHorizontal = component.horizontalScroll ?? false
        
        if columns == 1 && !isHorizontal {
            // Single column - use List
            return AnyView(
                List {
                    // Items-driven content
                    if !items.isEmpty {
                        ForEach(0..<items.count, id: \.self) { index in
                            Text(items[index])
                                .font(DynamicHelpers.fontFromComponent(component))
                                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                        }
                    }
                    // Child components
                    else if let children = component.child {
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
                            // Items-driven content
                            if !items.isEmpty {
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
                            else if let children = component.child {
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
                        // Items-driven content
                        if !items.isEmpty {
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
                        else if let children = component.child {
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
}

