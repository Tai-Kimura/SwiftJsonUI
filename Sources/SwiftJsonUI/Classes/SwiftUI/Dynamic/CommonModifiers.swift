//
//  CommonModifiers.swift
//  SwiftJsonUI
//
//  Common modifiers for all dynamic components
//

import SwiftUI

// MARK: - Modifier Overrides
/// Structure to customize or override specific modifiers in CommonModifiers
public struct ModifierOverrides {
    // Skip flags
    var skipPadding: Bool = false
    var skipCornerRadius: Bool = false
    var skipBorder: Bool = false
    var skipMargins: Bool = false
    
    // Custom values
    var customPadding: EdgeInsets? = nil
    var customCornerRadius: CGFloat? = nil
    
    // Custom modifier closures
    var customBackground: ((AnyView) -> AnyView)? = nil
    var customOverlay: ((AnyView) -> AnyView)? = nil
    var afterBackgroundModifier: ((AnyView) -> AnyView)? = nil
    var finalModifier: ((AnyView) -> AnyView)? = nil
    
    public init(
        skipPadding: Bool = false,
        skipCornerRadius: Bool = false,
        skipBorder: Bool = false,
        skipMargins: Bool = false,
        customPadding: EdgeInsets? = nil,
        customCornerRadius: CGFloat? = nil,
        customBackground: ((AnyView) -> AnyView)? = nil,
        customOverlay: ((AnyView) -> AnyView)? = nil,
        afterBackgroundModifier: ((AnyView) -> AnyView)? = nil,
        finalModifier: ((AnyView) -> AnyView)? = nil
    ) {
        self.skipPadding = skipPadding
        self.skipCornerRadius = skipCornerRadius
        self.skipBorder = skipBorder
        self.skipMargins = skipMargins
        self.customPadding = customPadding
        self.customCornerRadius = customCornerRadius
        self.customBackground = customBackground
        self.customOverlay = customOverlay
        self.afterBackgroundModifier = afterBackgroundModifier
        self.finalModifier = finalModifier
    }
}

// MARK: - Common Modifiers
public struct CommonModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    let parentOrientation: String? = nil  // To be passed when needed
    let customModifiers: ModifierOverrides
    
    public init(component: DynamicComponent, viewModel: DynamicViewModel, customModifiers: ModifierOverrides = ModifierOverrides()) {
        self.component = component
        self.viewModel = viewModel
        self.customModifiers = customModifiers
    }
    
    public func body(content: Content) -> some View {
        // Start with content and apply modifiers in order
        var result = AnyView(content)
        
        // 1. Apply padding (internal spacing) - can be overridden
        if customModifiers.skipPadding {
            // Skip padding if requested
        } else if let customPadding = customModifiers.customPadding {
            result = AnyView(result.padding(customPadding))
        } else {
            let padding = DynamicHelpers.getPadding(from: component)
            print("📐 CommonModifiers padding: id=\(component.id ?? "no-id"), type=\(component.type ?? "unknown"), padding=\(padding)")
            result = AnyView(result.padding(padding))
        }
        
        // 2. Apply frame
        let shouldApplyFrame = shouldApplyFrameModifier()
        if shouldApplyFrame {
            let width = getWidth()
            let height = getHeight()
            let alignment = getFrameAlignment()
            
            let _ = print("🖼️ Frame: id=\(component.id ?? "no-id"), width=\(width?.description ?? "nil"), height=\(height?.description ?? "nil")")
            
            // Apply min/ideal/max constraints if available
            if component.minWidth != nil || component.maxWidth != nil || component.minHeight != nil || component.maxHeight != nil || component.idealWidth != nil || component.idealHeight != nil {
                result = AnyView(result.frame(
                    minWidth: component.minWidth,
                    idealWidth: component.idealWidth,
                    maxWidth: component.maxWidth == .infinity ? .infinity : component.maxWidth,
                    minHeight: component.minHeight,
                    idealHeight: component.idealHeight,
                    maxHeight: component.maxHeight == .infinity ? .infinity : component.maxHeight,
                    alignment: alignment
                ))
            } else {
                // Use maxWidth/maxHeight for infinity, width/height for finite values
                if let w = width {
                    if w == .infinity {
                        result = AnyView(result.frame(maxWidth: .infinity, alignment: alignment))
                    } else {
                        result = AnyView(result.frame(width: w, alignment: alignment))
                    }
                }
                if let h = height {
                    if h == .infinity {
                        result = AnyView(result.frame(maxHeight: .infinity, alignment: alignment))
                    } else {
                        result = AnyView(result.frame(height: h, alignment: alignment))
                    }
                }
            }
        }
        
        // 3. Apply background - can be overridden
        if let customBackground = customModifiers.customBackground {
            result = AnyView(customBackground(result))
        } else {
            result = AnyView(result.background(DynamicHelpers.getBackground(from: component)))
        }
        
        // 4. Apply corner radius and clipping - can be overridden
        if customModifiers.skipCornerRadius {
            // Skip corner radius if requested
        } else if let customCornerRadius = customModifiers.customCornerRadius {
            result = AnyView(result.cornerRadius(customCornerRadius))
            if component.clipToBounds == true {
                result = AnyView(result.clipped())
            }
        } else {
            let cornerRadius = component.cornerRadius ?? 0
            result = AnyView(result.cornerRadius(cornerRadius))
            if component.clipToBounds == true || cornerRadius > 0 {
                result = AnyView(result.clipped())
            }
        }
        
        // 5. Apply border overlay - can be overridden
        if customModifiers.skipBorder {
            // Skip border if requested
        } else if let customOverlay = customModifiers.customOverlay {
            result = AnyView(customOverlay(result))
        } else {
            result = AnyView(result.overlay(getBorder()))
        }
        
        // 6. Apply custom modifiers that should come after background/border
        if let afterBackground = customModifiers.afterBackgroundModifier {
            result = AnyView(afterBackground(result))
        }
        
        // 7. Apply margins (external spacing)
        if customModifiers.skipMargins {
            // Skip margins if requested
        } else {
            result = AnyView(result.padding(DynamicHelpers.getMargins(from: component)))
        }
        
        // 8. Apply z-order
        if component.indexAbove != nil || component.indexBelow != nil {
            result = AnyView(result.zOrder(component: component))
        }
        
        // 9. Apply opacity and visibility
        result = AnyView(result
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1))
        
        // 10. Apply final custom modifiers
        if let finalModifier = customModifiers.finalModifier {
            result = AnyView(finalModifier(result))
        }
        
        return result
    }
    
    private func shouldApplyFrameModifier() -> Bool {
        // ScrollView should not have frame modifier with infinity values
        if component.type?.lowercased() == "scrollview" || component.type?.lowercased() == "scroll" {
            return false
        }
        
        // Apply frame if any sizing property is set
        let hasExplicitWidth = component.width != nil || hasWeightForWidth()
        let hasExplicitHeight = component.height != nil || hasWeightForHeight()
        let hasConstraints = component.minWidth != nil || component.maxWidth != nil || 
                           component.minHeight != nil || component.maxHeight != nil ||
                           component.idealWidth != nil || component.idealHeight != nil
        
        return hasExplicitWidth || hasExplicitHeight || hasConstraints
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
        // Note: We don't have parent orientation here, so we check if width is nil or 0 which indicates weight usage
        return hasWeight && (component.width == nil || component.width == 0)
    }
    
    private func hasWeightForHeight() -> Bool {
        // Weight affects height in vertical layouts or when heightWeight is specified
        let hasWeight = (component.weight ?? 0) > 0 || (component.heightWeight ?? 0) > 0
        // Note: We don't have parent orientation here, so we check if height is nil or 0 which indicates weight usage
        return hasWeight && (component.height == nil || component.height == 0)
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
}