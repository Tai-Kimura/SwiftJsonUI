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
        let attrs = component.typedAttributes(ButtonAttributes.self)
        // --- 1. Build StateAwareButtonView ---

        // Icon (`image`) — a bare name is an asset name, a binding resolves
        // through data (same resolution as Image#srcName).
        // rawRepresentation gives back the layout spelling — the static name
        // or "@{expr}" — which processText then interpolates against data.
        let image = DynamicHelpers.processText(
            attrs.image?.rawRepresentation as? String, data: data
        )
        let hasImage = !image.isEmpty

        // Text with binding support. "Button" is the placeholder for a button
        // with nothing in it, so it does not apply once there is an icon —
        // otherwise an icon-only button renders the word "Button" beside it
        // (button_converter.rb makes the same call).
        //
        // processText returns "" for a missing text, never nil, so the old
        // `?? "Button"` never fired and a text-less button rendered blank
        // here while the generated code rendered "Button". Checking the
        // empty string restores that parity.
        let rawText = DynamicHelpers.processText(component.text, data: data)
        let processedText = (rawText.isEmpty && !hasImage) ? "Button" : rawText
        let text = processedText.dynamicLocalized()

        // Build partialAttributes (same as label)
        let partialAttributes = buildPartialAttributes(component: component, data: data)

        // Action - onClick uses binding format @{functionName}; legacy
        // "onclick" selector format resolves to the same data-dict closure.
        let action: () -> Void = {
            if let onClick = component.effectiveOnClick {
                DynamicEventHelper.call(onClick, data: data)
            }
        }

        // Font properties
        // `font` doubles as a weight spelling ("bold" etc.) — the codegen
        // path resolves it through apply_font_modifiers; the explicit
        // fontWeight wins when both are declared.
        // Button declares fontSize as `number` only — the generated table
        // carries a plain `Double?`, so there is no binding form to resolve.
        let fontSize = attrs.fontSize.map { CGFloat($0) }
        // `fontWeight` is string|number|binding. The hand-decoded String?
        // hands "@{expr}" straight to the weight vocabulary, which matches
        // nothing — the same union the codegen halves read differently (49-B).
        let resolvedFontWeight: String? = {
            guard let raw = attrs.fontWeight?.rawRepresentation else { return component.fontWeight }
            if let s = raw as? String { return DynamicHelpers.processText(s, data: data) }
            return String(describing: raw)
        }()
        let fontWeight = resolvedFontWeight ?? {
            if let f = component.font,
               ["bold", "semibold", "medium", "light", "thin", "ultralight", "heavy", "black"].contains(f.lowercased()) {
                return f
            }
            return nil
        }()

        // Color properties
        let fontColor = DynamicHelpers.getColor(component.fontColor, data: data)
        let backgroundColor = DynamicHelpers.getColor(component.commonString(\.background), data: data)
        // `highlightBackground` is the UIKit-era spelling of the pressed-state
        // background; `tapBackground` wins when both are declared. Same rule
        // as button_converter.rb:188-194 and rjui button_converter.rb:68.
        let buttonAttrs = component.typedAttributes(ButtonAttributes.self)
        let tapBackground = DynamicHelpers.getColor(
            component.tapBackground ?? buttonAttrs.highlightBackground, data: data
        )
        // Read through the generated extraction so the `hilightColor` typo
        // alias resolves — 49-E folded that second declaration into an alias,
        // and the hand-decoded property never saw it.
        let highlightColor = DynamicHelpers.getColor(
            buttonAttrs.highlightColor?.rawRepresentation as? String,
            data: data
        )
        let disabledFontColor = DynamicHelpers.getColor(component.disabledFontColor, data: data)
        let disabledBackground = DynamicHelpers.getColor(
            component.typedAttributes(CommonAttributes.self).disabledBackground?.rawRepresentation as? String,
            data: data
        )

        // Icon tint: only when the layout asked for one — a template
        // rendering mode would flatten a multi-colour asset to a single
        // colour. Same rule as the Compose and web converters.
        let imageTint = hasImage
            ? DynamicHelpers.getColor(component.tintColor, data: data)
                ?? DynamicHelpers.getColor(component.fontColor, data: data)
            : nil

        // Corner radius, border - all applied inside StateAwareButtonView
        let cornerRadius = component.number(CommonAttributes.self, \.cornerRadius, data: data)
        let borderWidth = component.number(CommonAttributes.self, \.borderWidth, data: data)
        let borderColor = DynamicHelpers.getColor(component.commonString(\.borderColor), data: data)

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

        // weight handling (number|binding — resolve `@{binding}` from data)
        if let weight = DynamicHelpers.resolveWeight(from: component, data: data), weight > 0 {
            let effectiveOrientation = parentOrientation
                ?? component.rawAttribute("parent_orientation") as? String
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
                height: buttonHeight,
                image: hasImage ? image : nil,
                imageTint: imageTint
            )
        )

        // --- 2. apply_frame_constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component, data: data)

        // --- 3. apply_frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 4. apply_margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 4.5. buttonStyle (common attribute; plain/bordered/borderedProminent/borderless) ---
        if let style = attrs.common.style {
            switch style {
            case "plain": result = AnyView(result.buttonStyle(.plain))
            case "bordered": result = AnyView(result.buttonStyle(.bordered))
            case "borderedProminent": result = AnyView(result.buttonStyle(.borderedProminent))
            case "borderless": result = AnyView(result.buttonStyle(.borderless))
            case "automatic": result = AnyView(result.buttonStyle(.automatic))
            default: break
            }
        }

        // --- 4.6. confirmationDialog (iOS 15+, common attribute) ---
        // Mirrored from DynamicModifierHelper.applyStandardModifiers so that
        // Button — which runs its own modifier bag without applyStandardModifiers —
        // still honors the shared `confirmationDialog` attribute.
        if #available(iOS 15.0, *) {
            result = DynamicModifierHelper.applyConfirmationDialog(result, component: component, data: data)
        }

        // --- 4.7. onLongPress (common attribute) ---
        // Button runs its own modifier bag (no applyStandardModifiers), so the
        // shared onLongPress gesture is applied here; simultaneousGesture keeps
        // the Button's own tap action working.
        result = DynamicEventHelper.applyOnLongPress(result, component: component, data: data)

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
