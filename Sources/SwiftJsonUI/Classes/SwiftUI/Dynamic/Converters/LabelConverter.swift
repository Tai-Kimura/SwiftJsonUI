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
    let parentOrientation: String? = nil  // To be passed when needed
    
    func body(content: Content) -> some View {
        let modifiedContent = content
        
        // Apply frame only if width or height are explicitly set (not nil and not wrapContent)
        let shouldApplyFrame = shouldApplyFrameModifier()
        let finalContent = shouldApplyFrame ? 
            AnyView(modifiedContent.frame(
                width: getWidth(),
                height: getHeight(),
                alignment: getFrameAlignment()
            )) : AnyView(modifiedContent)
        
        return finalContent
            .padding(getPadding())
            .background(getBackground())
            .cornerRadius(component.cornerRadius ?? 0)
            .overlay(getBorder())
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    private func shouldApplyFrameModifier() -> Bool {
        // Only apply frame if width or height is explicitly set (not nil/wrapContent)
        // or if weight is specified (which requires infinity)
        let hasExplicitWidth = component.width != nil || hasWeightForWidth()
        let hasExplicitHeight = component.height != nil || hasWeightForHeight()
        return hasExplicitWidth || hasExplicitHeight
    }
    
    private func getWidth() -> CGFloat? {
        // If weight is specified and affects width, use infinity
        if hasWeightForWidth() {
            return .infinity
        }
        // Return explicit width if set and valid, nil for wrapContent or invalid values
        if let width = component.width {
            // Ensure width is positive and finite
            if width > 0 && width.isFinite {
                return width
            } else if width == .infinity {
                return width
            }
            // Return nil for 0 or negative values to avoid invalid frame
            return nil
        }
        return nil
    }
    
    private func getHeight() -> CGFloat? {
        // If weight is specified and affects height, use infinity
        if hasWeightForHeight() {
            return .infinity
        }
        // Return explicit height if set and valid, nil for wrapContent or invalid values
        if let height = component.height {
            // Ensure height is positive and finite
            if height > 0 && height.isFinite {
                return height
            } else if height == .infinity {
                return height
            }
            // Return nil for 0 or negative values to avoid invalid frame
            return nil
        }
        return nil
    }
    
    private func hasWeightForWidth() -> Bool {
        // Weight affects width in horizontal layouts or when widthWeight is specified
        let hasWeight = (component.weight ?? 0) > 0 || (component.widthWeight ?? 0) > 0
        // Note: We don't have parent orientation here, so we check if width is 0 which indicates weight usage
        return hasWeight && component.width == 0
    }
    
    private func hasWeightForHeight() -> Bool {
        // Weight affects height in vertical layouts or when heightWeight is specified
        let hasWeight = (component.weight ?? 0) > 0 || (component.heightWeight ?? 0) > 0
        // Note: We don't have parent orientation here, so we check if height is 0 which indicates weight usage
        return hasWeight && component.height == 0
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

