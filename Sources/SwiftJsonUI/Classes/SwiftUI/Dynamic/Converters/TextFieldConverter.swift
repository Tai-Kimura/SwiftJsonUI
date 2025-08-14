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
        
        return AnyView(
            TextField(placeholder, text: .constant(text))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(DynamicHelpers.fontFromComponent(component))
                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}