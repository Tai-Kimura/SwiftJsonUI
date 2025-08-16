//
//  DynamicHelpers.swift
//  SwiftJsonUI
//
//  Helper functions for dynamic views
//

import SwiftUI

// MARK: - Helper Functions
public struct DynamicHelpers {
    
    public static func fontFromComponent(_ component: DynamicComponent) -> Font {
        let size = component.fontSize ?? 16
        let fontName = component.font
        let weight = component.fontWeight
        
        // Determine weight
        let fontWeight: Font.Weight = {
            switch weight?.lowercased() ?? fontName?.lowercased() {
            case "bold":
                return .bold
            case "semibold":
                return .semibold
            case "medium":
                return .medium
            case "light":
                return .light
            case "thin":
                return .thin
            case "ultralight":
                return .ultraLight
            case "heavy":
                return .heavy
            case "black":
                return .black
            default:
                return .regular
            }
        }()
        
        // Apply custom font or system font
        if let fontName = fontName, fontName.lowercased() != "bold" {
            return .custom(fontName, size: size)
        } else {
            return .system(size: size, weight: fontWeight)
        }
    }
    
    public static func colorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        let cleanHex = hex.replacingOccurrences(of: "#", with: "")
        
        guard cleanHex.count == 6,
              let intValue = Int(cleanHex, radix: 16) else {
            return nil
        }
        
        let r = Double((intValue >> 16) & 0xFF) / 255.0
        let g = Double((intValue >> 8) & 0xFF) / 255.0
        let b = Double(intValue & 0xFF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
    
    public static func contentModeFromString(_ mode: String?) -> ContentMode {
        switch mode {
        case "AspectFill", "aspectFill":
            return .fill
        case "AspectFit", "aspectFit":
            return .fit
        default:
            return .fit
        }
    }
    
    public static func networkImageContentMode(_ mode: String?) -> NetworkImage.ContentMode {
        switch mode {
        case "AspectFill", "aspectFill":
            return .fill
        case "AspectFit", "aspectFit":
            return .fit
        case "center", "Center":
            return .center
        default:
            return .fit
        }
    }
    
    public static func renderingModeFromString(_ mode: String?) -> Image.TemplateRenderingMode? {
        switch mode {
        case "template", "Template":
            return .template
        case "original", "Original":
            return .original
        default:
            return nil
        }
    }
    
    public static func iconPositionFromString(_ position: String?) -> IconLabelView.IconPosition {
        switch position {
        case "top", "Top":
            return .top
        case "left", "Left":
            return .left
        case "right", "Right":
            return .right
        case "bottom", "Bottom":
            return .bottom
        default:
            return .left
        }
    }
    
    public static func textAlignmentFromString(_ alignment: String?) -> TextAlignment {
        switch alignment {
        case "Center", "center":
            return .center
        case "Left", "left":
            return .leading
        case "Right", "right":
            return .trailing
        default:
            return .leading
        }
    }
    
    public static func frameValue(_ value: String?) -> CGFloat? {
        guard let value = value else { return nil }
        
        switch value {
        case "matchParent":
            // SwiftUIでは.infinityを直接使わず、nilを返してmaxWidthで処理
            return nil
        case "wrapContent":
            return nil
        case "0", "0.0":
            // width:0 or height:0 for weight system
            return 0
        default:
            if let doubleValue = Double(value) {
                return CGFloat(doubleValue)
            }
            return nil
        }
    }
    
    public static func isMatchParent(_ value: String?) -> Bool {
        return value == "matchParent"
    }
    
    // Helper to convert AnyCodable to array of CGFloat values
    private static func anyCodableToFloatArray(_ value: AnyCodable?) -> [CGFloat]? {
        guard let value = value else { return nil }
        
        if let array = value.value as? [Any] {
            return array.compactMap { item in
                if let value = item as? CGFloat {
                    return value
                } else if let value = item as? Double {
                    return CGFloat(value)
                } else if let value = item as? Int {
                    return CGFloat(value)
                }
                return nil
            }
        } else if let value = value.value as? CGFloat {
            return [value]
        } else if let value = value.value as? Double {
            return [CGFloat(value)]
        } else if let value = value.value as? Int {
            return [CGFloat(value)]
        }
        
        return nil
    }
    
    // Convert array of padding/margin values to EdgeInsets
    public static func edgeInsetsFromArray(_ values: [CGFloat]) -> EdgeInsets {
        switch values.count {
        case 1:
            // All edges same value
            let value = values[0]
            return EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
        case 2:
            // [Vertical, Horizontal]
            let vValue = values[0]
            let hValue = values[1]
            return EdgeInsets(top: vValue, leading: hValue, bottom: vValue, trailing: hValue)
        case 4:
            // [Top, Right, Bottom, Left]
            return EdgeInsets(top: values[0], leading: values[3], bottom: values[2], trailing: values[1])
        default:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
    }
    
    // Convert AnyCodable to EdgeInsets (handles arrays and single values)
    public static func edgeInsetsFromAnyCodable(_ value: AnyCodable?) -> EdgeInsets? {
        guard let value = value else { return nil }
        
        if let array = anyCodableToFloatArray(value) {
            return edgeInsetsFromArray(array)
        }
        
        return nil
    }
    
    // Unified method to get padding EdgeInsets from component
    public static func getPadding(from component: DynamicComponent) -> EdgeInsets {
        var resultPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        // Check for paddings/padding array or value
        if let paddingInsets = edgeInsetsFromAnyCodable(component.paddings ?? component.padding) {
            resultPadding = paddingInsets
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
        if let insetInsets = edgeInsetsFromAnyCodable(component.insets) {
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
        if let marginInsets = edgeInsetsFromAnyCodable(component.margins) {
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
        return colorFromHex(component.background) ?? .clear
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
                if component.width == 0 && ((component.weight ?? 0) > 0 || (component.widthWeight ?? 0) > 0) {
                    return .infinity  // Fill the width allocated by WeightedHStack
                }
            }
            return component.width
        }()
        
        let heightValue: CGFloat? = {
            if isWeightedChild {
                // Check if weight affects height (vertical stack with weight or heightWeight)
                if component.height == 0 && ((component.weight ?? 0) > 0 || (component.heightWeight ?? 0) > 0) {
                    return .infinity  // Fill the height allocated by WeightedVStack
                }
            }
            return component.height
        }()
        
        return self
            .applyPadding(component, skip: skipPadding)  // Apply padding first (inner spacing)
            .frame(
                width: widthValue == .infinity ? nil : widthValue,
                height: heightValue == .infinity ? nil : heightValue
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