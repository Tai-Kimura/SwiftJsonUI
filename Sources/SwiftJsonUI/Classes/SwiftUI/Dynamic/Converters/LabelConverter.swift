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
        let text = component.text ?? ""
        
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

// MARK: - Common Modifiers
struct CommonModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            .frame(
                width: getWidth(),
                height: getHeight(),
                alignment: getFrameAlignment()
            )
            .padding(getPadding())
            .background(getBackground())
            .cornerRadius(component.cornerRadius ?? 0)
            .overlay(getBorder())
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    private func getWidth() -> CGFloat? {
        return component.width
    }
    
    private func getHeight() -> CGFloat? {
        return component.height
    }
    
    private func getFrameAlignment() -> Alignment {
        // Use text alignment or component alignment
        if let textAlign = component.textAlign {
            switch textAlign.lowercased() {
            case "center":
                return .center
            case "left", "start":
                return .leading
            case "right", "end":
                return .trailing
            default:
                return component.alignment ?? .topLeading
            }
        }
        return component.alignment ?? .topLeading
    }
    
    private func getPadding() -> EdgeInsets {
        let top = component.paddingTop ?? component.topPadding ?? component.padding?.value as? CGFloat ?? 0
        let leading = component.paddingLeft ?? component.leftPadding ?? component.padding?.value as? CGFloat ?? 0
        let bottom = component.paddingBottom ?? component.bottomPadding ?? component.padding?.value as? CGFloat ?? 0
        let trailing = component.paddingRight ?? component.rightPadding ?? component.padding?.value as? CGFloat ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    private func getBackground() -> Color {
        return DynamicHelpers.colorFromHex(component.background) ?? .clear
    }
    
    private func getBorder() -> some View {
        Group {
            if let borderWidth = component.borderWidth,
               borderWidth > 0 {
                let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
                RoundedRectangle(cornerRadius: component.cornerRadius ?? 0)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
        }
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

