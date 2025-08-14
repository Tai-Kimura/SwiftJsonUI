//
//  TableConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI List (Table)
//

import SwiftUI

public struct TableConverter {
    
    /// Convert DynamicComponent to SwiftUI List (Table)
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        let data = component.data ?? []
        let items = component.items ?? []
        
        return AnyView(
            List {
                // Data-driven content
                if !data.isEmpty {
                    ForEach(0..<data.count, id: \.self) { index in
                        TableRow(dataItem: data[index], component: component, viewModel: viewModel)
                    }
                }
                // Items-driven content
                else if !items.isEmpty {
                    ForEach(0..<items.count, id: \.self) { index in
                        HStack {
                            Text(items[index])
                                .font(DynamicHelpers.fontFromComponent(component))
                                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                            Spacer()
                        }
                    }
                }
                // Child components
                else if let children = component.child {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, viewModel: viewModel, viewId: viewId)
                    }
                }
                // Default demo content
                else {
                    ForEach(0..<10) { index in
                        Text("Row \(index)")
                    }
                }
            }
            .listStyle(getListStyle(component))
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func getListStyle(_ component: DynamicComponent) -> some ListStyle {
        // Check for list style in component properties
        // Default to PlainListStyle
        PlainListStyle()
    }
}

// MARK: - Table Row
struct TableRow: View {
    let dataItem: AnyCodable
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        HStack {
            // Display key-value pairs from data
            VStack(alignment: .leading, spacing: 4) {
                if let data = dataItem.value as? [String: Any] {
                    ForEach(Array(data.keys.sorted()), id: \.self) { key in
                        if let value = data[key] {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(String(describing: value))
                                    .font(.body)
                            }
                        }
                    }
                } else {
                    // If not a dictionary, just show the value
                    Text(String(describing: dataItem.value))
                        .font(.body)
                }
            }
        }
        .padding(.vertical, 8)
    }
}