//
//  LabelConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of label_converter.rb
//  Creates PartialAttributedText matching tool-generated code exactly.
//
//  Modifier order (matches label_converter.rb):
//    1. PartialAttributedText(...)
//    2. .truncationMode (lineBreakMode)
//    3. .minimumScaleFactor (autoShrink)
//    4. .padding (edgeInset - internal label padding)
//    5. weight frame (.frame(maxWidth: .infinity))
//    6. apply_padding (paddings/paddingTop etc.)
//    7. apply_frame_size (width/height)
//    8. apply_frame_constraints (minWidth/maxWidth/minHeight/maxHeight)
//    9. .background
//   10. .cornerRadius
//   11. apply_margins
//   12. .opacity / .hidden / .disabled
//   13. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct LabelConverter {

    /// Convert DynamicComponent to SwiftUI PartialAttributedText
    /// Matches label_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        parentOrientation: String? = nil
    ) -> AnyView {
        let attrs = component.typedAttributes(LabelAttributes.self)
        // --- 1. Build PartialAttributedText ---
        let processedText = DynamicHelpers.processText(
            attrs.text?.rawRepresentation as? String, data: data
        ) ?? ""

        // hint / hintAttributes — the Label placeholder. UIKit's SJUILabel
        // swaps in the styled hint when the text is empty and requires BOTH
        // keys; `placeholder` is the declared alias of `hint`, and
        // hintAttributes.fontColor wins over the flat hintColor. Nothing on
        // this path read any of it, so a Label carrying only a hint rendered
        // empty while the generated code rendered the hint
        // (label_converter.rb#label_hint_config).
        let hint = labelHint(component: component, attrs: attrs, data: data)
        let showsHint = hint != nil && processedText.isEmpty
        let text = (showsHint ? hint!.text : processedText).dynamicLocalized()

        // Build partialAttributes from component if present
        let partialAttributes = buildPartialAttributes(component: component, data: data)

        // Font properties. The hint carries its own size and colour while it
        // is showing — that is the whole point of hintAttributes.
        let fontSize = showsHint
            ? (hint?.size ?? DynamicHelpers.resolveNumber(attrs.fontSize, legacy: nil, data: data))
            : DynamicHelpers.resolveNumber(attrs.fontSize, legacy: nil, data: data)
        // Resolve font from binding if present (e.g., @{fontProp})
        let resolvedFont: String? = {
            if let expr = attrs.font?.bindingExpression {
                // Canonical string value context (Binding<String> unwraps)
                if let fontString = DynamicBindingResolver.resolveString(expression: expr, data: data) {
                    return fontString
                }
            }
            return attrs.font?.rawRepresentation as? String
        }()
        let fontWeight: String? = {
            if let fw = component.fontWeightSpelling() { return fw }
            guard let font = resolvedFont?.lowercased() else { return nil }
            let weightNames = ["bold", "semibold", "medium", "light", "thin", "ultralight", "heavy", "black", "normal", "regular"]
            return weightNames.contains(font) ? font : nil
        }()

        // fontColor with binding support
        let fontColor: Color? = {
            if component.commonBool(\.enabled) == false,
               let disabledColor = component.string(ButtonAttributes.self, \.disabledFontColor) {
                return DynamicHelpers.getColor(disabledColor, data: data)
            }
            if showsHint, let hintColor = hint?.color { return hintColor }
            return DynamicHelpers.getColor(attrs.fontColor?.rawRepresentation as? String, data: data)
        }()

        // lineSpacing — UIKit's formula, `(multiple - 1) * fontSize`, with
        // either operand possibly bound (label_converter.rb
        // #line_spacing_from_multiple resolves both). Every operand here read
        // a hand-decoded slot, which is nil for `@{expr}`: a bound multiple
        // produced no spacing at all, and a bound fontSize silently fell back
        // to 17 and skewed the arithmetic for a static multiple.
        let lineSpacing: CGFloat? = {
            if let multiple = DynamicHelpers.resolveNumber(
                attrs.lineHeightMultiple, legacy: nil, data: data
            ) {
                return (multiple - 1) * (fontSize ?? 17)
            }
            return DynamicHelpers.resolveNumber(
                attrs.lineSpacing, legacy: nil, data: data
            )
        }()

        // lineLimit
        let resolvedLines = DynamicHelpers.resolveNumber(
            attrs.lines, legacy: nil, data: data
        ).map { Int($0) }
        let lineLimit: Int? = {
            if let lines = resolvedLines {
                return lines == 0 ? nil : lines
            }
            if component.autoShrink == true {
                return 1
            }
            return nil  // nil means no lineLimit specified
        }()
        let hasLineLimit = resolvedLines != nil || component.autoShrink == true

        // textAlignment
        let textAlignment = DynamicHelpers.getTextAlignment(from: component)

        // linkable
        let linkable = DynamicHelpers.resolveBool(
            attrs.linkable, legacy: nil, data: data
        ) == true

        let fontWeightValue: Font.Weight? = fontWeight.flatMap { Font.Weight.from(string: $0) }

        // fontFamily with binding support
        let fontFamily: String? = {
            if let expr = attrs.fontFamily?.bindingExpression {
                // Canonical string value context (Binding<String> unwraps)
                if let family = DynamicBindingResolver.resolveString(expression: expr, data: data) {
                    return family
                }
                return nil
            }
            return attrs.fontFamily?.rawRepresentation as? String
        }()

        // highlightAttributes / highlightColor, driven by `selected`
        let highlight = buildHighlight(component: component, attrs: attrs, data: data)
        let isHighlighted = DynamicHelpers.resolveBool(attrs.selected, legacy: nil, data: data) ?? false

        var result = AnyView(
            PartialAttributedText(
                text,
                partialAttributes: partialAttributes ?? [],
                fontSize: fontSize,
                fontWeight: fontWeightValue,
                fontFamily: fontFamily,
                fontColor: fontColor,
                underline: component.decorationFlag(\.underline),
                strikethrough: component.decorationFlag(\.strikethrough),
                underlineDecoration: component.decorationStyle(\.underline, data: data),
                strikethroughDecoration: component.decorationStyle(\.strikethrough, data: data),
                lineSpacing: lineSpacing,
                lineLimit: hasLineLimit ? lineLimit : nil,
                textAlignment: textAlignment,
                linkable: linkable,
                highlightAttributes: highlight,
                isHighlighted: isHighlighted
            )
        )

        // --- 2. truncationMode (lineBreakMode) ---
        if let lineBreakMode = component.lineBreakMode {
            let mode: Text.TruncationMode? = {
                switch lineBreakMode {
                case "Head": return .head
                case "Middle": return .middle
                case "Tail", "Clip": return .tail
                default: return nil
                }
            }()
            if let mode = mode {
                result = AnyView(result.truncationMode(mode))
            }
        }

        // --- 3. minimumScaleFactor (autoShrink) ---
        let resolvedScaleFactor = DynamicHelpers.resolveNumber(
            attrs.minimumScaleFactor, legacy: nil, data: data
        )
        if component.autoShrink == true {
            result = AnyView(result.minimumScaleFactor(resolvedScaleFactor ?? 0.5))
        } else if let scaleFactor = resolvedScaleFactor {
            result = AnyView(result.minimumScaleFactor(scaleFactor))
        }

        // --- 4. edgeInset (internal label padding) ---
        if let edgeInset = component.edgeInset {
            result = AnyView(result.padding(parseEdgeInset(edgeInset)))
        }

        // --- 5. weight frame ---
        // weight is number|binding — resolve a `@{binding}` from data.
        if let weight = DynamicHelpers.resolveWeight(from: component, data: data), weight > 0 {
            let effectiveOrientation = parentOrientation
                ?? component.rawAttribute("parent_orientation") as? String
            if effectiveOrientation == "horizontal" {
                // Map textAlign to frame alignment
                let frameAlignment: Alignment = {
                    switch component.textAlignSpelling(data: data)?.lowercased() {
                    case "center": return .center
                    case "right", "trailing": return .trailing
                    default: return .leading
                    }
                }()
                result = AnyView(result.frame(maxWidth: CGFloat.infinity, alignment: frameAlignment))
            } else if effectiveOrientation == "vertical" {
                result = AnyView(result.frame(maxHeight: CGFloat.infinity))
            }
        }

        // --- 6. apply_padding (paddings/paddingTop etc.) ---
        result = DynamicModifierHelper.applyPadding(result, component: component, data: data)

        // --- 7. apply_frame_size (width/height) ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 8. apply_frame_constraints (minWidth/maxWidth etc.) ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component, data: data)

        // --- 9. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 10. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component, data: data)

        // --- 10b. textShadow — { color:, blur:, offset: [x, y] } (or a bare
        // color string, UIKit default 1pt blur). Mirrors label_converter.rb
        // apply_text_shadow; the dynamic path never read it (33 cross-effect:
        // ios rendered flat for a declared shadow).
        if let shadow = attrs.textShadow {
            if let colorName = shadow as? String,
               let color = DynamicHelpers.getColor(colorName) {
                result = AnyView(result.shadow(color: color, radius: 1, x: 0, y: 1))
            } else if let dict = shadow as? [String: Any] {
                let color = (dict["color"] as? String).flatMap { DynamicHelpers.getColor($0) }
                    ?? Color.black.opacity(0.3)
                let blur = (dict["blur"] as? Double) ?? (dict["blur"] as? Int).map(Double.init) ?? 1
                var x: Double = 0, y: Double = 1
                if let offset = dict["offset"] as? [Any], offset.count >= 2 {
                    x = (offset[0] as? Double) ?? (offset[0] as? Int).map(Double.init) ?? 0
                    y = (offset[1] as? Double) ?? (offset[1] as? Int).map(Double.init) ?? 1
                }
                result = AnyView(result.shadow(color: color, radius: blur, x: x, y: y))
            }
        }

        // --- 11. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 12. opacity / hidden / disabled ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)
        result = DynamicModifierHelper.applyDisabled(result, component: component, data: data)

        // --- 13. onClick ---
        result = DynamicEventHelper.applyOnClick(result, component: component, data: data)

        // --- 14. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }

    // MARK: - Highlight builder

    /// `highlightAttributes` / `highlightColor` -> the styling that takes over
    /// while `selected` is true.
    ///
    /// Mirrors `label_converter.rb#emit_highlight_attributes` and, through it,
    /// the UIKit precedence in SJUILabel's creator: a non-empty attribute object
    /// wins, an object with no recognised key falls through to `highlightColor`.
    private static func buildHighlight(
        component: DynamicComponent,
        attrs: LabelAttributes,
        data: [String: Any]
    ) -> TextHighlightAttributes? {
        var highlight = TextHighlightAttributes()
        var recognised = false

        if let dict = attrs.highlightAttributes {
            if let font = dict["font"] as? String {
                // UIKit resolves the literal name "bold" to the bold system
                // font rather than to a family.
                if font.lowercased() == "bold" {
                    highlight.fontWeight = .bold
                } else {
                    highlight.fontFamily = font
                }
                recognised = true
            }
            if let size = dict["fontSize"] as? NSNumber {
                highlight.fontSize = CGFloat(size.doubleValue)
                recognised = true
            }
            if let color = dict["fontColor"] as? String,
               let resolved = DynamicHelpers.getColor(color, data: data) {
                highlight.fontColor = resolved
                recognised = true
            }
            if let multiple = dict["lineHeightMultiple"] as? NSNumber {
                highlight.lineHeightMultiple = CGFloat(multiple.doubleValue)
                recognised = true
            }
            if let align = dict["textAlign"] as? String {
                switch align.lowercased() {
                case "left": highlight.textAlignment = .leading
                case "center": highlight.textAlignment = .center
                case "right": highlight.textAlignment = .trailing
                default: break
                }
                recognised = highlight.textAlignment != nil || recognised
            }
        }

        if recognised {
            return highlight
        }
        if let color = DynamicHelpers.getColor(
            attrs.highlightColor?.rawRepresentation as? String, data: data
        ) {
            return TextHighlightAttributes(fontColor: color)
        }
        return nil
    }

    // MARK: - PartialAttributes builder

    private static func buildPartialAttributes(
        component: DynamicComponent,
        data: [String: Any]
    ) -> [PartialAttribute]? {
        guard let rawAttrs = component.partialAttributes,
              let attrsArray = rawAttrs.value as? [[String: Any]], !attrsArray.isEmpty else {
            return nil
        }
        return attrsArray.compactMap { dict -> PartialAttribute? in
            // Resolve onClick closure from data dictionary
            var onClickClosure: (() -> Void)? = nil
            if let onClick = dict["onclick"] as? String ?? dict["onClick"] as? String {
                let propName = DynamicEventHelper.extractPropertyName(from: onClick) ?? onClick
                onClickClosure = data[propName] as? () -> Void
            }

            // Parse fontSize from CGFloat or Int
            var fontSize: CGFloat? = nil
            if let fs = dict["fontSize"] as? CGFloat {
                fontSize = fs
            } else if let fs = dict["fontSize"] as? Int {
                fontSize = CGFloat(fs)
            }

            // Parse fontWeight
            var fontWeight: Font.Weight? = nil
            if let fw = dict["fontWeight"] as? String {
                fontWeight = Font.Weight.from(string: fw)
            }

            // Use range-based or textPattern-based init
            if let rangeArray = dict["range"] as? [Int], rangeArray.count == 2, rangeArray[0] < rangeArray[1] {
                return PartialAttribute(
                    range: rangeArray[0]..<rangeArray[1],
                    fontColor: (dict["fontColor"] as? String).flatMap { DynamicHelpers.getColor($0) },
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    underline: dict["underline"] as? Bool ?? false,
                    strikethrough: dict["strikethrough"] as? Bool ?? false,
                    backgroundColor: (dict["background"] as? String).flatMap { DynamicHelpers.getColor($0) },
                    onClick: onClickClosure,
                    onClickActionName: dict["onclick"] as? String ?? dict["onClick"] as? String
                )
            } else if let pattern = dict["range"] as? String {
                return PartialAttribute(
                    textPattern: pattern.dynamicLocalized(),
                    fontColor: (dict["fontColor"] as? String).flatMap { DynamicHelpers.getColor($0) },
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    underline: dict["underline"] as? Bool ?? false,
                    strikethrough: dict["strikethrough"] as? Bool ?? false,
                    backgroundColor: (dict["background"] as? String).flatMap { DynamicHelpers.getColor($0) },
                    onClick: onClickClosure,
                    onClickActionName: dict["onclick"] as? String ?? dict["onClick"] as? String
                )
            } else {
                return nil
            }
        }
    }

    // MARK: - Edge Inset Parser

    /// Parse edgeInset from AnyCodable (single value, array [top,right,bottom,left], or pipe-separated string)
    /// The Label placeholder: text, and the size/colour it carries.
    ///
    /// Both keys are required, matching `label_converter.rb#label_hint_config`
    /// and UIKit's SJUILabel — a bare `hint` with no `hintAttributes` is not a
    /// placeholder. `placeholder` is the declared alias of `hint`, and the
    /// nested `hintAttributes.fontColor` wins over the flat `hintColor`, which
    /// is the cascade adjudicated for TextField's hintAttributes.
    static func labelHint(
        component: DynamicComponent,
        attrs: LabelAttributes,
        data: [String: Any]
    ) -> (text: String, color: Color?, size: CGFloat?)? {
        guard let nested = attrs.hintAttributes,
              let raw = attrs.hint ?? component.placeholder,
              !raw.isEmpty else { return nil }

        let colorSpelling = (nested["fontColor"] as? String)
            ?? (attrs.hintColor?.rawRepresentation as? String)
        let size = (nested["fontSize"] as? Double).map { CGFloat($0) }
            ?? (nested["fontSize"] as? Int).map { CGFloat($0) }

        return (
            text: DynamicHelpers.processText(raw, data: data),
            color: DynamicHelpers.getColor(colorSpelling, data: data),
            size: size
        )
    }

    private static func parseEdgeInset(_ edgeInset: AnyCodable) -> EdgeInsets {
        let value = edgeInset.value

        // Single numeric value
        if let single = value as? CGFloat {
            return EdgeInsets(top: single, leading: single, bottom: single, trailing: single)
        }
        if let single = value as? Double {
            let v = CGFloat(single)
            return EdgeInsets(top: v, leading: v, bottom: v, trailing: v)
        }
        if let single = value as? Int {
            let v = CGFloat(single)
            return EdgeInsets(top: v, leading: v, bottom: v, trailing: v)
        }

        // Array format [top, right, bottom, left] (UIKit order)
        if let array = value as? [Any] {
            let values = array.compactMap { item -> CGFloat? in
                if let d = item as? Double { return CGFloat(d) }
                if let i = item as? Int { return CGFloat(i) }
                if let f = item as? CGFloat { return f }
                return nil
            }
            switch values.count {
            case 1:
                return EdgeInsets(top: values[0], leading: values[0], bottom: values[0], trailing: values[0])
            case 2:
                return EdgeInsets(top: values[0], leading: values[1], bottom: values[0], trailing: values[1])
            case 3:
                return EdgeInsets(top: values[0], leading: values[1], bottom: values[2], trailing: values[1])
            case 4:
                // UIKit order: [top, right, bottom, left] -> SwiftUI: [top, leading(=left), bottom, trailing(=right)]
                return EdgeInsets(top: values[0], leading: values[3], bottom: values[2], trailing: values[1])
            default:
                return EdgeInsets()
            }
        }

        // Pipe-separated string "top|right|bottom|left"
        if let str = value as? String, str.contains("|") {
            let parts = str.split(separator: "|").compactMap { CGFloat(Double($0) ?? 0) }
            switch parts.count {
            case 1:
                return EdgeInsets(top: parts[0], leading: parts[0], bottom: parts[0], trailing: parts[0])
            case 2:
                return EdgeInsets(top: parts[0], leading: parts[1], bottom: parts[0], trailing: parts[1])
            case 3:
                return EdgeInsets(top: parts[0], leading: parts[1], bottom: parts[2], trailing: parts[1])
            case 4:
                return EdgeInsets(top: parts[0], leading: parts[3], bottom: parts[2], trailing: parts[1])
            default:
                return EdgeInsets()
            }
        }

        return EdgeInsets()
    }
}
#endif // DEBUG
