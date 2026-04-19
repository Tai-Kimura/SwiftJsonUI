//
//  ToggleConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Toggle.
//  Matches toggle_converter.rb behavior and modifier order.
//
//  Modifier order (matches toggle_converter.rb):
//    1. Toggle(isOn:) { Text(...) with font/color modifiers }
//    2. .toggleStyle() (if toggleStyle set)
//    3. .onChange() (onValueChange)
//    4. applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct ToggleConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let id = component.id ?? "toggle"

        // Resolve isOn binding: check isOn first, then checked
        let isOnExpr: String? = {
            if let expr = component.rawData["isOn"] as? String, expr.hasPrefix("@{") {
                return expr
            }
            if let expr = component.rawData["checked"] as? String, expr.hasPrefix("@{") {
                return expr
            }
            return nil
        }()

        let isOnBinding = DynamicBindingHelper.bool(
            isOnExpr,
            data: data,
            fallback: component.isOn ?? component.checked ?? false
        )

        // Label text
        let text = component.text ?? component.label ?? ""

        // Build Toggle with label
        var result: AnyView

        // Determine font from component or labelAttributes
        let labelAttrsDict = component.rawData["labelAttributes"] as? [String: Any]

        // Build the label Text view with font and color modifiers
        let labelFont: Font? = {
            if let labelAttrs = labelAttrsDict {
                // labelAttributes override component-level font settings
                let fontSize = labelAttrs["fontSize"] as? CGFloat ?? component.fontSize
                let fontName = labelAttrs["font"] as? String ?? component.font
                let fontWeight = labelAttrs["fontWeight"] as? String ?? labelAttrs["fontStyle"] as? String ?? component.fontWeight
                guard fontSize != nil || fontName != nil || fontWeight != nil else { return nil }
                if let name = fontName, let size = fontSize ?? 17 as CGFloat? {
                    return Font.custom(name, size: size)
                }
                if let size = fontSize {
                    let weight = DynamicHelpers.fontWeightFromString(fontWeight)
                    return Font.system(size: size, weight: weight)
                }
                return nil
            } else {
                return DynamicHelpers.fontFromComponent(component)
            }
        }()

        let labelColor: Color? = {
            if let labelAttrs = labelAttrsDict {
                let colorStr = labelAttrs["fontColor"] as? String ?? labelAttrs["color"] as? String
                if let colorStr = colorStr {
                    return DynamicHelpers.getColor(colorStr)
                }
            }
            if let fontColor = component.fontColor {
                return DynamicHelpers.getColor(fontColor)
            }
            return nil
        }()

        result = AnyView(
            Toggle(isOn: isOnBinding) {
                buildLabelText(text: text, font: labelFont, color: labelColor)
            }
        )

        // toggleStyle
        if let toggleStyle = component.rawData["toggleStyle"] as? String {
            switch toggleStyle {
            case "switch":
                result = AnyView(AnyViewWrapper(view: result).toggleStyle(SwitchToggleStyle()))
            case "button":
                if #available(iOS 15.0, *) {
                    result = AnyView(AnyViewWrapper(view: result).toggleStyle(.button))
                }
            default:
                result = AnyView(AnyViewWrapper(view: result).toggleStyle(DefaultToggleStyle()))
            }
        }

        // onValueChange handler - called when toggle state changes
        if let onValueChange = component.onValueChange,
           let _ = DynamicEventHelper.extractPropertyName(from: onValueChange) {
            // Determine the binding property to observe
            let observeProperty: String? = {
                if let expr = component.rawData["isOn"] as? String {
                    return DynamicEventHelper.extractPropertyName(from: expr)
                }
                if let expr = component.rawData["checked"] as? String {
                    return DynamicEventHelper.extractPropertyName(from: expr)
                }
                return nil
            }()

            if let propName = observeProperty,
               let binding = data[propName] as? SwiftUI.Binding<Bool> {
                result = AnyView(
                    result.onChange(of: binding.wrappedValue) { newValue in
                        DynamicEventHelper.callWithValue(
                            onValueChange,
                            id: id,
                            value: newValue,
                            data: data
                        )
                    }
                )
            }
        }

        // Standard modifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private helpers

    @ViewBuilder
    private static func buildLabelText(text: String, font: Font?, color: Color?) -> some View {
        let baseText = Text(text.dynamicLocalized())
        if let font = font, let color = color {
            baseText.font(font).foregroundColor(color)
        } else if let font = font {
            baseText.font(font)
        } else if let color = color {
            baseText.foregroundColor(color)
        } else {
            baseText
        }
    }
}

/// Helper to apply toggleStyle to AnyView (toggleStyle requires ToggleStyle conformance on the View)
private struct AnyViewWrapper: View {
    let view: AnyView
    var body: some View { view }
}

#endif // DEBUG
