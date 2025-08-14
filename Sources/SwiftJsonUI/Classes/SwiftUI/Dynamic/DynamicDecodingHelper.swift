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
}