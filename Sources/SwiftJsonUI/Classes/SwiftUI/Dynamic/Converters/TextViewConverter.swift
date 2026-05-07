//
//  TextViewConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of textview_converter.rb
//  Creates TextViewWithPlaceholder matching tool-generated code exactly.
//
//  Modifier order (matches textview_converter.rb):
//    1. TextViewWithPlaceholder(...) creation
//       - text binding, hint, hintAttributes (hintColor, hintFont, hintFontSize, hintLineHeightMultiple)
//       - hideOnFocused, fontSize, fontColor, font, backgroundColor, cornerRadius
//       - containerInset (paddings used as containerInset), flexible, minHeight, maxHeight
//    2. .onChange (onTextChange)
//    3. flexible: frame(minHeight/maxHeight) OR apply_frame_constraints + apply_frame_size
//    4. .overlay (border)
//    5. apply_margins
//    6. .opacity / .hidden
//    7. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct TextViewConverter {

    /// Convert DynamicComponent to SwiftUI TextViewWithPlaceholder
    /// Matches textview_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let id = component.id ?? "textEditor"

        // --- 1. Build TextViewWithPlaceholder ---

        // Text binding
        let textBinding = DynamicBindingHelper.string(component.text, data: data)

        // hint (placeholder) - hint takes priority, fallback to placeholder
        let hint: String? = {
            if let h = component.hint ?? component.placeholder {
                if let propName = DynamicEventHelper.extractPropertyName(from: h) {
                    if let binding = data[propName] as? SwiftUI.Binding<String> {
                        return binding.wrappedValue
                    }
                    if let value = data[propName] as? String {
                        return value
                    }
                }
                return h.dynamicLocalized()
            }
            return nil
        }()

        // hintColor - from hintAttributes or individual property
        let hintColor: Color = {
            if let hintAttrs = component.hintAttributes?.value as? [String: Any] {
                if let fc = hintAttrs["fontColor"] as? String ?? hintAttrs["color"] as? String {
                    return DynamicHelpers.getColor(fc) ?? Color.gray.opacity(0.6)
                }
            }
            if let hc = component.hintColor {
                return DynamicHelpers.getColor(hc) ?? Color.gray.opacity(0.6)
            }
            return Color.gray.opacity(0.6)
        }()

        // hintFont - from hintAttributes or individual property
        let hintFont: String? = {
            if let hintAttrs = component.hintAttributes?.value as? [String: Any] {
                if let f = hintAttrs["font"] as? String { return f }
            }
            return component.hintFont
        }()

        // hintFontSize - from hintAttributes or individual property
        let hintFontSize: CGFloat? = {
            if let hintAttrs = component.hintAttributes?.value as? [String: Any] {
                if let fs = hintAttrs["fontSize"] as? CGFloat { return fs }
                if let fs = hintAttrs["fontSize"] as? Double { return CGFloat(fs) }
                if let fs = hintAttrs["fontSize"] as? Int { return CGFloat(fs) }
            }
            return component.hintFontSize
        }()

        // hintLineHeightMultiple - from hintAttributes or individual property
        let hintLineHeightMultiple: CGFloat? = {
            if let hintAttrs = component.hintAttributes?.value as? [String: Any] {
                if let lhm = hintAttrs["lineHeightMultiple"] as? CGFloat { return lhm }
                if let lhm = hintAttrs["lineHeightMultiple"] as? Double { return CGFloat(lhm) }
            }
            return component.hintLineHeightMultiple
        }()

        // hideOnFocused
        let hideOnFocused = component.hideOnFocused ?? true

        // fontSize
        let fontSize = component.fontSize ?? 16

        // fontColor
        let fontColor: Color = {
            if let fc = component.fontColor {
                return DynamicHelpers.getColor(fc) ?? .primary
            }
            return .primary
        }()

        // font (fontName)
        let fontName = component.font

        // backgroundColor
        let backgroundColor: Color = {
            if let bg = component.background {
                return DynamicHelpers.getColor(bg) ?? Color(UIColor.systemBackground)
            }
            return Color(UIColor.systemBackground)
        }()

        // cornerRadius
        let cornerRadius = component.cornerRadius ?? 0

        // containerInset (paddings used as containerInset for TextView)
        let containerInset: EdgeInsets = {
            if let ci = component.containerInset {
                switch ci.count {
                case 1:
                    return EdgeInsets(top: ci[0], leading: ci[0], bottom: ci[0], trailing: ci[0])
                case 2:
                    return EdgeInsets(top: ci[0], leading: ci[1], bottom: ci[0], trailing: ci[1])
                case 4:
                    return EdgeInsets(top: ci[0], leading: ci[1], bottom: ci[2], trailing: ci[3])
                default:
                    return EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5)
                }
            }
            // Fallback: use paddings as containerInset
            let padding = DynamicHelpers.getPadding(from: component)
            if padding.top != 0 || padding.leading != 0 || padding.bottom != 0 || padding.trailing != 0 {
                return padding
            }
            return EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5)
        }()

        // flexible
        let flexible = component.flexible ?? false

        // minHeight / maxHeight
        let minHeight = component.minHeight
        let maxHeight = component.maxHeight

        var result = AnyView(
            TextViewWithPlaceholder(
                text: textBinding,
                hint: hint,
                hintColor: hintColor,
                hintFont: hintFont,
                hintFontSize: hintFontSize,
                hintLineHeightMultiple: hintLineHeightMultiple,
                hideOnFocused: hideOnFocused,
                fontSize: fontSize,
                fontColor: fontColor,
                fontName: fontName,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                containerInset: containerInset,
                flexible: flexible,
                minHeight: minHeight,
                maxHeight: maxHeight
            )
        )

        // --- 2. .onChange (onTextChange) ---
        if let onTextChange = component.onTextChange,
           let propName = DynamicEventHelper.extractPropertyName(from: component.text) {
            result = AnyView(
                result.onChange(of: textBinding.wrappedValue) { _, newValue in
                    DynamicEventHelper.callWithValue(onTextChange, id: id, value: newValue, data: data)
                }
            )
        }

        // --- 3. Frame modifiers ---
        if flexible {
            // For flexible TextViews, apply minHeight/maxHeight as frame
            if let minH = minHeight, let maxH = maxHeight {
                result = AnyView(result.frame(minHeight: minH, maxHeight: maxH))
            } else if let minH = minHeight {
                result = AnyView(result.frame(minHeight: minH))
            } else if let maxH = maxHeight {
                result = AnyView(result.frame(maxHeight: maxH))
            }
        } else {
            // paddings is used as containerInset, so skip external padding
            // Normal frame application
            result = DynamicModifierHelper.applyFrameConstraints(result, component: component)
            result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)
        }

        // --- 4. .overlay (border) ---
        // Note: background and cornerRadius are handled internally by TextViewWithPlaceholder
        result = DynamicModifierHelper.applyBorder(result, component: component)

        // --- 5. apply_margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 6. .opacity / .hidden ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 7. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }
}
#endif // DEBUG
