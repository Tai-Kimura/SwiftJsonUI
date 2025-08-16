//
//  DynamicHelpers.swift
//  SwiftJsonUI
//
//  Helper functions for dynamic views
//

import SwiftUI

// MARK: - Helper Functions
public struct DynamicHelpers {
    
    // MARK: - Wrapper methods for JSON data transformations (delegate to DynamicDecodingHelper)
    
    public static func fontFromComponent(_ component: DynamicComponent) -> Font {
        return DynamicDecodingHelper.fontFromComponent(component)
    }
    
    public static func colorFromHex(_ hex: String?) -> Color? {
        return DynamicDecodingHelper.colorFromHex(hex)
    }
    
    public static func getContentMode(from component: DynamicComponent) -> ContentMode {
        return DynamicDecodingHelper.toContentMode(component.contentMode)
    }
    
    public static func getNetworkImageContentMode(from component: DynamicComponent) -> NetworkImage.ContentMode {
        return DynamicDecodingHelper.toNetworkImageContentMode(component.contentMode)
    }
    
    public static func getRenderingMode(from component: DynamicComponent) -> Image.TemplateRenderingMode? {
        return DynamicDecodingHelper.toRenderingMode(component.renderingMode)
    }
    
    public static func getIconPosition(from component: DynamicComponent) -> IconLabelView.IconPosition {
        return DynamicDecodingHelper.toIconPosition(component.iconPosition)
    }
    
    public static func getTextAlignment(from component: DynamicComponent) -> TextAlignment {
        return DynamicDecodingHelper.toTextAlignment(component.textAlign)
    }
    
    // Keep old methods for backward compatibility (deprecated)
    @available(*, deprecated, renamed: "getContentMode(from:)")
    public static func contentModeFromString(_ mode: String?) -> ContentMode {
        return DynamicDecodingHelper.toContentMode(mode)
    }
    
    @available(*, deprecated, renamed: "getNetworkImageContentMode(from:)")
    public static func networkImageContentMode(_ mode: String?) -> NetworkImage.ContentMode {
        return DynamicDecodingHelper.toNetworkImageContentMode(mode)
    }
    
    @available(*, deprecated, renamed: "getRenderingMode(from:)")
    public static func renderingModeFromString(_ mode: String?) -> Image.TemplateRenderingMode? {
        return DynamicDecodingHelper.toRenderingMode(mode)
    }
    
    @available(*, deprecated, renamed: "getIconPosition(from:)")
    public static func iconPositionFromString(_ position: String?) -> IconLabelView.IconPosition {
        return DynamicDecodingHelper.toIconPosition(position)
    }
    
    @available(*, deprecated, renamed: "getTextAlignment(from:)")
    public static func textAlignmentFromString(_ alignment: String?) -> TextAlignment {
        return DynamicDecodingHelper.toTextAlignment(alignment)
    }
    
    // Unified method to get padding EdgeInsets from component
    public static func getPadding(from component: DynamicComponent) -> EdgeInsets {
        var resultPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        // Debug logging
        if component.type?.lowercased() == "scrollview" {
            print("🔍 ScrollView padding debug: paddings=\(String(describing: component.paddings)), padding=\(String(describing: component.padding))")
        }
        
        // Check for paddings/padding array or value
        if let paddingInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.paddings ?? component.padding) {
            resultPadding = paddingInsets
            if component.type?.lowercased() == "scrollview" {
                print("🔍 ScrollView padding from array: \(resultPadding)")
            }
        } else {
            // Fallback to individual padding properties
            let top = component.paddingTop ?? component.topPadding ?? 0
            let leading = component.paddingLeft ?? component.leftPadding ?? 0
            let bottom = component.paddingBottom ?? component.bottomPadding ?? 0
            let trailing = component.paddingRight ?? component.rightPadding ?? 0
            
            resultPadding = EdgeInsets(
                top: top,
                leading: leading,
                bottom: bottom,
                trailing: trailing
            )
        }
        
        // Apply insets if present (additive)
        if let insetInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.insets) {
            resultPadding.top += insetInsets.top
            resultPadding.leading += insetInsets.leading
            resultPadding.bottom += insetInsets.bottom
            resultPadding.trailing += insetInsets.trailing
        }
        
        // Apply insetHorizontal if present (additive)
        if let value = component.insetHorizontal {
            resultPadding.leading += value
            resultPadding.trailing += value
        }
        
        return resultPadding
    }
    
    // Unified method to get margins EdgeInsets from component
    public static func getMargins(from component: DynamicComponent) -> EdgeInsets {
        // Check for margins array or value
        if let marginInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.margins) {
            return marginInsets
        }
        
        // Fallback to individual margin properties
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
    
    // Get background color from component
    public static func getBackground(from component: DynamicComponent) -> Color {
        return DynamicDecodingHelper.colorFromHex(component.background) ?? .clear
    }
    
    // Get opacity from component
    public static func getOpacity(from component: DynamicComponent) -> Double {
        if let opacity = component.opacity {
            return Double(opacity)
        }
        if let alpha = component.alpha {
            return Double(alpha)
        }
        return 1.0
    }
    
    // Check if component should be hidden
    public static func isHidden(_ component: DynamicComponent) -> Bool {
        return component.hidden == true || component.visibility == "gone"
    }
}

// MARK: - View Modifier Extension
extension View {
    public func applyDynamicModifiers(_ component: DynamicComponent, isWeightedChild: Bool = false, skipPadding: Bool = false) -> some View {
        // width and height are already CGFloat? after JSON decoding
        // .infinity means matchParent, nil means wrapContent or not specified
        let widthValue: CGFloat? = {
            // If this is a weighted child, WeightedStack handles the main axis sizing
            // But we still need to set infinity for the content to fill the allocated space
            if isWeightedChild {
                // Check if weight affects width (horizontal stack with weight or widthWeight)
                if (component.width == nil || component.width == 0) && ((component.weight ?? 0) > 0 || (component.widthWeight ?? 0) > 0) {
                    return .infinity  // Fill the width allocated by WeightedHStack
                }
            }
            return component.width
        }()
        
        let heightValue: CGFloat? = {
            if isWeightedChild {
                // Check if weight affects height (vertical stack with weight or heightWeight)
                if (component.height == nil || component.height == 0) && ((component.weight ?? 0) > 0 || (component.heightWeight ?? 0) > 0) {
                    return .infinity  // Fill the height allocated by WeightedVStack
                }
            }
            return component.height
        }()
        
        return self
            .applyPadding(component, skip: skipPadding)  // Apply padding first
            .frame(
                width: widthValue,
                height: heightValue
            )
            .frame(
                minWidth: component.minWidth,
                maxWidth: widthValue == .infinity ? .infinity : component.maxWidth,
                minHeight: component.minHeight,
                maxHeight: heightValue == .infinity ? .infinity : component.maxHeight
            )
            .background(DynamicHelpers.colorFromHex(component.background) ?? Color.clear)
            .cornerRadius(component.cornerRadius ?? 0)
            .applyBorder(component)
            .dynamicClipped(component.clipToBounds == true)
            .applyMargin(component)  // Apply margin last (outer spacing)
            .opacity(component.opacity ?? component.alpha ?? (component.visibility == "invisible" ? 0 : 1))
            .dynamicHidden(component.hidden == true || component.visibility == "gone")
            .disabled(component.userInteractionEnabled == false)
            .applyShadow(component)
            .applyAspectRatio(component)
            .applyCenterInParent(component)
    }
    
    @ViewBuilder
    func dynamicHidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func dynamicClipped(_ clipped: Bool) -> some View {
        if clipped {
            self.clipped()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyBorder(_ component: DynamicComponent) -> some View {
        if let borderWidth = component.borderWidth,
           let borderColor = component.borderColor {
            let color = DynamicHelpers.colorFromHex(borderColor) ?? .clear
            let radius = component.cornerRadius ?? 0
            self.overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: borderWidth)
            )
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyShadow(_ component: DynamicComponent) -> some View {
        if let shadow = component.shadow,
           let shadowDict = shadow.value as? [String: Any] {
            let color = shadowDict["shadowColor"] as? String ?? "#000000"
            let radius = CGFloat(shadowDict["shadowRadius"] as? Double ?? 5.0)
            let offsetX = CGFloat(shadowDict["shadowOffsetX"] as? Double ?? 0.0)
            let offsetY = CGFloat(shadowDict["shadowOffsetY"] as? Double ?? 0.0)
            let opacity = shadowDict["shadowOpacity"] as? Double ?? 0.3
            
            self.shadow(
                color: (DynamicHelpers.colorFromHex(color) ?? Color.black).opacity(opacity),
                radius: radius,
                x: offsetX,
                y: offsetY
            )
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyAspectRatio(_ component: DynamicComponent) -> some View {
        if let aspectWidth = component.aspectWidth,
           let aspectHeight = component.aspectHeight,
           aspectHeight > 0 {
            let ratio = aspectWidth / aspectHeight
            self.aspectRatio(ratio, contentMode: .fit)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyCenterInParent(_ component: DynamicComponent) -> some View {
        if component.centerInParent == true {
            self.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyPadding(_ component: DynamicComponent, skip: Bool = false) -> some View {
        if skip {
            self
        } else {
            self.padding(DynamicHelpers.getPadding(from: component))
        }
    }
    
    @ViewBuilder
    func applyMargin(_ component: DynamicComponent) -> some View {
        self.padding(DynamicHelpers.getMargins(from: component))
    }
}