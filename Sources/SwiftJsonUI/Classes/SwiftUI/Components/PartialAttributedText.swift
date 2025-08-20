import SwiftUI

/// A text component that supports partial text attributes
/// Used for all text rendering with support for partial styling
public struct PartialAttributedText: View {
    let text: String
    let partialAttributes: [PartialAttribute]
    let fontSize: CGFloat?
    let fontWeight: Font.Weight?
    let fontColor: Color?
    let underline: Bool
    let strikethrough: Bool
    let lineSpacing: CGFloat?
    let lineLimit: Int?
    let textAlignment: TextAlignment
    
    public init(
        _ text: String,
        partialAttributes: [PartialAttribute] = [],
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
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
    
    /// Convenience initializer for generated code with string fontWeight
    public init(
        _ text: String,
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
        self.partialAttributes = []
        self.fontSize = fontSize
        self.fontWeight = fontWeight != nil ? Font.Weight.from(string: fontWeight!) : nil
        self.fontColor = fontColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.lineSpacing = lineSpacing
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }
    
    /// Convenience initializer for backward compatibility with dictionary format
    public init(
        _ text: String,
        partialAttributesDict: [[String: Any]],
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
        self.partialAttributes = partialAttributesDict.compactMap { 
            PartialAttribute(from: $0) 
        }
        self.fontSize = fontSize
        self.fontWeight = fontWeight != nil ? Font.Weight.from(string: fontWeight!) : nil
        self.fontColor = fontColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.lineSpacing = lineSpacing
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }
    
    public var body: some View {
        if !partialAttributes.isEmpty {
            let result = createAttributedStringWithMapping()
            Text(result.attributedString)
                .applyTextModifiers(
                    underline: underline,
                    strikethrough: strikethrough,
                    lineSpacing: lineSpacing,
                    lineLimit: lineLimit,
                    textAlignment: textAlignment
                )
                .environment(\.openURL, OpenURLAction { url in
                    // Handle app:// URLs for onclick actions
                    if url.scheme == "app", let host = url.host {
                        // Find the partial attribute with matching onClick
                        if let partial = result.urlMapping[host] {
                            partial.onClick?()
                            return .handled
                        }
                        return .handled
                    }
                    return .systemAction
                })
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
    
    private func createAttributedStringWithMapping() -> (attributedString: AttributedString, urlMapping: [String: PartialAttribute]) {
        var attributedString = AttributedString(text)
        var urlMapping: [String: PartialAttribute] = [:]
        
        // Apply base styles to entire string
        // Only apply base font if both fontSize and fontWeight are provided
        // Otherwise, let partial attributes handle font settings
        if let fontSize = fontSize, let fontWeight = fontWeight {
            attributedString.font = .system(size: fontSize, weight: fontWeight)
        } else if let fontSize = fontSize {
            attributedString.font = .system(size: fontSize)
        }
        
        if let fontColor = fontColor {
            attributedString.foregroundColor = fontColor
        }
        
        // Apply partial attributes
        for partial in partialAttributes {
            // Calculate the actual range (handles both numeric and text pattern)
            guard let calculatedRange = partial.calculateRange(in: text) else {
                continue
            }
            
            // Convert character offsets to AttributedString indices
            let stringStartIndex = text.index(text.startIndex, offsetBy: calculatedRange.lowerBound, limitedBy: text.endIndex) ?? text.startIndex
            let stringEndIndex = text.index(text.startIndex, offsetBy: calculatedRange.upperBound, limitedBy: text.endIndex) ?? text.endIndex
            
            // Find corresponding indices in AttributedString
            guard let attrStartIndex = AttributedString.Index(stringStartIndex, within: attributedString),
                  let attrEndIndex = AttributedString.Index(stringEndIndex, within: attributedString),
                  attrStartIndex < attrEndIndex else {
                continue
            }
            
            let range = attrStartIndex..<attrEndIndex
            
            // Apply fontColor
            if let color = partial.fontColor {
                attributedString[range].foregroundColor = color
            }
            
            // Apply fontSize and fontWeight
            if let size = partial.fontSize {
                attributedString[range].font = .system(size: size, weight: partial.fontWeight ?? .regular)
            } else if let weight = partial.fontWeight {
                // Apply only weight if fontSize not specified
                let size = fontSize ?? SwiftJsonUIConfiguration.shared.defaultFontSize
                attributedString[range].font = .system(size: size, weight: weight)
            }
            
            // Apply underline
            if partial.underline {
                attributedString[range].underlineStyle = .single
            }
            
            // Apply strikethrough
            if partial.strikethrough {
                attributedString[range].strikethroughStyle = .single
            }
            
            // Apply background color
            if let bgColor = partial.backgroundColor {
                attributedString[range].backgroundColor = bgColor
            }
            
            // Handle onclick as link
            if partial.onClick != nil {
                // Generate a unique ID for this onClick action
                let actionId = UUID().uuidString
                // Store the mapping for this onClick
                urlMapping[actionId] = partial
                if let url = URL(string: "app://\(actionId)") {
                    attributedString[range].link = url
                }
            }
        }
        
        return (attributedString, urlMapping)
    }
}

// MARK: - View Extensions for Text modifiers
extension View {
    func applyBaseFont(fontSize: CGFloat?, fontWeight: Font.Weight?) -> some View {
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
    let fontWeight: Font.Weight?
    
    func body(content: Content) -> some View {
        if let fontSize = fontSize, let fontWeight = fontWeight {
            // Both fontSize and fontWeight specified
            content.font(.system(size: fontSize, weight: fontWeight))
        } else if let fontSize = fontSize {
            // Only fontSize specified
            content.font(.system(size: fontSize))
        } else if let fontWeight = fontWeight {
            // Only fontWeight specified - use default size from configuration
            content.font(.system(size: SwiftJsonUIConfiguration.shared.defaultFontSize, weight: fontWeight))
        } else {
            content
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