//
//  ButtonConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of button_converter.rb
//  Creates StateAwareButtonView matching tool-generated code exactly.
//
//  Modifier order (matches button_converter.rb):
//    1. StateAwareButtonView(...) with internal: text, action, font, colors,
//       cornerRadius, border, padding, enabled, width, height
//    2. apply_frame_constraints
//    3. apply_frame_size
//    4. apply_margins
//    5. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct ButtonConverter {

    /// Convert DynamicComponent to SwiftUI StateAwareButtonView
    /// Matches button_converter.rb convert_state_aware_button method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        parentOrientation: String? = nil
    ) -> AnyView {
        // --- 1. Build StateAwareButtonView ---

        // Text with binding support
        let processedText = DynamicHelpers.processText(component.text, data: data) ?? "Button"
        let text = processedText.dynamicLocalized()

        // Build partialAttributes (same as label)
        let partialAttributes = buildPartialAttributes(component: component, data: data)

        // Action - onClick uses binding format @{functionName}
        let action: () -> Void = {
            if let onClick = component.onClick {
                DynamicEventHelper.call(onClick, data: data)
            }
        }

        // Font properties
        let fontSize = component.fontSize
        let fontWeight = component.fontWeight

        // Color properties
        let fontColor = DynamicHelpers.getColor(component.fontColor, data: data)
        let backgroundColor = DynamicHelpers.getColor(component.background, data: data)
        let tapBackground = DynamicHelpers.getColor(component.tapBackground, data: data)
        let highlightColor = DynamicHelpers.getColor(component.highlightColor, data: data)
        let disabledFontColor = DynamicHelpers.getColor(component.disabledFontColor, data: data)
        let disabledBackground = DynamicHelpers.getColor(component.disabledBackground, data: data)

        // Corner radius, border - all applied inside StateAwareButtonView
        let cornerRadius = component.cornerRadius
        let borderWidth = component.borderWidth
        let borderColor = DynamicHelpers.getColor(component.borderColor, data: data)

        // Padding
        let padding = DynamicHelpers.getPadding(from: component)

        // Enabled state (with binding support)
        let isEnabled = DynamicBindingHelper.resolveBool(component.enabled, data: data, fallback: true)

        // Handle width/height - pass to StateAwareButtonView so background fills the frame
        var buttonWidth = component.width
        var buttonHeight = component.height

        // matchParent handling
        if component.widthRaw == "matchParent" || component.width == -1 {
            buttonWidth = -1
        }
        if component.heightRaw == "matchParent" || component.height == -1 {
            buttonHeight = -1
        }

        // weight handling
        if let weight = component.weight, weight > 0 {
            let effectiveOrientation = parentOrientation ?? component.rawData["parent_orientation"] as? String
            if effectiveOrientation == "horizontal" {
                buttonWidth = -1
            } else if effectiveOrientation == "vertical" {
                buttonHeight = -1
            }
        }

        var result = AnyView(
            StateAwareButtonView(
                text: text,
                partialAttributes: partialAttributes,
                action: action,
                fontSize: fontSize,
                fontWeight: fontWeight != nil ? DynamicHelpers.fontWeightFromString(fontWeight) : nil,
                fontColor: fontColor,
                backgroundColor: backgroundColor,
                tapBackground: tapBackground,
                highlightColor: highlightColor,
                disabledFontColor: disabledFontColor,
                disabledBackground: disabledBackground,
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderColor: borderColor,
                padding: padding,
                isEnabled: isEnabled,
                width: buttonWidth,
                height: buttonHeight
            )
        )

        // --- 2. apply_frame_constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)

        // --- 3. apply_frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 4. apply_margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 5. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }

    // MARK: - PartialAttributes builder (same as LabelConverter)

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
                    textPattern: pattern,
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
}
#endif // DEBUG
