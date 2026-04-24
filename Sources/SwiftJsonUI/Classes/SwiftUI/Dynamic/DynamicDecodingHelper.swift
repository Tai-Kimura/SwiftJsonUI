//
//  DynamicDecodingHelper.swift
//  SwiftJsonUI
//
//  Helper for decoding dynamic component values
//

import Foundation
import SwiftUI
#if DEBUG


public struct DynamicDecodingHelper {

    // MARK: - Alias Coalescing

    /// Return the first non-nil value from the variadic list. Used to bridge
    /// attribute-name variations the tool may emit (e.g. `minimumValue` vs
    /// `minimum`, `selectedIndex` vs `selectedTabIndex`) until the backfill
    /// catalog declares `aliases` and loaders normalize up front.
    public static func firstNonNil<T>(_ values: T?...) -> T? {
        for value in values {
            if let value = value { return value }
        }
        return nil
    }

    // MARK: - Bool-or-Binding

    /// Resolve a value that may be either a Boolean or a `@{propertyName}`
    /// binding string. Falls back to `default` when nothing usable is found.
    /// Covers attributes like `enabled`, `disabled`, `isOn`, `checked`,
    /// `scrollEnabled` where both shapes are valid per the shared catalog.
    public static func resolveBoolOrBinding(
        _ value: AnyCodable?,
        data: [String: Any] = [:],
        default defaultValue: Bool = false
    ) -> Bool {
        guard let value = value else { return defaultValue }

        if let boolValue = value.value as? Bool {
            return boolValue
        }
        if let stringValue = value.value as? String {
            if stringValue.hasPrefix("@{") && stringValue.hasSuffix("}") {
                let propertyName = String(stringValue.dropFirst(2).dropLast(1))
                if let dataValue = data[propertyName] {
                    if let boolValue = dataValue as? Bool { return boolValue }
                    if let intValue = dataValue as? Int { return intValue != 0 }
                    if let stringValue = dataValue as? String {
                        return stringValue == "true" || stringValue == "1"
                    }
                }
                return defaultValue
            }
            if stringValue == "true" || stringValue == "1" { return true }
            if stringValue == "false" || stringValue == "0" { return false }
        }
        return defaultValue
    }

    // MARK: - Visibility

    /// Resolve effective visibility for a component considering both the
    /// legacy `hidden` boolean and the `visibility` three-state string.
    /// `hidden == true` always wins; otherwise the `visibility` value is
    /// returned as-is (`"visible"`, `"invisible"`, `"gone"`). Returns
    /// `"visible"` when neither is present.
    public static func resolveVisibility(
        component: DynamicComponent,
        data: [String: Any] = [:]
    ) -> String {
        if component.hidden == true {
            return "gone"
        }
        switch component.visibility {
        case "gone", "invisible", "visible":
            return component.visibility ?? "visible"
        default:
            return "visible"
        }
    }

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
                // Handle nested AnyCodable
                if let anyCodable = item as? AnyCodable {
                    if let value = anyCodable.value as? CGFloat {
                        return value
                    } else if let value = anyCodable.value as? Double {
                        return CGFloat(value)
                    } else if let value = anyCodable.value as? Int {
                        return CGFloat(value)
                    }
                }
                // Handle direct values
                else if let value = item as? CGFloat {
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

    /// Convert AnyCodable margin value to CGFloat (handles binding and direct values)
    /// - Parameters:
    ///   - value: AnyCodable value that can be CGFloat, Int, Double, String, or binding
    ///   - data: Data dictionary for resolving bindings
    /// - Returns: CGFloat value or 0 if not resolvable
    public static func marginValueToCGFloat(_ value: AnyCodable?, data: [String: Any] = [:]) -> CGFloat {
        guard let value = value else { return 0 }

        // Handle direct numeric values
        if let floatValue = value.value as? CGFloat {
            return floatValue
        }
        if let doubleValue = value.value as? Double {
            return CGFloat(doubleValue)
        }
        if let intValue = value.value as? Int {
            return CGFloat(intValue)
        }

        // Handle string values (including bindings)
        if let stringValue = value.value as? String {
            // Check for binding pattern @{propertyName}
            if stringValue.hasPrefix("@{") && stringValue.hasSuffix("}") {
                let startIndex = stringValue.index(stringValue.startIndex, offsetBy: 2)
                let endIndex = stringValue.index(stringValue.endIndex, offsetBy: -1)
                let propertyName = String(stringValue[startIndex..<endIndex])

                // Look up value in data dictionary
                if let dataValue = data[propertyName] {
                    if let floatValue = dataValue as? CGFloat {
                        return floatValue
                    }
                    if let doubleValue = dataValue as? Double {
                        return CGFloat(doubleValue)
                    }
                    if let intValue = dataValue as? Int {
                        return CGFloat(intValue)
                    }
                }
                return 0 // Binding not resolved
            }

            // Try to parse as number
            if let doubleValue = Double(stringValue) {
                return CGFloat(doubleValue)
            }
        }

        return 0
    }
    
    /// Decode child components from JSON
    /// Handles both single component and array of components
    /// Keeps all components including those without type (include, data, etc.) for later filtering
    public static func decodeChildren(from container: KeyedDecodingContainer<DynamicComponent.CodingKeys>, 
                                     forKey key: DynamicComponent.CodingKeys) -> [DynamicComponent]? {
        // Try to decode as array first (using FailableDecodable to skip invalid elements)
        if let childArray = try? container.decode([FailableDecodable<DynamicComponent>].self, forKey: key) {
            // Filter out nil values but keep all components (including those without type like include)
            // The actual filtering will be done later by DynamicViewContainer
            let validComponents = childArray.compactMap { $0.value }
            
            #if DEBUG
            print("[DynamicDecodingHelper] Decoded \(childArray.count) children, \(validComponents.count) valid")
            for (index, component) in validComponents.enumerated() {
                print("[DynamicDecodingHelper] Child[\(index)]: type=\(component.type ?? "nil")")
                if component.type == "Collection" {
                    print("[DynamicDecodingHelper] Collection found at index \(index)")
                    print("[DynamicDecodingHelper]   sections: \(component.sections?.count ?? 0)")
                    print("[DynamicDecodingHelper]   items: \(component.items ?? [])")
                    print("[DynamicDecodingHelper]   rawData.items: \(component.rawData["items"] ?? "nil")")
                }
            }
            #endif
            
            return validComponents.isEmpty ? nil : validComponents
        }
        
        // Try to decode as single component
        if let singleChild = try? container.decode(DynamicComponent.self, forKey: key) {
            // Keep all components (including those without type like include)
            return [singleChild]
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
    
    /// Get color from identifier using SwiftJsonUIConfiguration
    /// This supports both hex colors and color resource keys
    public static func getColor(_ identifier: String?) -> Color? {
        guard let identifier = identifier else { return nil }
        
        // Use SwiftJsonUIConfiguration to get color
        // This will check colorProvider first, then fall back to hex conversion
        return SwiftJsonUIConfiguration.shared.getColor(for: identifier)
    }
    
    /// Convert component properties to Font
    public static func fontFromComponent(_ component: DynamicComponent) -> Font? {
        // Return nil if no font attributes are specified
        guard component.fontSize != nil || component.font != nil || component.fontWeight != nil || component.fontFamily != nil else {
            return nil
        }

        let config = SwiftJsonUIConfiguration.shared
        let size = component.fontSize ?? config.font.size

        // fontFamily takes highest priority: fontProvider -> Font.custom()
        if let fontFamily = component.fontFamily {
            if let providedFont = config.fontProvider?(fontFamily) {
                return providedFont
            }
            return .custom(fontFamily, size: size)
        }

        let fontName = component.font ?? config.font.name
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
                return config.font.weight
            }
        }()

        // Weight-only font names that should use system font
        let weightNames = ["bold", "semibold", "medium", "light", "thin", "ultralight", "heavy", "black"]

        // Apply custom font: fontProvider -> custom name -> system font
        if let fontName = fontName, !weightNames.contains(fontName.lowercased()) {
            if let providedFont = config.fontProvider?(fontName) {
                return providedFont
            }
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
            return .fit
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
#endif // DEBUG
