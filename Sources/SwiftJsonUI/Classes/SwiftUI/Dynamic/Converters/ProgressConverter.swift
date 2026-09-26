//
//  ProgressConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI ProgressView.
//
//  Modifier order (matches progress_converter.rb):
//    ProgressView(value:) -> .tint(progressTintColor)
//    -> .background(trackTintColor) -> applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct ProgressConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let attrs = component.typedAttributes(ProgressAttributes.self)
        // Progress value: check binding expression first, then static value
        let progressValue: Double = {
            // Binding expression: @{propertyName} — canonical number
            // value context (dot-path / default / Binding<Double> unwrap)
            if let expr = attrs.progress?.bindingExpression {
                return DynamicBindingResolver.resolveDouble(expression: expr, data: data) ?? 0
            }
            // Static value from decoded property. Undeclared renders an EMPTY
            // bar (see shared/core/attribute_semantics.json → progressValue).
            return Double(component.number(ProgressAttributes.self, \.progress, data: data) ?? 0)
        }()

        // ProgressView
        var result = AnyView(
            ProgressView(value: progressValue)
        )

        // indicatorStyle — the declared vocabulary is `medium` / `large`
        // ("ActivityIndicator size style"), NOT linear/circular. Reading it as
        // the shape mapped BOTH declared values onto
        // CircularProgressViewStyle(), so the attribute emitted one constant
        // whatever the layout wrote. `controlSize` is the size knob a
        // ProgressView actually has (progress_converter.rb:30-43 — 49-B fixed
        // the codegen half of this).
        switch DeclaredSpelling.lowered(component.indicatorStyle, in: ProgressAttributes.IndicatorStyle.declaredSpellings) {
        case "large": result = AnyView(result.controlSize(.large))
        case "medium": result = AnyView(result.controlSize(.regular))
        default: break
        }

        // `style` is not read here: it is the style file's name
        // (common.style — "Style file name (without extension)"), applied by
        // the style processor, and Progress declares no shape — a
        // determinate ProgressView is a bar. Reading it as the shape drew any
        // styled Progress (a style named anything but `linear`) as a spinner
        // while kjui and rjui drew a bar (jsonui-cli 1.9.0, the same misread
        // Blur's `style` fallback was).

        // progressTintColor -> .tint() — `color` / `tintColor` are the
        // Indicator/UIKit spellings of the same accent; the specific name
        // wins (mirrors progress_converter.rb).
        // rawRepresentation, not .value — the attribute is string|binding and
        // `.value` reads only the literal half, so a bound tint silently
        // rendered the default (run-4 ?.value sweep). getColor resolves the
        // `@{...}` spelling from data, same as every other colour read.
        let tint = DynamicHelpers.resolveColor(attrs.progressTintColor, data: data)
            ?? (attrs.color
                    ?? component.typedAttributes(ProgressAttributes.self).tintColor)
                .flatMap { DynamicHelpers.getColor($0, data: data) }
        if let color = tint {
            result = AnyView(result.tint(color))
        }

        // trackTintColor -> .background()
        if let color = DynamicHelpers.resolveColor(attrs.trackTintColor, data: data) {
            result = AnyView(result.background(color))
        }

        // hidesWhenStopped — UIActivityIndicatorView's property. On a
        // determinate ProgressView "stopped" is progress == 0, so this hides
        // the bar until there is progress to show. Read by nobody here, which
        // left a Progress declared with it visible at 0
        // (progress_converter.rb:52-58 defines the same rule).
        if attrs.hidesWhenStopped == true {
            result = AnyView(result.opacity(progressValue > 0 ? 1 : 0))
        }

        // Standard modifiers (padding -> frame -> background -> cornerRadius -> border -> margins -> ...)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
