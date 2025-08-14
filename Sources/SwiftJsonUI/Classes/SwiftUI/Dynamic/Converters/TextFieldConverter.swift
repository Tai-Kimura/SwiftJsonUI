//
//  TextFieldConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextField
//

import SwiftUI

public struct TextFieldConverter {
    
    /// Extract property name from @{propertyName} syntax
    private static func extractPropertyName(from value: String?) -> String? {
        guard let value = value,
              value.hasPrefix("@{") && value.hasSuffix("}") else {
            return nil
        }
        let startIndex = value.index(value.startIndex, offsetBy: 2)
        let endIndex = value.index(value.endIndex, offsetBy: -1)
        return String(value[startIndex..<endIndex])
    }
    
    /// Convert DynamicComponent to SwiftUI TextField
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let placeholder = component.hint ?? component.placeholder ?? ""
        
        // Check if text has @{} binding syntax
        if let propertyName = extractPropertyName(from: component.text) {
            // Get value from data dictionary
            let value = viewModel.data[propertyName] as? String ?? ""
            
            // Create binding that updates the data dictionary
            let binding = Binding<String>(
                get: { value },
                set: { newValue in
                    viewModel.data[propertyName] = newValue
                    viewModel.objectWillChange.send()
                }
            )
            
            return AnyView(
                TextField(placeholder, text: binding)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(DynamicHelpers.fontFromComponent(component))
                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        } else {
            // Use static text if no binding
            let text = component.text ?? ""
            
            return AnyView(
                TextField(placeholder, text: .constant(text))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(DynamicHelpers.fontFromComponent(component))
                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
    }
}