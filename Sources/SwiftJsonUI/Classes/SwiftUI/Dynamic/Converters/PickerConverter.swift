//
//  PickerConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Picker
//

import SwiftUI

public struct PickerConverter {
    
    /// Convert DynamicComponent to SwiftUI Picker
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let items = component.items ?? []
        let selectedItem = component.selectedItem ?? items.first ?? ""
        let label = component.text ?? "Select"
        
        return AnyView(
            Picker(label, selection: .constant(selectedItem)) {
                ForEach(items, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(DynamicHelpers.fontFromComponent(component))
            .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}