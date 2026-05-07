//
//  IndicatorConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI ProgressView (indeterminate).
//
//  Modifier order (matches indicator_converter.rb):
//    ProgressView()
//    -> .progressViewStyle()        // indicatorStyle / style
//    -> .scaleEffect()              // large=1.5, small=0.8
//    -> .tint()                     // color / tintColor / tint
//    -> applyStandardModifiers()    // base_view_converter apply_modifiers
//
//  Conditional visibility:
//    animating == false             -> EmptyView()
//    animating == "@{prop}"         -> if data.prop { ProgressView ... }
//    animating == true / missing    -> always show

import SwiftUI
#if DEBUG

public struct IndicatorConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        // Check for animating property (read from rawData since not a typed field)
        let animatingRaw = component.rawData["animating"]

        // Static false - don't show indicator
        if let boolVal = animatingRaw as? Bool, boolVal == false {
            return AnyView(EmptyView())
        }

        // Binding expression - wrap in conditional visibility
        if let stringVal = animatingRaw as? String,
           stringVal.hasPrefix("@{") && stringVal.hasSuffix("}") {
            let varName = toCamelCase(String(stringVal.dropFirst(2).dropLast(1)))
            let isAnimating = DynamicBindingHelper.resolveBool(stringVal, data: data, fallback: false)
            if !isAnimating {
                return AnyView(EmptyView())
            }
            return buildProgressView(component: component, data: data)
        }

        // Static true, any truthy value, or no animating property - always show
        return buildProgressView(component: component, data: data)
    }

    // MARK: - Private

    private static func buildProgressView(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        // 1. ProgressView
        var result = AnyView(ProgressView())

        // 2. progressViewStyle (indicatorStyle or style from rawData)
        let styleStr = component.indicatorStyle
            ?? component.rawData["style"] as? String
        if let styleStr = styleStr {
            let scale = scaleForStyle(styleStr)
            result = applyProgressViewStyle(result, style: styleStr)

            // 3. scaleEffect (based on style)
            if scale != 1.0 {
                result = AnyView(result.scaleEffect(scale))
            }
        }

        // 4. tint (color / tintColor / tint)
        let colorStr = component.color
            ?? component.tintColor
            ?? component.tint
        if let colorStr = colorStr, let color = DynamicHelpers.getColor(colorStr) {
            result = AnyView(result.tint(color))
        }

        // 5. applyStandardModifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    private static func applyProgressViewStyle(_ view: AnyView, style: String) -> AnyView {
        switch style.lowercased() {
        case "linear":
            return AnyView(view.progressViewStyle(LinearProgressViewStyle()))
        default:
            return AnyView(view.progressViewStyle(CircularProgressViewStyle()))
        }
    }

    private static func scaleForStyle(_ style: String) -> CGFloat {
        switch style.lowercased() {
        case "large":
            return 1.5
        case "small":
            return 0.8
        default:
            return 1.0
        }
    }

    /// Convert snake_case to camelCase
    private static func toCamelCase(_ str: String) -> String {
        let parts = str.split(separator: "_")
        guard let first = parts.first else { return str }
        return String(first) + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }
}
#endif // DEBUG
