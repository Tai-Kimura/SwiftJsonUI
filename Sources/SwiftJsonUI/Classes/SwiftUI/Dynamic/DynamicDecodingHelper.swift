//
//  DynamicDecodingHelper.swift
//  SwiftJsonUI
//
//  Helper for decoding dynamic component values
//

import Foundation
import SwiftUI

public struct DynamicDecodingHelper {
    
    /// Decode width or height value from JSON
    /// Returns: CGFloat value where .infinity = matchParent, nil = wrapContent, or specific value
    public static func decodeSizeValue(from container: KeyedDecodingContainer<DynamicComponent.CodingKeys>, 
                                       forKey key: DynamicComponent.CodingKeys) -> (value: CGFloat?, raw: String?) {
        // Try to decode as string first
        if let stringValue = try? container.decode(String.self, forKey: key) {
            switch stringValue.lowercased() {
            case "matchparent", "match_parent":
                return (.infinity, stringValue)
            case "wrapcontent", "wrap_content":
                return (nil, stringValue)
            default:
                // Try to parse as number (including "0" or "0.0")
                let numericValue = Double(stringValue).map { CGFloat($0) }
                return (numericValue, stringValue)
            }
        }
        
        // Try to decode as Double
        if let doubleValue = try? container.decode(Double.self, forKey: key) {
            return (CGFloat(doubleValue), nil)
        }
        
        // Try to decode as Int
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return (CGFloat(intValue), nil)
        }
        
        // No value found
        return (nil, nil)
    }
    
    /// Convert AnyCodable to array of CGFloat values
    public static func anyCodableToFloatArray(_ value: AnyCodable?) -> [CGFloat]? {
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
    
    /// Convert array of padding/margin values to EdgeInsets
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
    
    /// Convert AnyCodable to EdgeInsets (handles arrays and single values)
    public static func edgeInsetsFromAnyCodable(_ value: AnyCodable?) -> EdgeInsets? {
        guard let value = value else { return nil }
        
        if let array = anyCodableToFloatArray(value) {
            return edgeInsetsFromArray(array)
        }
        
        return nil
    }
    
    /// Decode child components from JSON
    /// Handles both single component and array of components
    /// Automatically filters out elements without type (include, data, etc.)
    public static func decodeChildren(from container: KeyedDecodingContainer<DynamicComponent.CodingKeys>, 
                                     forKey key: DynamicComponent.CodingKeys) -> [DynamicComponent]? {
        // Try to decode as array first (using FailableDecodable to skip invalid elements)
        if let childArray = try? container.decode([FailableDecodable<DynamicComponent>].self, forKey: key) {
            // Filter out nil values and components without type
            let validComponents = childArray.compactMap { $0.value }.filter { $0.isValid }
            return validComponents.isEmpty ? nil : validComponents
        }
        
        // Try to decode as single component
        if let singleChild = try? container.decode(DynamicComponent.self, forKey: key) {
            // Filter out components without type
            return singleChild.isValid ? [singleChild] : nil
        }
        
        // No children found
        return nil
    }
    
    /// Convert gravity string array to SwiftUI Alignment
    public static func gravityToAlignment(_ gravity: [String]?) -> Alignment? {
        guard let gravity = gravity, !gravity.isEmpty else { return nil }
        
        var horizontal: HorizontalAlignment = .center
        var vertical: VerticalAlignment = .center
        
        for value in gravity {
            switch value.lowercased() {
            // Horizontal
            case "left", "start":
                horizontal = .leading
            case "right", "end":
                horizontal = .trailing
            case "center_horizontal", "centerHorizontal":
                horizontal = .center
                
            // Vertical
            case "top":
                vertical = .top
            case "bottom":
                vertical = .bottom
            case "center_vertical", "centerVertical":
                vertical = .center
                
            // Combined
            case "center":
                horizontal = .center
                vertical = .center
                
            default:
                break
            }
        }
        
        // Convert to Alignment
        switch (horizontal, vertical) {
        case (.leading, .top):
            return .topLeading
        case (.center, .top):
            return .top
        case (.trailing, .top):
            return .topTrailing
        case (.leading, .center):
            return .leading
        case (.center, .center):
            return .center
        case (.trailing, .center):
            return .trailing
        case (.leading, .bottom):
            return .bottomLeading
        case (.center, .bottom):
            return .bottom
        case (.trailing, .bottom):
            return .bottomTrailing
        default:
            return .topLeading
        }
    }
    
    /// Decode gravity value from JSON
    /// Can be string, array of strings, or pipe-separated string (e.g., "top|center")
    public static func decodeGravity(from container: KeyedDecodingContainer<DynamicComponent.CodingKeys>) -> [String]? {
        // Try to decode as array of strings
        if let gravityArray = try? container.decode([String].self, forKey: .gravity) {
            return gravityArray
        }
        
        // Try to decode as single string
        if let gravityString = try? container.decode(String.self, forKey: .gravity) {
            // Check if it's pipe-separated
            if gravityString.contains("|") {
                return gravityString.split(separator: "|").map { String($0) }
            } else {
                return [gravityString]
            }
        }
        
        return nil
    }
    
    // MARK: - String to Type Conversion Methods (JSON Data Transformations)
    
    /// Convert hex string to Color
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
    
    /// Convert component properties to Font
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
    
    /// Convert content mode string to ContentMode
    public static func toContentMode(_ mode: String?) -> ContentMode {
        switch mode {
        case "AspectFill", "aspectFill":
            return .fill
        case "AspectFit", "aspectFit":
            return .fit
        default:
            return .fit
        }
    }
    
    /// Convert content mode string to NetworkImage.ContentMode
    public static func toNetworkImageContentMode(_ mode: String?) -> NetworkImage.ContentMode {
        switch mode {
        case "AspectFill", "aspectFill":
            return .fill
        case "AspectFit", "aspectFit":
            return .fit
        case "center", "Center":
            return .center
        default:
            return .fill
        }
    }
    
    /// Convert rendering mode string to Image.TemplateRenderingMode
    public static func toRenderingMode(_ mode: String?) -> Image.TemplateRenderingMode? {
        switch mode {
        case "template", "Template":
            return .template
        case "original", "Original":
            return .original
        default:
            return nil
        }
    }
    
    /// Convert icon position string to IconLabelView.IconPosition
    public static func toIconPosition(_ position: String?) -> IconLabelView.IconPosition {
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
    
    /// Convert text alignment string to TextAlignment
    public static func toTextAlignment(_ alignment: String?) -> TextAlignment {
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
}