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
            .padding(getPadding())  // Apply internal padding first
            .background(getBackground())
            .cornerRadius(component.cornerRadius ?? 0)
            .overlay(getBorder())
            .padding(getMargins())  // Apply margins as outer padding
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    private func shouldApplyFrameModifier() -> Bool {
        // ScrollView should not have frame modifier with infinity values
        if component.type?.lowercased() == "scrollview" || component.type?.lowercased() == "scroll" {
            return false
        }
        
        // Only apply frame if width or height is explicitly set (not nil/wrapContent)
        // or if weight is specified (which requires infinity)
        let hasExplicitWidth = component.width != nil || hasWeightForWidth()
        let hasExplicitHeight = component.height != nil || hasWeightForHeight()
        return hasExplicitWidth || hasExplicitHeight
    }
    
    private func getWidth() -> CGFloat? {
        // If weight is specified and affects width, use infinity
        if hasWeightForWidth() {
            let _ = print("🏋️ Width with weight: component id=\(component.id ?? "no-id"), weight=\(component.weight ?? 0), width=\(component.width ?? -1)")
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
        // Check for paddings array first
        if let paddingsValue = component.paddings ?? component.padding {
            if let paddingArray = paddingsValue.value as? [Any] {
                // Handle array format [top, right, bottom, left] or [vertical, horizontal] or [all]
                switch paddingArray.count {
                case 1:
                    if let value = paddingArray[0] as? Int {
                        let padding = CGFloat(value)
                        return EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
                    } else if let value = paddingArray[0] as? Double {
                        let padding = CGFloat(value)
                        return EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
                    } else if let value = paddingArray[0] as? CGFloat {
                        return EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
                    }
                case 2:
                    // Vertical, Horizontal
                    var vPadding: CGFloat = 0
                    var hPadding: CGFloat = 0
                    
                    if let vValue = paddingArray[0] as? Int, let hValue = paddingArray[1] as? Int {
                        vPadding = CGFloat(vValue)
                        hPadding = CGFloat(hValue)
                    } else if let vValue = paddingArray[0] as? Double, let hValue = paddingArray[1] as? Double {
                        vPadding = CGFloat(vValue)
                        hPadding = CGFloat(hValue)
                    } else if let vValue = paddingArray[0] as? CGFloat, let hValue = paddingArray[1] as? CGFloat {
                        vPadding = vValue
                        hPadding = hValue
                    }
                    
                    return EdgeInsets(top: vPadding, leading: hPadding, bottom: vPadding, trailing: hPadding)
                case 4:
                    // Top, Right, Bottom, Left
                    var top: CGFloat = 0
                    var right: CGFloat = 0
                    var bottom: CGFloat = 0
                    var left: CGFloat = 0
                    
                    if let t = paddingArray[0] as? Int,
                       let r = paddingArray[1] as? Int,
                       let b = paddingArray[2] as? Int,
                       let l = paddingArray[3] as? Int {
                        top = CGFloat(t)
                        right = CGFloat(r)
                        bottom = CGFloat(b)
                        left = CGFloat(l)
                    } else if let t = paddingArray[0] as? Double,
                              let r = paddingArray[1] as? Double,
                              let b = paddingArray[2] as? Double,
                              let l = paddingArray[3] as? Double {
                        top = CGFloat(t)
                        right = CGFloat(r)
                        bottom = CGFloat(b)
                        left = CGFloat(l)
                    } else if let t = paddingArray[0] as? CGFloat,
                              let r = paddingArray[1] as? CGFloat,
                              let b = paddingArray[2] as? CGFloat,
                              let l = paddingArray[3] as? CGFloat {
                        top = t
                        right = r
                        bottom = b
                        left = l
                    }
                    
                    return EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
                default:
                    break
                }
            } else if let intValue = paddingsValue.value as? Int {
                let padding = CGFloat(intValue)
                return EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
            } else if let doubleValue = paddingsValue.value as? Double {
                let padding = CGFloat(doubleValue)
                return EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
            } else if let floatValue = paddingsValue.value as? CGFloat {
                return EdgeInsets(top: floatValue, leading: floatValue, bottom: floatValue, trailing: floatValue)
            }
        }
        
        // Fallback to individual padding properties
        let top = component.paddingTop ?? component.topPadding ?? 0
        let leading = component.paddingLeft ?? component.leftPadding ?? 0
        let bottom = component.paddingBottom ?? component.bottomPadding ?? 0
        let trailing = component.paddingRight ?? component.rightPadding ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
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