//
//  CommonModifiers.swift
//  SwiftJsonUI
//
//  Common modifiers for all dynamic components
//

import SwiftUI

// MARK: - Common Modifiers
public struct CommonModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    let parentOrientation: String? = nil  // To be passed when needed
    
    public func body(content: Content) -> some View {
        let modifiedContent = content
        
        // Apply frame only if width or height are explicitly set (not nil and not wrapContent)
        let shouldApplyFrame = shouldApplyFrameModifier()
        
        if shouldApplyFrame {
            let width = getWidth()
            let height = getHeight()
            let _ = print("🖼️ Frame: id=\(component.id ?? "no-id"), width=\(width?.description ?? "nil"), height=\(height?.description ?? "nil")")
            
            // Check for invalid dimensions
            if let w = width, (w < 0 || !w.isFinite) && w != .infinity {
                print("⚠️ Invalid width detected: \(w) for component id=\(component.id ?? "no-id")")
            }
            if let h = height, (h < 0 || !h.isFinite) && h != .infinity {
                print("⚠️ Invalid height detected: \(h) for component id=\(component.id ?? "no-id")")
            }
        }
        
        // Apply frame dimensions separately
        var finalContent = AnyView(modifiedContent)
        
        if shouldApplyFrame {
            let width = getWidth()
            let height = getHeight()
            let alignment = getFrameAlignment()
            
            // Apply width if it has a value
            if let w = width {
                finalContent = AnyView(finalContent.frame(width: w, alignment: alignment))
            }
            
            // Apply height if it has a value
            if let h = height {
                finalContent = AnyView(finalContent.frame(height: h, alignment: alignment))
            }
        }
        
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