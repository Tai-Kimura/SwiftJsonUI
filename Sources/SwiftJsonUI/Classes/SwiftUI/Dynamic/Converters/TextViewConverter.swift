//
//  TextViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextViewWithPlaceholder
//

import SwiftUI

// MARK: - TextView-specific modifiers
// Corresponding to Generated code: text_view_converter.rb
struct TextViewModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            // TextViewWithPlaceholder handles padding internally via containerInset
            // Only apply border and margins here
            .overlay(getBorder())  // Border after component's internal cornerRadius
            .padding(getMargins())  // Apply margins as outer padding
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    /// Get border overlay
    @ViewBuilder
    private func getBorder() -> some View {
        if let borderWidth = component.borderWidth,
           borderWidth > 0 {
            let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
            RoundedRectangle(cornerRadius: component.cornerRadius ?? 0)
                .stroke(borderColor, lineWidth: borderWidth)
        }
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
        // Handle containerInset as single value or array
        let insetArray: [CGFloat]
        if let singleInset = component.containerInset?.first, component.containerInset?.count == 1 {
            // If single value, apply to all edges
            insetArray = [singleInset, singleInset, singleInset, singleInset]
        } else {
            insetArray = component.containerInset ?? [8, 5, 8, 5]
        }
        
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
            .modifier(TextViewModifiers(component: component, viewModel: viewModel))  // Border and margins only
        )
    }
}