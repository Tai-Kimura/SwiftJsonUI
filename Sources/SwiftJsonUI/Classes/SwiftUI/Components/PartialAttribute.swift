import SwiftUI

/// Represents a partial text attribute that can be applied to a range of text
public struct PartialAttribute {
    /// The range of characters to apply the attributes to (start, end)
    public let range: Range<Int>
    
    /// Optional font color for this range
    public let fontColor: Color?
    
    /// Optional font size for this range
    public let fontSize: CGFloat?
    
    /// Optional font weight for this range
    public let fontWeight: Font.Weight?
    
    /// Whether to underline this range
    public let underline: Bool
    
    /// Whether to strikethrough this range
    public let strikethrough: Bool
    
    /// Optional background color for this range
    public let backgroundColor: Color?
    
    /// Optional onclick action name for this range
    public let onClick: String?
    
    public init(
        range: Range<Int>,
        fontColor: Color? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        backgroundColor: Color? = nil,
        onClick: String? = nil
    ) {
        self.range = range
        self.fontColor = fontColor
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.underline = underline
        self.strikethrough = strikethrough
        self.backgroundColor = backgroundColor
        self.onClick = onClick
    }
    
    /// Initialize from dictionary (for backward compatibility)
    public init?(from dictionary: [String: Any]) {
        // Parse range
        guard let rangeArray = dictionary["range"] as? [Int],
              rangeArray.count == 2,
              rangeArray[0] < rangeArray[1] else {
            return nil
        }
        self.range = rangeArray[0]..<rangeArray[1]
        
        // Parse fontColor
        if let colorHex = dictionary["fontColor"] as? String {
            self.fontColor = Color(hex: colorHex)
        } else {
            self.fontColor = nil
        }
        
        // Parse fontSize
        self.fontSize = dictionary["fontSize"] as? CGFloat
        
        // Parse fontWeight
        if let weightString = dictionary["fontWeight"] as? String {
            self.fontWeight = Font.Weight.from(string: weightString)
        } else {
            self.fontWeight = nil
        }
        
        // Parse underline
        self.underline = dictionary["underline"] as? Bool ?? false
        
        // Parse strikethrough
        self.strikethrough = dictionary["strikethrough"] as? Bool ?? false
        
        // Parse backgroundColor
        if let bgHex = dictionary["background"] as? String {
            self.backgroundColor = Color(hex: bgHex)
        } else {
            self.backgroundColor = nil
        }
        
        // Parse onClick
        self.onClick = dictionary["onclick"] as? String
    }
}

// MARK: - Font.Weight Extension
extension Font.Weight {
    static func from(string: String) -> Font.Weight {
        switch string.lowercased() {
        case "ultralight":
            return .ultraLight
        case "thin":
            return .thin
        case "light":
            return .light
        case "regular":
            return .regular
        case "medium":
            return .medium
        case "semibold":
            return .semibold
        case "bold":
            return .bold
        case "heavy":
            return .heavy
        case "black":
            return .black
        default:
            return .regular
        }
    }
}

// MARK: - Color Extension for hex conversion
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}