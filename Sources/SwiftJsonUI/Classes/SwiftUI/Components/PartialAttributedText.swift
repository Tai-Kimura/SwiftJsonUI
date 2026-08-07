import SwiftUI

/// The styling a label switches to while it is selected.
///
/// UIKit keeps two attribute dictionaries and swaps between them when
/// `SJUILabel.selected` flips (`applyAttributedText`:
/// `let attr = selected ? highlightAttributes : attributes`). SwiftUI has no
/// highlighted state on `Text`, so the same swap happens here instead: every
/// field left nil falls through to the base value, mirroring the way the UIKit
/// dictionary seeds itself from the base font and colour and only overrides the
/// keys the layout actually names.
///
/// The fields are the declared `highlightAttributes` keys. `font` splits into
/// `fontFamily` and `fontWeight` because UIKit resolves the literal name
/// `"bold"` to the bold system font rather than to a family.
public struct TextHighlightAttributes {
    public var fontFamily: String?
    public var fontSize: CGFloat?
    public var fontWeight: Font.Weight?
    public var fontColor: Color?
    public var lineHeightMultiple: CGFloat?
    public var textAlignment: TextAlignment?

    public init(
        fontFamily: String? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
        fontColor: Color? = nil,
        lineHeightMultiple: CGFloat? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontColor = fontColor
        self.lineHeightMultiple = lineHeightMultiple
        self.textAlignment = textAlignment
    }
}

/// A text component that supports partial text attributes
/// Used for all text rendering with support for partial styling
public struct PartialAttributedText: View {
    let text: String
    let partialAttributes: [PartialAttribute]
    let fontSize: CGFloat?
    let fontWeight: Font.Weight?
    let fontFamily: String?
    let fontColor: Color?
    let underline: Bool
    let strikethrough: Bool
    /// The object face's contents. Nil for the boolean face, which keeps the
    /// plain-line rendering it always had.
    let underlineDecoration: TextDecoration?
    let strikethroughDecoration: TextDecoration?
    let lineSpacing: CGFloat?
    let lineLimit: Int?
    let textAlignment: TextAlignment
    let linkable: Bool
    let highlightAttributes: TextHighlightAttributes?
    let isHighlighted: Bool

    public init(
        _ text: String,
        partialAttributes: [PartialAttribute] = [],
        fontSize: CGFloat? = nil,
        fontWeight: Font.Weight? = nil,
        fontFamily: String? = nil,
        fontColor: Color? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        underlineDecoration: TextDecoration? = nil,
        strikethroughDecoration: TextDecoration? = nil,
        lineSpacing: CGFloat? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment = .leading,
        linkable: Bool = false,
        highlightAttributes: TextHighlightAttributes? = nil,
        isHighlighted: Bool = false
    ) {
        self.text = text
        self.partialAttributes = partialAttributes
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontFamily = fontFamily
        self.fontColor = fontColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.underlineDecoration = underlineDecoration
        self.strikethroughDecoration = strikethroughDecoration
        self.lineSpacing = lineSpacing
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.linkable = linkable
        self.highlightAttributes = highlightAttributes
        self.isHighlighted = isHighlighted
    }

    /// Convenience initializer for generated code with string fontWeight
    public init(
        _ text: String,
        fontSize: CGFloat? = nil,
        fontWeight: String? = nil,
        fontFamily: String? = nil,
        fontColor: Color? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        underlineDecoration: TextDecoration? = nil,
        strikethroughDecoration: TextDecoration? = nil,
        lineSpacing: CGFloat? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment = .leading,
        linkable: Bool = false,
        highlightAttributes: TextHighlightAttributes? = nil,
        isHighlighted: Bool = false
    ) {
        self.text = text
        self.partialAttributes = []
        self.fontSize = fontSize
        self.fontWeight = fontWeight != nil ? Font.Weight.from(string: fontWeight!) : nil
        self.fontFamily = fontFamily
        self.fontColor = fontColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.underlineDecoration = underlineDecoration
        self.strikethroughDecoration = strikethroughDecoration
        self.lineSpacing = lineSpacing
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.linkable = linkable
        self.highlightAttributes = highlightAttributes
        self.isHighlighted = isHighlighted
    }

    /// Convenience initializer for backward compatibility with dictionary format
    public init(
        _ text: String,
        partialAttributesDict: [[String: Any]],
        fontSize: CGFloat? = nil,
        fontWeight: String? = nil,
        fontFamily: String? = nil,
        fontColor: Color? = nil,
        underline: Bool = false,
        strikethrough: Bool = false,
        underlineDecoration: TextDecoration? = nil,
        strikethroughDecoration: TextDecoration? = nil,
        lineSpacing: CGFloat? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment = .leading,
        linkable: Bool = false,
        highlightAttributes: TextHighlightAttributes? = nil,
        isHighlighted: Bool = false
    ) {
        self.text = text
        self.partialAttributes = partialAttributesDict.compactMap {
            PartialAttribute(from: $0)
        }
        self.fontSize = fontSize
        self.fontWeight = fontWeight != nil ? Font.Weight.from(string: fontWeight!) : nil
        self.fontFamily = fontFamily
        self.fontColor = fontColor
        self.underline = underline
        self.strikethrough = strikethrough
        self.underlineDecoration = underlineDecoration
        self.strikethroughDecoration = strikethroughDecoration
        self.lineSpacing = lineSpacing
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
        self.linkable = linkable
        self.highlightAttributes = highlightAttributes
        self.isHighlighted = isHighlighted
    }

    // MARK: - Highlight resolution
    //
    // Resolved once here rather than at each use so the two render paths below
    // (attributed and plain) cannot drift apart: a label with partialAttributes
    // has to honour the highlight swap exactly like one without.

    private var activeHighlight: TextHighlightAttributes? {
        isHighlighted ? highlightAttributes : nil
    }

    private var effectiveFontSize: CGFloat? {
        activeHighlight?.fontSize ?? fontSize
    }

    private var effectiveFontWeight: Font.Weight? {
        activeHighlight?.fontWeight ?? fontWeight
    }

    private var effectiveFontFamily: String? {
        activeHighlight?.fontFamily ?? fontFamily
    }

    private var effectiveFontColor: Color? {
        activeHighlight?.fontColor ?? fontColor
    }

    private var effectiveTextAlignment: TextAlignment {
        activeHighlight?.textAlignment ?? textAlignment
    }

    /// `lineHeightMultiple` is a multiple of the line height; SwiftUI takes the
    /// extra space between lines. The conversion needs the font size in force,
    /// which is why it happens here and not in the caller.
    private var effectiveLineSpacing: CGFloat? {
        guard let multiple = activeHighlight?.lineHeightMultiple else {
            return lineSpacing
        }
        let size = effectiveFontSize ?? SwiftJsonUIConfiguration.shared.font.size
        return max(0, (multiple - 1) * size)
    }

    public var body: some View {
        if !partialAttributes.isEmpty || linkable {
            let result = createAttributedStringWithMapping()
            Text(result.attributedString)
                .applyTextModifiers(
                    underline: underline,
                    strikethrough: strikethrough,
                    underlineDecoration: underlineDecoration,
                    strikethroughDecoration: strikethroughDecoration,
                    lineSpacing: effectiveLineSpacing,
                    lineLimit: lineLimit,
                    textAlignment: effectiveTextAlignment
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
        } else if needsUIKitLineStyle {
            // Double/Thick come from NSUnderlineStyle and SwiftUI's Text
            // cannot draw them (Text.LineStyle has solid/dot/dash patterns
            // only) — the body face bridges to the UILabel the vocabulary
            // was defined for. Partial/linkable bodies keep the SwiftUI
            // path: their Double/Thick stays single-weight there, the
            // remaining honest degradation.
            StyledLineText(
                text: text,
                font: uiKitFont,
                textColor: UIColor(effectiveFontColor ?? .primary),
                underline: (underline || underlineDecoration != nil) ? (underlineDecoration ?? TextDecoration()) : nil,
                strikethrough: (strikethrough || strikethroughDecoration != nil) ? (strikethroughDecoration ?? TextDecoration()) : nil,
                textAlignment: uiKitAlignment,
                numberOfLines: lineLimit ?? 0
            )
        } else {
            Text(text)
                .applyBaseFont(
                    fontSize: effectiveFontSize,
                    fontWeight: effectiveFontWeight,
                    fontFamily: effectiveFontFamily
                )
                .applyTextColor(effectiveFontColor)
                .applyTextModifiers(
                    underline: underline,
                    strikethrough: strikethrough,
                    underlineDecoration: underlineDecoration,
                    strikethroughDecoration: strikethroughDecoration,
                    lineSpacing: effectiveLineSpacing,
                    lineLimit: lineLimit,
                    textAlignment: effectiveTextAlignment
                )
        }
    }

    /// Whether a declared decoration needs the UIKit bridge (Double/Thick).
    private var needsUIKitLineStyle: Bool {
        underlineDecoration?.lineStyle == .double || underlineDecoration?.lineStyle == .thick ||
        strikethroughDecoration?.lineStyle == .double || strikethroughDecoration?.lineStyle == .thick
    }

    private var uiKitFont: UIFont {
        let size = effectiveFontSize ?? SwiftJsonUIConfiguration.shared.font.size
        if let family = effectiveFontFamily, let named = UIFont(name: family, size: size) {
            return named
        }
        let weight: UIFont.Weight = {
            switch effectiveFontWeight {
            case .bold: return .bold
            case .semibold: return .semibold
            case .medium: return .medium
            case .light: return .light
            case .thin: return .thin
            case .heavy: return .heavy
            case .black: return .black
            case .ultraLight: return .ultraLight
            default: return .regular
            }
        }()
        return .systemFont(ofSize: size, weight: weight)
    }

    private var uiKitAlignment: NSTextAlignment {
        switch effectiveTextAlignment {
        case .center: return .center
        case .trailing: return .right
        default: return .natural
        }
    }

    private func createAttributedStringWithMapping() -> (attributedString: AttributedString, urlMapping: [String: PartialAttribute]) {
        var attributedString = AttributedString(text)
        var urlMapping: [String: PartialAttribute] = [:]

        // Apply base styles to entire string.
        // fontFamily routes through the unified resolver so apps with a
        // `fontProvider` see the full FontSpec (family + weight + size).
        if let fontFamily = effectiveFontFamily {
            let size = effectiveFontSize ?? SwiftJsonUIConfiguration.shared.font.size
            attributedString.font = SwiftJsonUIConfiguration.shared.resolveFont(
                FontSpec(family: fontFamily, weight: effectiveFontWeight, size: size)
            )
        } else if let fontSize = effectiveFontSize, let fontWeight = effectiveFontWeight {
            attributedString.font = .system(size: fontSize, weight: fontWeight)
        } else if let fontSize = effectiveFontSize {
            attributedString.font = .system(size: fontSize)
        } else if let fontWeight = effectiveFontWeight {
            attributedString.font = .system(
                size: SwiftJsonUIConfiguration.shared.font.size,
                weight: fontWeight
            )
        }

        if let fontColor = effectiveFontColor {
            attributedString.foregroundColor = fontColor
        }

        // If linkable is true, detect URLs and make them clickable
        if linkable {
            detectAndApplyLinks(&attributedString)
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
                let size = effectiveFontSize ?? SwiftJsonUIConfiguration.shared.font.size
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

    private func detectAndApplyLinks(_ attributedString: inout AttributedString) {
        // Detect URLs, phone numbers, and email addresses in the text
        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        let detector = try? NSDataDetector(types: types.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []

        for match in matches {
            if let range = Range(match.range, in: text) {
                var url: URL?

                switch match.resultType {
                case .link:
                    url = match.url
                    #if DEBUG
                    if let url = url {
                        print("[PartialAttributedText] Detected link: \(url.absoluteString)")
                    }
                    #endif
                case .phoneNumber:
                    if let phoneNumber = match.phoneNumber {
                        // Remove spaces and special characters for tel: URL
                        let cleanedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: "-", with: "")
                            .replacingOccurrences(of: "(", with: "")
                            .replacingOccurrences(of: ")", with: "")
                        url = URL(string: "tel:\(cleanedNumber)")
                        #if DEBUG
                        print("[PartialAttributedText] Detected phone: \(phoneNumber) -> tel:\(cleanedNumber)")
                        #endif
                    }
                default:
                    break
                }

                if let url = url {
                    // Convert String range to AttributedString range
                    let startIndex = text.index(text.startIndex, offsetBy: range.lowerBound.utf16Offset(in: text))
                    let endIndex = text.index(text.startIndex, offsetBy: range.upperBound.utf16Offset(in: text))

                    if let attrStartIndex = AttributedString.Index(startIndex, within: attributedString),
                       let attrEndIndex = AttributedString.Index(endIndex, within: attributedString),
                       attrStartIndex < attrEndIndex {
                        let attrRange = attrStartIndex..<attrEndIndex
                        attributedString[attrRange].link = url
                        attributedString[attrRange].underlineStyle = .single
                    }
                }
            }
        }
    }
}

// MARK: - View Extensions for Text modifiers
extension View {
    func applyBaseFont(fontSize: CGFloat?, fontWeight: Font.Weight?, fontFamily: String? = nil) -> some View {
        self.modifier(BaseFontModifier(fontSize: fontSize, fontWeight: fontWeight, fontFamily: fontFamily))
    }

    func applyTextColor(_ color: Color?) -> some View {
        self.modifier(TextColorModifier(color: color))
    }

    func applyTextModifiers(
        underline: Bool,
        strikethrough: Bool,
        underlineDecoration: TextDecoration? = nil,
        strikethroughDecoration: TextDecoration? = nil,
        lineSpacing: CGFloat?,
        lineLimit: Int?,
        textAlignment: TextAlignment
    ) -> some View {
        // The declared colour reaches the rule through the text-styling
        // modifiers themselves; `nil` is SwiftUI's "inherit the foreground",
        // which is exactly the plain-line rendering the boolean face had.
        // `lineOffset` is UIKit's `baselineOffset` — it shifts the text
        // relative to its line box (SJUILabel.swift:452), not the rule.
        self
            .underline(underline, color: underlineDecoration?.color)
            .strikethrough(strikethrough, color: strikethroughDecoration?.color)
            .baselineOffset(underlineDecoration?.lineOffset ?? 0)
            .lineSpacing(lineSpacing ?? 0)
            .lineLimit(lineLimit)
            .multilineTextAlignment(textAlignment)
    }
}

struct BaseFontModifier: ViewModifier {
    let fontSize: CGFloat?
    let fontWeight: Font.Weight?
    let fontFamily: String?

    init(fontSize: CGFloat?, fontWeight: Font.Weight?, fontFamily: String? = nil) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontFamily = fontFamily
    }

    func body(content: Content) -> some View {
        if let fontFamily = fontFamily {
            // fontFamily specified: route through the unified FontSpec resolver
            // so apps with a `fontProvider` see family + weight + size together.
            let size = fontSize ?? SwiftJsonUIConfiguration.shared.font.size
            content.font(
                SwiftJsonUIConfiguration.shared.resolveFont(
                    FontSpec(family: fontFamily, weight: fontWeight, size: size)
                )
            )
        } else if let fontSize = fontSize, let fontWeight = fontWeight {
            // Both fontSize and fontWeight specified
            content.font(.system(size: fontSize, weight: fontWeight))
        } else if let fontSize = fontSize {
            // Only fontSize specified
            content.font(.system(size: fontSize))
        } else if let fontWeight = fontWeight {
            // Only fontWeight specified - use default size from configuration
            content.font(.system(size: SwiftJsonUIConfiguration.shared.font.size, weight: fontWeight))
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
