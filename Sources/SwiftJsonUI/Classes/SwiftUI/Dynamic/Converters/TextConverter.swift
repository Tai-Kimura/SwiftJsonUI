//
//  TextConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Text view
//

import SwiftUI

public struct TextConverter {
    
    /// Convert DynamicComponent to SwiftUI Text view
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = component.text ?? ""
        
        return AnyView(
            Text(text)
                .font(DynamicHelpers.fontFromComponent(component))
                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                .multilineTextAlignment(DynamicHelpers.textAlignmentFromString(component.textAlign))
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}