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
        // Progress value: check binding expression first, then static value
        let progressExpr = component.rawData["progress"] as? String
        let progressValue: Double = {
            // Binding expression: @{propertyName}
            if let expr = progressExpr,
               expr.hasPrefix("@{") && expr.hasSuffix("}") {
                let propName = String(expr.dropFirst(2).dropLast(1))
                return data[propName] as? Double ?? 0
            }
            // Static value from decoded property
            return component.progress ?? 0.5
        }()

        // ProgressView
        var result = AnyView(
            ProgressView(value: progressValue)
        )

        // progressTintColor -> .tint()
        if let progressTintColor = component.rawData["progressTintColor"] as? String,
           let color = DynamicHelpers.getColor(progressTintColor) {
            result = AnyView(result.tint(color))
        }

        // trackTintColor -> .background()
        if let trackTintColor = component.rawData["trackTintColor"] as? String,
           let color = DynamicHelpers.getColor(trackTintColor) {
            result = AnyView(result.background(color))
        }

        // Standard modifiers (padding -> frame -> background -> cornerRadius -> border -> margins -> ...)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
