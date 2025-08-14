//
//  TextFieldConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextField
//

import SwiftUI

public struct TextFieldConverter {
    
    /// Convert DynamicComponent to SwiftUI TextField
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let placeholder = component.hint ?? component.placeholder ?? ""
        let text = component.text ?? ""
        
        // Create binding from @{property} expression
        let binding: Binding<String>
        if text.hasPrefix("@{") && text.hasSuffix("}") {
            let propertyName = String(text.dropFirst(2).dropLast(1))
            binding = Binding<String>(
                get: { viewModel.getDataValue(for: propertyName) as? String ?? "" },
                set: { viewModel.setDataValue(for: propertyName, value: $0) }
            )
        } else {
            binding = .constant(text)
        }
        
        return AnyView(
            TextField(placeholder, text: binding)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(DynamicHelpers.fontFromComponent(component))
                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}