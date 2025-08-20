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
    let onClickHandler: ((String) -> Void)?
    
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
        textAlignment: TextAlignment = .leading,
        onClickHandler: ((String) -> Void)? = nil
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
        self.onClickHandler = onClickHandler
    }
    
    /// Convenience initializer for backward compatibility with dictionary format
    public init(
        _ text: String,
        partialAttributesDict: [[String: Any]]? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: String? = nil,
        fontColor: Color? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        lineSpacing: CGFloat? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment = .leading,
        onClickHandler: ((String) -> Void)? = nil
    ) {
        self.text = text
        self.partialAttributes = partialAttributesDict?.compactMap { 
            PartialAttribute(from: $0, onClickHandler: onClickHandler) 
        } ?? []
        self.fontSize = fontSize
        self.fontWeight = fontWeight != nil ? Font.Weight.from(string: fontWeight!) : nil
        self.fontColor = fontColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.lineSpacing = lineSpacing
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.onClickHandler = onClickHandler
    }
    
    public var body: some View {
        if !partialAttributes.isEmpty {
            Text(createAttributedString())
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
                        // Find the partial attribute with matching action name or ID
                        for partial in partialAttributes {
                            if let actionName = partial.onClickActionName, actionName == host {
                                partial.onClick?()
                                return .handled
                            }
                        }
                        // Fallback to the old string-based handler if needed
                        onClickHandler?(host)
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
    
    private func createAttributedString() -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Apply base styles to entire string
        if let fontSize = fontSize {
            attributedString.font = .system(size: fontSize, weight: fontWeight ?? .regular)
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
                let size = fontSize ?? 17
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
            // Use action name if available (for URL-based handling), otherwise generate unique ID
            if partial.onClick != nil {
                let actionId = partial.onClickActionName ?? UUID().uuidString
                if let url = URL(string: "app://\(actionId)") {
                    attributedString[range].link = url
                }
            }
        }
        
        return attributedString
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
        if let fontSize = fontSize {
            content.font(.system(size: fontSize, weight: fontWeight ?? .regular))
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