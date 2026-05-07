//
//  TextConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Text view (plain text, no PartialAttributedText).
//  For rich text / partialAttributes, use LabelConverter instead.
//
//  This converter is intended for simple "Text" type components that don't need
//  PartialAttributedText features. In practice, DynamicComponentBuilder routes both
//  "text" and "label" to LabelConverter, so TextConverter is available for
//  custom component adapters or future routing changes.
//
//  Modifier order (matches label_converter.rb for consistency):
//    1. Text(...) with font, foregroundColor, multilineTextAlignment
//    2. .truncationMode (lineBreakMode)
//    3. .minimumScaleFactor (autoShrink)
//    4. .padding (edgeInset - internal text padding)
//    5. weight frame (.frame(maxWidth/maxHeight: .infinity))
//    6. padding (paddings / paddingTop etc.)
//    7. frame_size (width / height)
//    8. frame_constraints (minWidth / maxWidth / minHeight / maxHeight)
//    9. background
//   10. cornerRadius
//   11. margins
//   12. opacity
//   13. hidden
//   14. disabled
//   15. onClick
//   16. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct TextConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        parentOrientation: String? = nil
    ) -> AnyView {
        let processedText = DynamicHelpers.processText(component.text, data: data)
        let text = processedText.dynamicLocalized()
        let textColor = DynamicHelpers.getColor(component.fontColor, data: data) ?? .primary
        let alignment = DynamicHelpers.getTextAlignment(from: component)

        // --- 1. Text view with font, color, alignment ---
        var result: AnyView
        if let font = DynamicHelpers.fontFromComponent(component, data: data) {
            result = AnyView(
                Text(text)
                    .font(font)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(alignment)
            )
        } else {
            result = AnyView(
                Text(text)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(alignment)
            )
        }

        // lineLimit
        if let lines = component.lines {
            if lines == 0 {
                result = AnyView(result.lineLimit(nil))
            } else {
                result = AnyView(result.lineLimit(lines))
            }
        } else if component.autoShrink == true {
            result = AnyView(result.lineLimit(1))
        }

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

        // --- 4. edgeInset (internal text padding) ---
        if let edgeInset = component.edgeInset {
            result = AnyView(result.padding(parseEdgeInset(edgeInset)))
        }

        // --- 5. weight frame ---
        if let weight = component.weight, weight > 0 {
            let effectiveOrientation = parentOrientation
            if effectiveOrientation == "horizontal" {
                // Map textAlign to frame alignment
                let frameAlignment: Alignment = {
                    switch component.textAlign {
                    case "center": return .center
                    case "right": return .trailing
                    default: return .leading
                    }
                }()
                result = AnyView(result.frame(maxWidth: .infinity, alignment: frameAlignment))
            } else if effectiveOrientation == "vertical" {
                result = AnyView(result.frame(maxHeight: .infinity))
            } else {
                // Default: treat as horizontal for weight
                result = AnyView(result.frame(maxWidth: .infinity))
            }
        }

        // --- 6. padding (paddings / paddingTop etc.) ---
        result = DynamicModifierHelper.applyPadding(result, component: component)

        // --- 7. frame_size (width / height) ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 8. frame_constraints (minWidth / maxWidth / minHeight / maxHeight) ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)

        // --- 9. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 10. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component)

        // --- 11. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 12. opacity ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)

        // --- 13. hidden ---
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 14. disabled ---
        result = DynamicModifierHelper.applyDisabled(result, component: component, data: data)

        // --- 15. onClick ---
        result = DynamicEventHelper.applyOnClick(result, component: component, data: data)

        // --- 16. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }

    // MARK: - Edge Inset Parser

    /// Parse edgeInset from AnyCodable (single value, array [top,right,bottom,left], or pipe-separated string)
    /// UIKit compatible: supports [top, right, bottom, left] order
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
