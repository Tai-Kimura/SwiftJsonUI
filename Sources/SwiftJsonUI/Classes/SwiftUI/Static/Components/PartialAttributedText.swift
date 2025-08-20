import SwiftUI

/// A text component that supports partial text attributes
/// Used for all text rendering in Static mode
public struct PartialAttributedText: View {
    let text: String
    let partialAttributes: [[String: Any]]?
    let fontSize: CGFloat?
    let fontWeight: String?
    let fontColor: Color?
    let underline: Bool
    let strikethrough: Bool
    let lineSpacing: CGFloat?
    let lineLimit: Int?
    let textAlignment: TextAlignment
    
    public init(
        _ text: String,
        partialAttributes: [[String: Any]]? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: String? = nil,
        fontColor: Color? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        lineSpacing: CGFloat? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment = .leading
    ) {
        self.text = text
        self.partialAttributes = partialAttributes
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontColor = fontColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.lineSpacing = lineSpacing
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }
    
    public var body: some View {
        if let partialAttributes = partialAttributes, !partialAttributes.isEmpty {
            Text(createAttributedString())
                .applyTextModifiers(
                    underline: underline,
                    strikethrough: strikethrough,
                    lineSpacing: lineSpacing,
                    lineLimit: lineLimit,
                    textAlignment: textAlignment
                )
        } else {
            Text(text)
                .applyBaseFont(fontSize: fontSize, fontWeight: fontWeight)
                .applyTextColor(fontColor)
                .applyTextModifiers(
                    underline: underline,
                    strikethrough: strikethrough,
                    lineSpacing: lineSpacing,
                    lineLimit: lineLimit,
                    textAlignment: textAlignment
                )
        }
    }
    
    private func createAttributedString() -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Apply base styles to entire string
        if let fontSize = fontSize {
            attributedString.font = .system(size: fontSize, weight: fontWeightToSwiftUI(fontWeight))
        }
        if let fontColor = fontColor {
            attributedString.foregroundColor = fontColor
        }
        
        // Apply partial attributes
        for partial in partialAttributes ?? [] {
            guard let rangeArray = partial["range"] as? [Int],
                  rangeArray.count == 2 else {
                continue
            }
            
            let startOffset = rangeArray[0]
            let endOffset = rangeArray[1]
            
            // Convert character offsets to AttributedString indices
            let stringStartIndex = text.index(text.startIndex, offsetBy: startOffset, limitedBy: text.endIndex) ?? text.startIndex
            let stringEndIndex = text.index(text.startIndex, offsetBy: endOffset, limitedBy: text.endIndex) ?? text.endIndex
            
            // Find corresponding indices in AttributedString
            guard let attrStartIndex = AttributedString.Index(stringStartIndex, within: attributedString),
                  let attrEndIndex = AttributedString.Index(stringEndIndex, within: attributedString) else {
                continue
            }
            
            let startIndex = attrStartIndex
            let endIndex = attrEndIndex
            
            guard startIndex < endIndex else {
                continue
            }
            
            let range = startIndex..<endIndex
            
            // Apply fontColor
            if let fontColorHex = partial["fontColor"] as? String {
                attributedString[range].foregroundColor = Color(hex: fontColorHex)
            }
            
            // Apply fontSize
            if let partialFontSize = partial["fontSize"] as? CGFloat {
                let weight = fontWeightToSwiftUI(partial["fontWeight"] as? String)
                attributedString[range].font = .system(size: partialFontSize, weight: weight)
            } else if let fontWeightStr = partial["fontWeight"] as? String {
                // Apply only weight if fontSize not specified
                let size = fontSize ?? 17
                attributedString[range].font = .system(size: size, weight: fontWeightToSwiftUI(fontWeightStr))
            }
            
            // Apply underline
            if partial["underline"] as? Bool == true {
                attributedString[range].underlineStyle = .single
            }
            
            // Apply strikethrough
            if partial["strikethrough"] as? Bool == true {
                attributedString[range].strikethroughStyle = .single
            }
            
            // Apply background color
            if let backgroundHex = partial["background"] as? String {
                attributedString[range].backgroundColor = Color(hex: backgroundHex)
            }
            
            // Handle onclick as link
            if let onclick = partial["onclick"] as? String {
                if let url = URL(string: "app://\(onclick)") {
                    attributedString[range].link = url
                }
            }
        }
        
        return attributedString
    }
    
    private func fontWeightToSwiftUI(_ weight: String?) -> Font.Weight {
        switch weight?.lowercased() {
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
    }
}

// MARK: - View Extensions for Text modifiers
extension View {
    func applyBaseFont(fontSize: CGFloat?, fontWeight: String?) -> some View {
        self.modifier(BaseFontModifier(fontSize: fontSize, fontWeight: fontWeight))
    }
    
    func applyTextColor(_ color: Color?) -> some View {
        self.modifier(TextColorModifier(color: color))
    }
    
    func applyTextModifiers(
        underline: Bool,
        strikethrough: Bool,
        lineSpacing: CGFloat?,
        lineLimit: Int?,
        textAlignment: TextAlignment
    ) -> some View {
        self
            .underline(underline)
            .strikethrough(strikethrough)
            .lineSpacing(lineSpacing ?? 0)
            .lineLimit(lineLimit)
            .multilineTextAlignment(textAlignment)
    }
}

struct BaseFontModifier: ViewModifier {
    let fontSize: CGFloat?
    let fontWeight: String?
    
    func body(content: Content) -> some View {
        if let fontSize = fontSize {
            let weight = fontWeightToSwiftUI(fontWeight)
            content.font(.system(size: fontSize, weight: weight))
        } else {
            content
        }
    }
    
    private func fontWeightToSwiftUI(_ weight: String?) -> Font.Weight {
        switch weight?.lowercased() {
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
    }
}

struct TextColorModifier: ViewModifier {
    let color: Color?
    
    func body(content: Content) -> some View {
        if let color = color {
            content.foregroundColor(color)
        } else {
            content
        }
    }
}

// MARK: - Color Extension for hex conversion
extension Color {
    init(hex: String) {
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