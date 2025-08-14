//
//  TextViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextViewWithPlaceholder
//

import SwiftUI

public struct TextViewConverter {
    
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
    
    /// Convert DynamicComponent to SwiftUI TextViewWithPlaceholder
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let insetArray = component.containerInset ?? [8, 5, 8, 5]
        let containerInset = EdgeInsets(
            top: insetArray.count > 0 ? insetArray[0] : 8,
            leading: insetArray.count > 1 ? insetArray[1] : 5,
            bottom: insetArray.count > 2 ? insetArray[2] : 8,
            trailing: insetArray.count > 3 ? insetArray[3] : 5
        )
        
        // Check if text has @{} binding syntax
        var textBinding: SwiftUI.Binding<String>
        if let propertyName = extractPropertyName(from: component.text) {
            // Create binding that updates the data dictionary
            textBinding = SwiftUI.Binding<String>(
                get: { 
                    viewModel.data[propertyName] as? String ?? ""
                },
                set: { newValue in
                    viewModel.data[propertyName] = newValue
                    viewModel.objectWillChange.send()
                }
            )
        } else {
            // Use static text if no binding
            let text = component.text ?? ""
            textBinding = .constant(text)
        }
        
        return AnyView(
            TextViewWithPlaceholder(
                text: textBinding,
                hint: component.hint ?? component.placeholder,
                hintColor: DynamicHelpers.colorFromHex(component.hintColor) ?? .gray,
                hintFont: component.hintFont,
                hideOnFocused: component.hideOnFocused ?? true,
                fontSize: component.fontSize ?? 16,
                fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                fontName: component.font,
                backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? .clear,
                cornerRadius: component.cornerRadius ?? 0,
                containerInset: containerInset,
                flexible: component.flexible ?? false,
                minHeight: component.minHeight,
                maxHeight: component.maxHeight
            )
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}