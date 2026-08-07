//
//  CheckboxConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to CheckBoxView.
//  Matches checkbox_converter.rb behavior and modifier order.
//
//  Modifier order (matches checkbox_converter.rb):
//    1. CheckBoxView(...) creation with all parameters
//    2. applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct CheckboxConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let id = component.id ?? "checkbox"
        let attrs = component.typedAttributes(CheckBoxAttributes.self)

        // Resolve isOn binding: check isOn, checked, bind
        let isOnExpr: String? = attrs.isOn?.bindingString
            ?? attrs.checked?.bindingString
            ?? attrs.common.bind?.bindingString

        let isOnBinding = DynamicBindingHelper.bool(
            isOnExpr,
            data: data,
            fallback: attrs.isOn?.value ?? attrs.checked?.value ?? false
        )

        // Label text (supports binding)
        let labelText: String = {
            // 'label' is the CheckBox-specific spelling and wins over the
            // generic text (kjui order — 33 adjudication).
            let raw = component.string(CheckBoxAttributes.self, \.label)
                ?? component.string(CheckBoxAttributes.self, \.text) ?? ""
            return DynamicHelpers.processText(raw, data: data).dynamicLocalized()
        }()

        // Icon names
        let icon = component.icon ?? attrs.src
        let selectedIcon = component.selectedIcon ?? component.onSrc

        // Icon size
        let iconSize = component.iconSize ?? 24

        // Spacing — number|binding; the hand-decoded slot is nil for
        // `@{expr}`, so a bound spacing fell to the default 8.
        let spacing = DynamicHelpers.resolveNumber(attrs.spacing, legacy: nil, data: data) ?? 8

        // Font properties
        let fontSize = DynamicHelpers.resolveNumber(attrs.fontSize, legacy: nil, data: data)
        let fontWeight: Font.Weight? = {
            if let style = component.rawAttribute("fontStyle") as? String {
                return DynamicHelpers.fontWeightFromString(style)
            }
            if let weight = component.fontWeightSpelling() {
                return DynamicHelpers.fontWeightFromString(weight)
            }
            // 'font' carries the weight spelling on selection controls
            // (kjui reads it the same way — 33 cross-effect: ios rendered
            // the default weight for font: bold).
            // `font` is string|binding here: the bound spelling arrives as
            // the literal "@{expr}", which matches no weight name and fell
            // through as nil. Resolve it before the vocabulary lookup.
            if let font = (attrs.font?.rawRepresentation as? String)
                .map({ DynamicHelpers.processText($0, data: data) }) ?? component.string(CheckBoxAttributes.self, \.font) {
                return DynamicHelpers.fontWeightFromString(font)
            }
            return nil
        }()

        // Font color
        let fontColor: Color? = {
            if let fc = component.string(CheckBoxAttributes.self, \.fontColor) {
                return DynamicHelpers.getColor(fc)
            }
            return nil
        }()

        // Checked/unchecked colors
        //
        // The codegen chain is `checkedColor || checkColor || tintColor ||
        // onTintColor` (checkbox_converter.rb:98). Two of those are now
        // DECLARED aliases of `checkedColor` (plan 51-E, 57a527a), so the
        // generated extraction folds them and the hand-written raw reads are
        // gone. `tintColor` is deliberately not an alias — it is declared on
        // `common`, and on a CheckBox the common tint IS the checked colour —
        // so it stays a separate, typed read.
        let checkedColor: Color = {
            if let spelling = attrs.checkedColor {
                return DynamicHelpers.getColor(spelling, data: data) ?? .blue
            }
            if let tint = DynamicHelpers.resolveColor(attrs.common.tintColor, data: data) {
                return tint
            }
            return .blue
        }()

        let uncheckedColor: Color = {
            if let uc = component.uncheckedColor {
                return DynamicHelpers.getColor(uc) ?? .gray
            }
            return .gray
        }()

        // Enabled state (supports binding)
        let isEnabled: Bool = {
            switch attrs.common.enabled {
            case .binding(let expr):
                return DynamicBindingHelper.resolveBool("@{\(expr)}", data: data, fallback: true)
            case .value(let v):
                return v
            case nil:
                return true
            }
        }()

        // onValueChange callback
        //
        // `action` and `onValueChanged` are now declared aliases of
        // `onValueChange` (plan 51-E, 57a527a), so the generated extraction
        // resolves all three spellings and only `onClick` — which stays a
        // `common` attribute of its own — needs a second read.
        let handlerExpr: String? = attrs.onValueChange?.bindingString
            ?? attrs.common.onClick?.bindingString

        let onValueChanged: ((Bool) -> Void)? = {
            guard let expr = handlerExpr else { return nil }
            return { newValue in
                DynamicEventHelper.callWithValue(
                    expr,
                    id: id,
                    value: newValue,
                    data: data
                )
            }
        }()

        // Build CheckBoxView
        var result = AnyView(
            CheckBoxView(
                isOn: isOnBinding,
                label: labelText.isEmpty ? nil : labelText,
                icon: icon,
                selectedIcon: selectedIcon,
                iconSize: iconSize,
                // Icon tint. Declared, generated, and taken by CheckBoxView
                // since it was written (CheckBoxView.swift:141 already reads
                // `iconColor ?? …` for the system glyph) — the converter was
                // simply not passing it, so `CheckBox/iconColor__static`
                // measured inert on ios while the codegen honoured it
                // (checkbox_converter.rb:58). Emitted here in the same
                // position the codegen emits it.
                iconColor: DynamicHelpers.getColor(attrs.iconColor, data: data),
                spacing: spacing,
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontColor: fontColor,
                checkedColor: checkedColor,
                uncheckedColor: uncheckedColor,
                isEnabled: isEnabled,
                onValueChanged: onValueChanged
            )
        )

        // Standard modifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
