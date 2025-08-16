//
//  TextConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Text view
//

import SwiftUI

// Dynamic mode text/label converter
// Generated code equivalent: sjui_tools/lib/swiftui/views/label_converter.rb
public struct TextConverter {
    
    /// Convert DynamicComponent to SwiftUI Text view
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = viewModel.processText(component.text) ?? ""
        
        return AnyView(
            Text(text)
                .font(DynamicHelpers.fontFromComponent(component))
                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                .multilineTextAlignment(DynamicHelpers.getTextAlignment(from: component))
                .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
                .background(DynamicHelpers.colorFromHex(component.background) ?? .clear)
                .cornerRadius(component.cornerRadius ?? 0)
                .modifier(TextModifiers(component: component, viewModel: viewModel))  // External margins only
        )
    }
}

// MARK: - Text Modifiers (margins only, no padding/background/cornerRadius)
// Generated code equivalent: sjui_tools/lib/swiftui/views/label_converter.rb:247-248 (apply_margins)
struct TextModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            // Apply margins only (padding/background/cornerRadius are handled by TextConverter)
            .padding(DynamicHelpers.getMargins(from: component))
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1)
    }
}