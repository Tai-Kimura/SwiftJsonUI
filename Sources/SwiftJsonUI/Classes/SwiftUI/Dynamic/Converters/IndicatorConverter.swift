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
        let attrs = component.typedAttributes(IndicatorAttributes.self)
        let animatingRaw = attrs.animating?.rawRepresentation

        // `hidesWhenStopped` decides what a STOPPED indicator does, and it is
        // only ever read on that branch — the canon is written into
        // `Indicator.animating`'s own declaration: "`false` stops it, and
        // hidesWhenStopped then decides whether the stopped indicator keeps
        // its space or collapses out of the layout". This path collapsed to
        // EmptyView unconditionally, so a declared `hidesWhenStopped: false`
        // changed nothing here while the codegen kept a stopped spinner at
        // `.opacity(0)` (indicator_converter.rb:23-30) — the two ios paths
        // implemented different rules, which is what
        // `Indicator/hidesWhenStopped__false` measured.
        //
        // Absent means true, mirroring the codegen's nil-coalescing. The SSoT
        // declares no `default` for the attribute; reported to E.
        let hidesWhenStopped = attrs.hidesWhenStopped ?? true

        // A stopped indicator: gone, or present but invisible.
        func stopped() -> AnyView {
            hidesWhenStopped
                ? AnyView(EmptyView())
                : AnyView(buildProgressView(component: component, data: data).opacity(0))
        }

        // Static false - don't show indicator
        if let boolVal = animatingRaw as? Bool, boolVal == false {
            return stopped()
        }

        // Binding expression - wrap in conditional visibility
        if let stringVal = animatingRaw as? String,
           DynamicBindingResolver.isBindingExpression(stringVal) {
            // Canonical bool value context via the central resolver
            let isAnimating = DynamicBindingHelper.resolveBool(stringVal, data: data, fallback: false)
            if !isAnimating {
                return stopped()
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
            ?? component.typedAttributes(IndicatorAttributes.self).common.style
        if let styleStr = styleStr {
            let scale = scaleForStyle(styleStr)
            result = applyProgressViewStyle(result, style: styleStr)

            // 3. scaleEffect (based on style)
            if scale != 1.0 {
                result = AnyView(result.scaleEffect(scale))
            }
        }

        // 4. tint (color / tintColor / tint)
        let colorStr = component.typedAttributes(IndicatorAttributes.self).color?.rawRepresentation as? String
            ?? component.commonString(\.tintColor)
            ?? component.string(SwitchAttributes.self, \.tint)
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

}
#endif // DEBUG
