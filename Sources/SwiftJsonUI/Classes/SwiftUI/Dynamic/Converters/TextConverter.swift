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
        let text = viewModel.processText(component.text) ?? ""
        
        return AnyView(
            Text(text)
                .font(DynamicHelpers.fontFromComponent(component))
                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                .multilineTextAlignment(DynamicHelpers.textAlignmentFromString(component.textAlign))
                .padding(getTextPadding(component))  // Internal padding
                .background(DynamicHelpers.colorFromHex(component.background) ?? .clear)
                .cornerRadius(component.cornerRadius ?? 0)
                .modifier(TextModifiers(component: component, viewModel: viewModel))  // External margins only
        )
    }
    
    private static func getTextPadding(_ component: DynamicComponent) -> EdgeInsets {
        // Get padding value from AnyCodable
        var paddingValue: CGFloat? = nil
        if let padding = component.padding {
            if let intValue = padding.value as? Int {
                paddingValue = CGFloat(intValue)
            } else if let doubleValue = padding.value as? Double {
                paddingValue = CGFloat(doubleValue)
            } else if let floatValue = padding.value as? CGFloat {
                paddingValue = floatValue
            }
        }
        
        // If padding is specified, use it for all sides
        if let padding = paddingValue {
            return EdgeInsets(
                top: component.paddingTop ?? component.topPadding ?? padding,
                leading: component.paddingLeft ?? component.leftPadding ?? padding,
                bottom: component.paddingBottom ?? component.bottomPadding ?? padding,
                trailing: component.paddingRight ?? component.rightPadding ?? padding
            )
        }
        
        // Use individual padding properties or default to 0
        return EdgeInsets(
            top: component.paddingTop ?? component.topPadding ?? 0,
            leading: component.paddingLeft ?? component.leftPadding ?? 0,
            bottom: component.paddingBottom ?? component.bottomPadding ?? 0,
            trailing: component.paddingRight ?? component.rightPadding ?? 0
        )
    }
}

// MARK: - Text Modifiers (margins only, no padding/background/cornerRadius)
struct TextModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            // Apply margins only (padding/background/cornerRadius are handled by TextConverter)
            .padding(getMargins())
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    private func getMargins() -> EdgeInsets {
        // Use margin properties for outer spacing
        let top = component.topMargin ?? 0
        let leading = component.leftMargin ?? 0
        let bottom = component.bottomMargin ?? 0
        let trailing = component.rightMargin ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    private func getOpacity() -> Double {
        if let opacity = component.opacity {
            return Double(opacity)
        }
        if let alpha = component.alpha {
            return Double(alpha)
        }
        return 1.0
    }
    
    private func isHidden() -> Bool {
        return component.hidden == true || component.visibility == "gone"
    }
}