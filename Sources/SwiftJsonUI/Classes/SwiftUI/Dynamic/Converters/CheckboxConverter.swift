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

        // Resolve isOn binding: check isOn, checked, bind
        let isOnExpr: String? = {
            if let expr = component.rawData["isOn"] as? String, expr.hasPrefix("@{") {
                return expr
            }
            if let expr = component.rawData["checked"] as? String, expr.hasPrefix("@{") {
                return expr
            }
            if let expr = component.rawData["bind"] as? String, expr.hasPrefix("@{") {
                return expr
            }
            return nil
        }()

        let isOnBinding = DynamicBindingHelper.bool(
            isOnExpr,
            data: data,
            fallback: component.isOn ?? component.checked ?? false
        )

        // Label text (supports binding)
        let labelText: String = {
            let raw = component.text ?? component.label ?? ""
            return DynamicHelpers.processText(raw, data: data).dynamicLocalized()
        }()

        // Icon names
        let icon = component.icon ?? component.src
        let selectedIcon = component.selectedIcon ?? component.onSrc

        // Icon size
        let iconSize = component.iconSize ?? 24

        // Spacing
        let spacing = component.spacing ?? 8

        // Font properties
        let fontSize = component.fontSize
        let fontWeight: Font.Weight? = {
            if let style = component.rawData["fontStyle"] as? String {
                return DynamicHelpers.fontWeightFromString(style)
            }
            if let weight = component.fontWeight {
                return DynamicHelpers.fontWeightFromString(weight)
            }
            return nil
        }()

        // Font color
        let fontColor: Color? = {
            if let fc = component.fontColor {
                return DynamicHelpers.getColor(fc)
            }
            return nil
        }()

        // Checked/unchecked colors
        let checkedColor: Color = {
            if let cc = component.checkedColor {
                return DynamicHelpers.getColor(cc) ?? .blue
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
            if let enabledStr = component.rawData["enabled"] as? String,
               enabledStr.hasPrefix("@{") {
                return DynamicBindingHelper.resolveBool(enabledStr, data: data, fallback: true)
            }
            if let enabledBool = component.rawData["enabled"] as? Bool {
                return enabledBool
            }
            return true
        }()

        // onValueChange callback
        // Support: onValueChange, onClick, action, onValueChanged (backward compat)
        let handlerExpr: String? = {
            let candidates = ["onValueChange", "onClick", "action", "onValueChanged"]
            for key in candidates {
                if let expr = component.rawData[key] as? String,
                   expr.hasPrefix("@{") && expr.hasSuffix("}") {
                    return expr
                }
            }
            return nil
        }()

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
