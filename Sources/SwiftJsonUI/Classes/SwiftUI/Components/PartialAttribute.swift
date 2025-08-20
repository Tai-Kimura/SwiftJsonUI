import SwiftUI

/// Represents a partial text attribute that can be applied to a range of text
public struct PartialAttribute {
    /// The range of characters to apply the attributes to (start, end)
    public let range: Range<Int>
    
    /// Optional text pattern to search for (alternative to numeric range)
    public let textPattern: String?
    
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
    
    /// Optional onclick action closure for this range
    public let onClick: (() -> Void)?
    
    /// Store the action name when initialized from dictionary (for code generation)
    public let onClickActionName: String?
    
    /// Calculate the actual range in the given text
    /// Returns nil if textPattern is not found in the text
    public func calculateRange(in text: String) -> Range<Int>? {
        if let pattern = textPattern {
            // Find the pattern in the text
            if let range = text.range(of: pattern) {
                let startOffset = text.distance(from: text.startIndex, to: range.lowerBound)
                let endOffset = text.distance(from: text.startIndex, to: range.upperBound)
                return startOffset..<endOffset
            }
            return nil
        } else {
            // Use the numeric range directly
            return range
        }
    }
    
    public init(
        range: Range<Int>,
        fontColor: Color? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        backgroundColor: Color? = nil,
        onClick: (() -> Void)? = nil,
        onClickActionName: String? = nil
    ) {
        self.range = range
        self.textPattern = nil
        self.fontColor = fontColor
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.underline = underline
        self.strikethrough = strikethrough
        self.backgroundColor = backgroundColor
        self.onClick = onClick
        self.onClickActionName = onClickActionName
    }
    
    /// Initialize with text pattern instead of numeric range
    public init(
        textPattern: String,
        fontColor: Color? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        backgroundColor: Color? = nil,
        onClick: (() -> Void)? = nil,
        onClickActionName: String? = nil
    ) {
        self.range = 0..<0  // Placeholder, will be calculated from text
        self.textPattern = textPattern
        self.fontColor = fontColor
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.underline = underline
        self.strikethrough = strikethrough
        self.backgroundColor = backgroundColor
        self.onClick = onClick
        self.onClickActionName = onClickActionName
    }
    
    /// Initialize from dictionary (for backward compatibility)
    /// Note: onClick will be nil when initialized from dictionary.
    public init?(from dictionary: [String: Any]) {
        // Parse range - can be either [Int, Int] array or String pattern
        if let rangeArray = dictionary["range"] as? [Int],
           rangeArray.count == 2,
           rangeArray[0] < rangeArray[1] {
            self.range = rangeArray[0]..<rangeArray[1]
            self.textPattern = nil
        } else if let pattern = dictionary["range"] as? String {
            self.range = 0..<0  // Placeholder, will be calculated from text
            self.textPattern = pattern
        } else {
            return nil
        }
        
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
        
        // Store action name for URL-based handling
        self.onClickActionName = dictionary["onclick"] as? String
        self.onClick = nil  // Will be set in code generation
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