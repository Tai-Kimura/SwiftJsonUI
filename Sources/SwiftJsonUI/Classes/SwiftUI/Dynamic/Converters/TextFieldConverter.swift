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
            .padding(getMargins())  // Apply margins as outer padding
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
    
    /// Get padding value from component
    private static func getTextFieldPadding(_ component: DynamicComponent) -> EdgeInsets {
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
        
        // Use individual padding properties or fallback to padding value
        let top = component.paddingTop ?? component.topPadding ?? paddingValue ?? 0
        let leading = component.paddingLeft ?? component.leftPadding ?? paddingValue ?? 0
        let bottom = component.paddingBottom ?? component.bottomPadding ?? paddingValue ?? 0
        let trailing = component.paddingRight ?? component.rightPadding ?? paddingValue ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    /// Get background color
    private static func getBackground(_ component: DynamicComponent) -> Color {
        return DynamicHelpers.colorFromHex(component.background) ?? .clear
    }
    
    /// Get border overlay
    @ViewBuilder
    private static func getBorder(_ component: DynamicComponent) -> some View {
        if let borderWidth = component.borderWidth,
           borderWidth > 0 {
            let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
            RoundedRectangle(cornerRadius: component.cornerRadius ?? 0)
                .stroke(borderColor, lineWidth: borderWidth)
        }
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
                    .padding(getTextFieldPadding(component))  // Internal padding
                    .background(getBackground(component))
                    .cornerRadius(component.cornerRadius ?? 0)
                    .overlay(getBorder(component))  // Border after cornerRadius, before margins
                    .modifier(TextFieldModifiers(component: component, viewModel: viewModel))  // Margins only
            )
        } else {
            // Use static text if no binding
            let text = component.text ?? ""
            
            return AnyView(
                TextField(placeholder, text: .constant(text))
                    .font(DynamicHelpers.fontFromComponent(component))
                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                    .padding(getTextFieldPadding(component))  // Internal padding
                    .background(getBackground(component))
                    .cornerRadius(component.cornerRadius ?? 0)
                    .overlay(getBorder(component))  // Border after cornerRadius, before margins
                    .modifier(TextFieldModifiers(component: component, viewModel: viewModel))  // Margins only
            )
        }
    }
}