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
        viewModel: DynamicViewModel,
        parentOrientation: String? = nil
    ) -> AnyView {
        let text = viewModel.processText(component.text) ?? ""
        let textColor = DynamicHelpers.colorFromHex(component.fontColor) ?? .primary
        let alignment = DynamicHelpers.getTextAlignment(from: component)
        
        // Create text view with optional font
        let textView: AnyView
        if let font = DynamicHelpers.fontFromComponent(component) {
            textView = AnyView(
                Text(text)
                    .font(font)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(alignment)
            )
        } else {
            textView = AnyView(
                Text(text)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(alignment)
            )
        }
        
        // Apply frame for weight FIRST (before padding and background)
        // This ensures the background fills the entire weighted area
        var result = textView
        
        // If weight is specified, apply appropriate frame modifier
        if let weight = component.weight, weight > 0 {
            // Weight only affects the main axis of the parent container
            if parentOrientation == "horizontal" {
                // In horizontal stack, weight affects width
                if component.width == nil || component.width == 0 {
                    result = AnyView(result.frame(maxWidth: .infinity))
                }
            } else if parentOrientation == "vertical" {
                // In vertical stack, weight affects height
                if component.height == nil || component.height == 0 {
                    result = AnyView(result.frame(maxHeight: .infinity))
                }
            } else {
                // Parent orientation unknown, use heuristic
                if component.width == nil || component.width == 0 {
                    result = AnyView(result.frame(maxWidth: .infinity))
                }
            }
        }
        
        // Apply explicit width/height if set
        if let width = component.width, width > 0 && width != .infinity {
            result = AnyView(result.frame(width: width))
        } else if component.width == .infinity {
            result = AnyView(result.frame(maxWidth: .infinity))
        }
        
        if let height = component.height, height > 0 && height != .infinity {
            result = AnyView(result.frame(height: height))
        } else if component.height == .infinity {
            result = AnyView(result.frame(maxHeight: .infinity))
        }
        
        // Apply edgeInset as additional padding for text
        if let edgeInset = component.edgeInset {
            result = AnyView(result.padding(edgeInset))
        }
        
        return AnyView(
            result
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