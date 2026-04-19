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
        // --- 1. Build PartialAttributedText ---
        let processedText = DynamicHelpers.processText(component.text, data: data) ?? ""
        let text = processedText.dynamicLocalized()

        // Build partialAttributes from component if present
        let partialAttributes = buildPartialAttributes(component: component, data: data)

        // Font properties
        let fontSize = component.fontSize
        // Resolve font from binding if present (e.g., @{fontProp})
        let resolvedFont: String? = {
            if let fontRaw = component.rawData["font"] as? String,
               fontRaw.hasPrefix("@{") && fontRaw.hasSuffix("}") {
                let propertyName = String(fontRaw.dropFirst(2).dropLast(1))
                if let binding = data[propertyName] as? SwiftUI.Binding<String> {
                    return binding.wrappedValue
                }
                if let fontString = data[propertyName] as? String {
                    return fontString
                }
            }
            return component.font
        }()
        let fontWeight: String? = {
            if let fw = component.fontWeight { return fw }
            guard let font = resolvedFont?.lowercased() else { return nil }
            let weightNames = ["bold", "semibold", "medium", "light", "thin", "ultralight", "heavy", "black", "normal", "regular"]
            return weightNames.contains(font) ? font : nil
        }()

        // fontColor with binding support
        let fontColor: Color? = {
            if component.enabled?.value as? Bool == false, let disabledColor = component.disabledFontColor {
                return DynamicHelpers.getColor(disabledColor, data: data)
            }
            return DynamicHelpers.getColor(component.fontColor, data: data)
        }()

        // lineSpacing
        let lineSpacing: CGFloat? = {
            if let lineHeightMultiple = component.lineHeightMultiple {
                return (CGFloat(lineHeightMultiple) - 1) * CGFloat(component.fontSize ?? 17)
            }
            return component.lineSpacing
        }()

        // lineLimit
        let lineLimit: Int? = {
            if let lines = component.lines {
                return lines == 0 ? nil : lines
            }
            if component.autoShrink == true {
                return 1
            }
            return nil  // nil means no lineLimit specified
        }()
        let hasLineLimit = component.lines != nil || component.autoShrink == true

        // textAlignment
        let textAlignment = DynamicHelpers.getTextAlignment(from: component)

        // linkable
        let linkable = component.linkable == true

        let fontWeightValue: Font.Weight? = fontWeight.flatMap { Font.Weight.from(string: $0) }

        // fontFamily with binding support
        let fontFamily: String? = {
            if let raw = component.rawData["fontFamily"] as? String,
               raw.hasPrefix("@{") && raw.hasSuffix("}") {
                let propertyName = String(raw.dropFirst(2).dropLast(1))
                if let binding = data[propertyName] as? SwiftUI.Binding<String> {
                    return binding.wrappedValue
                }
                return data[propertyName] as? String
            }
            return component.fontFamily
        }()

        var result = AnyView(
            PartialAttributedText(
                text,
                partialAttributes: partialAttributes ?? [],
                fontSize: fontSize,
                fontWeight: fontWeightValue,
                fontFamily: fontFamily,
                fontColor: fontColor,
                underline: component.underline ?? false,
                strikethrough: component.strikethrough ?? false,
                lineSpacing: lineSpacing,
                lineLimit: hasLineLimit ? lineLimit : nil,
                textAlignment: textAlignment,
                linkable: linkable
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
        if component.autoShrink == true {
            let scaleFactor = component.minimumScaleFactor ?? 0.5
            result = AnyView(result.minimumScaleFactor(CGFloat(scaleFactor)))
        } else if let scaleFactor = component.minimumScaleFactor {
            result = AnyView(result.minimumScaleFactor(CGFloat(scaleFactor)))
        }

        // --- 4. edgeInset (internal label padding) ---
        if let edgeInset = component.edgeInset {
            result = AnyView(result.padding(parseEdgeInset(edgeInset)))
        }

        // --- 5. weight frame ---
        if let weight = component.weight, weight > 0 {
            let effectiveOrientation = parentOrientation ?? component.rawData["parent_orientation"] as? String
            if effectiveOrientation == "horizontal" {
                // Map textAlign to frame alignment
                let frameAlignment: Alignment = {
                    switch component.textAlign {
                    case "center": return .center
                    case "right": return .trailing
                    default: return .leading
                    }
                }()
                result = AnyView(result.frame(maxWidth: CGFloat.infinity, alignment: frameAlignment))
            } else if effectiveOrientation == "vertical" {
                result = AnyView(result.frame(maxHeight: CGFloat.infinity))
            }
        }

        // --- 6. apply_padding (paddings/paddingTop etc.) ---
        result = DynamicModifierHelper.applyPadding(result, component: component)

        // --- 7. apply_frame_size (width/height) ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 8. apply_frame_constraints (minWidth/maxWidth etc.) ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)

        // --- 9. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 10. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component)

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
