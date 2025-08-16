//
//  TextFieldConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextField
//

import SwiftUI

// MARK: - TextField-specific modifiers (margins only)
// Corresponding to Generated code: textfield_converter.rb
struct TextFieldModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            .padding(DynamicHelpers.getMargins(from: component))  // Apply margins as outer padding
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1)
    }
}

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
            let binding = SwiftUI.Binding<String>(
                get: { value },
                set: { newValue in
                    viewModel.data[propertyName] = newValue
                    viewModel.objectWillChange.send()
                }
            )
            
            return AnyView(
                TextField(placeholder, text: binding)
                    .font(DynamicHelpers.fontFromComponent(component))
                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                    .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
                    .background(DynamicHelpers.getBackground(from: component))
                    .cornerRadius(component.cornerRadius ?? 0)
                    .overlay(
                        Group {
                            if let borderWidth = component.borderWidth,
                               borderWidth > 0 {
                                let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
                                RoundedRectangle(cornerRadius: component.cornerRadius ?? 0)
                                    .stroke(borderColor, lineWidth: borderWidth)
                            }
                        }
                    )  // Border after cornerRadius, before margins
                    .modifier(TextFieldModifiers(component: component, viewModel: viewModel))  // Margins only
            )
        } else {
            // Use static text if no binding
            let text = component.text ?? ""
            
            return AnyView(
                TextField(placeholder, text: .constant(text))
                    .font(DynamicHelpers.fontFromComponent(component))
                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                    .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
                    .background(DynamicHelpers.getBackground(from: component))
                    .cornerRadius(component.cornerRadius ?? 0)
                    .overlay(
                        Group {
                            if let borderWidth = component.borderWidth,
                               borderWidth > 0 {
                                let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
                                RoundedRectangle(cornerRadius: component.cornerRadius ?? 0)
                                    .stroke(borderColor, lineWidth: borderWidth)
                            }
                        }
                    )  // Border after cornerRadius, before margins
                    .modifier(TextFieldModifiers(component: component, viewModel: viewModel))  // Margins only
            )
        }
    }
}