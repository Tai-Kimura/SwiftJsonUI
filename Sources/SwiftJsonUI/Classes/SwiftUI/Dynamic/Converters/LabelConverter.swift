//
//  LabelConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Text view
//

import SwiftUI

public struct LabelConverter {
    
    /// Convert DynamicComponent to SwiftUI Text view
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = viewModel.processText(component.text) ?? ""
        
        var textView = Text(text)
            .font(DynamicHelpers.fontFromComponent(component))
            .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
        
        // Apply text alignment
        if let textAlign = component.textAlign {
            textView = applyTextAlignment(textView, alignment: textAlign)
        }
        
        // Apply common modifiers
        return AnyView(
            textView
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    
    private static func applyTextAlignment(_ text: Text, alignment: String) -> Text {
        // Text alignment is handled by the frame modifier in CommonModifiers
        return text
    }
}

