//
//  DynamicShadow.swift
//  SwiftJsonUI
//
//  Flexible shadow type that accepts string or object
//

import SwiftUI
#if DEBUG


// MARK: - Shadow Model
public struct ShadowConfig: Decodable {
    let color: String?
    let opacity: CGFloat?
    let radius: CGFloat?
    let x: CGFloat?
    let y: CGFloat?
    
    public init(color: String? = "#000000",
                opacity: CGFloat? = 0.1,
                radius: CGFloat? = 4,
                x: CGFloat? = 0,
                y: CGFloat? = 2) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Flexible Shadow Type
public enum DynamicShadow: Decodable {
    case string(String)
    case config(ShadowConfig)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as string first (for simple shadow like "default")
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        }
        // Try to decode as shadow config object
        else if let shadowConfig = try? container.decode(ShadowConfig.self) {
            self = .config(shadowConfig)
        }
        else {
            throw DecodingError.typeMismatch(DynamicShadow.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                    debugDescription: "Expected string or shadow object"))
        }
    }
    
    public var shadowColor: Color {
        switch self {
        case .string(let value):
            // Handle predefined shadow types
            switch value.lowercased() {
            case "default", "light":
                return Color.black.opacity(0.1)
            case "dark":
                return Color.black.opacity(0.3)
            case "none":
                return Color.clear
            default:
                // Try to parse as hex color
                return DynamicHelpers.getColor(value) ?? Color.black.opacity(0.1)
            }
        case .config(let config):
            let baseColor = DynamicHelpers.getColor(config.color) ?? Color.black
            return baseColor.opacity(config.opacity ?? 0.1)
        }
    }
    
    public var shadowRadius: CGFloat {
        switch self {
        case .string(let value):
            switch value.lowercased() {
            case "default", "light":
                return 4
            case "dark":
                return 8
            case "none":
                return 0
            default:
                return 4
            }
        case .config(let config):
            return config.radius ?? 4
        }
    }
    
    public var shadowOffset: CGSize {
        switch self {
        case .string(let value):
            switch value.lowercased() {
            case "default", "light", "dark":
                return CGSize(width: 0, height: 2)
            case "none":
                return CGSize.zero
            default:
                return CGSize(width: 0, height: 2)
            }
        case .config(let config):
            return CGSize(width: config.x ?? 0, height: config.y ?? 2)
        }
    }
}
#endif // DEBUG
