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
            // Static value from decoded property
            return component.progress ?? 0.5
        }()

        // ProgressView
        var result = AnyView(
            ProgressView(value: progressValue)
        )

        // indicatorStyle — same vocabulary as Indicator (linear/circular); a
        // determinate bar defaults to linear, so only apply when declared
        // (mirrors progress_converter.rb).
        let indicatorStyle = component.indicatorStyle ?? component.rawAttribute("style") as? String
        if let style = indicatorStyle {
            if style.lowercased() == "linear" {
                result = AnyView(result.progressViewStyle(LinearProgressViewStyle()))
            } else {
                result = AnyView(result.progressViewStyle(CircularProgressViewStyle()))
            }
        }

        // progressTintColor -> .tint() — `color` / `tintColor` are the
        // Indicator/UIKit spellings of the same accent; the specific name
        // wins (mirrors progress_converter.rb).
        let tintSpelling = attrs.progressTintColor?.value
            ?? component.rawAttribute("color") as? String
            ?? component.tintColor
        if let progressTintColor = tintSpelling,
           let color = DynamicHelpers.getColor(progressTintColor) {
            result = AnyView(result.tint(color))
        }

        // trackTintColor -> .background()
        if let trackTintColor = attrs.trackTintColor?.value,
           let color = DynamicHelpers.getColor(trackTintColor) {
            result = AnyView(result.background(color))
        }

        // Standard modifiers (padding -> frame -> background -> cornerRadius -> border -> margins -> ...)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
