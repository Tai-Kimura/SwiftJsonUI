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
        let data = component.data ?? []
        let items = component.items ?? []
        
        if columns == 1 {
            // Single column - use List
            return AnyView(
                List {
                    // Data-driven content
                    if !data.isEmpty {
                        ForEach(0..<data.count, id: \.self) { index in
                            CollectionCell(
                                data: data[index],
                                component: component,
                                viewModel: viewModel
                            )
                        }
                    }
                    // Items-driven content
                    else if !items.isEmpty {
                        ForEach(0..<items.count, id: \.self) { index in
                            Text(items[index])
                                .font(DynamicHelpers.fontFromComponent(component))
                                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                        }
                    }
                    // Child components
                    else if let children = component.child {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            ChildView(component: child, viewModel: viewModel, viewId: viewId)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        } else {
            // Multiple columns - use LazyVGrid
            let gridColumns = Array(repeating: GridItem(.flexible()), count: columns)
            
            return AnyView(
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: component.spacing ?? 10) {
                        // Data-driven content
                        if !data.isEmpty {
                            ForEach(0..<data.count, id: \.self) { index in
                                CollectionCell(
                                    data: data[index],
                                    component: component,
                                    viewModel: viewModel
                                )
                            }
                        }
                        // Items-driven content
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
                        else if let children = component.child {
                            ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                                ChildView(component: child, viewModel: viewModel, viewId: viewId)
                            }
                        }
                    }
                    .padding()
                }
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
    }
}

// MARK: - Collection Cell
struct CollectionCell: View {
    let data: [String: String]
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(data.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(data[key] ?? "")
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

