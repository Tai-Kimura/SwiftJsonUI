//
//  GradientViewConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of gradient_view_converter.rb
//  Creates a view with LinearGradient background matching tool-generated code exactly.
//
//  Modifier order (matches gradient_view_converter.rb):
//    1. Child view (single child) or VStack (multiple children) or Color.clear (no children)
//    2. .background(LinearGradient(...))  -- when colors/gradient is present
//    3. applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct GradientViewConverter {

    /// Convert DynamicComponent to SwiftUI View with Gradient Background
    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        // --- 1. Create content from children ---
        let children = component.childComponents ?? []
        var result: AnyView

        // Strip weighted child flags before passing to children
        var cData = data
        cData.removeValue(forKey: "__isWeightedChild")
        cData.removeValue(forKey: "__weightedParentOrientation")

        if children.isEmpty {
            result = AnyView(Color.clear)
        } else if children.count == 1 {
            result = AnyView(
                DynamicComponentBuilder(component: children[0], data: cData, viewId: viewId)
            )
        } else {
            result = AnyView(
                VStack(spacing: 0) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, data: cData, viewId: viewId)
                    }
                }
            )
        }

        // --- 2. .background(LinearGradient(...)) ---
        let colorArray = component.rawData["colors"] as? [String]
            ?? component.rawData["gradient"] as? [String]
        if let colorArray = colorArray, !colorArray.isEmpty {
            let gradient = buildLinearGradient(colorArray: colorArray, component: component)
            result = AnyView(result.background(gradient))
        }

        // --- 3. applyStandardModifiers() ---
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private Helpers

    /// Build a LinearGradient from color hex array and component attributes
    private static func buildLinearGradient(
        colorArray: [String],
        component: DynamicComponent
    ) -> LinearGradient {
        let colors = colorArray.compactMap { DynamicHelpers.getColor($0) }
        let finalColors = colors.isEmpty ? [Color.clear] : colors

        let startPoint: UnitPoint
        let endPoint: UnitPoint

        // Check for explicit startPoint/endPoint dictionaries
        if let startDict = component.rawData["startPoint"] as? [String: Any],
           let endDict = component.rawData["endPoint"] as? [String: Any] {
            startPoint = gradientUnitPoint(from: startDict)
            endPoint = gradientUnitPoint(from: endDict)
        } else {
            // Fall back to gradientDirection string
            let direction = component.rawData["gradientDirection"] as? String ?? "Vertical"
            switch direction {
            case "Horizontal":
                startPoint = .leading
                endPoint = .trailing
            case "Oblique":
                startPoint = .topLeading
                endPoint = .bottomTrailing
            default: // "Vertical" or anything else
                startPoint = .top
                endPoint = .bottom
            }
        }

        return LinearGradient(
            colors: finalColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    /// Convert a {x, y} dictionary to a SwiftUI UnitPoint, mapping common values
    /// to named constants (matches gradient_view_converter.rb gradient_point method)
    private static func gradientUnitPoint(from dict: [String: Any]) -> UnitPoint {
        let x = (dict["x"] as? Double) ?? (dict["x"] as? CGFloat).map(Double.init) ?? 0
        let y = (dict["y"] as? Double) ?? (dict["y"] as? CGFloat).map(Double.init) ?? 0

        // Map common gradient points to named constants
        switch (x, y) {
        case (0, 0):     return .topLeading
        case (0.5, 0):   return .top
        case (1, 0):     return .topTrailing
        case (0, 0.5):   return .leading
        case (0.5, 0.5): return .center
        case (1, 0.5):   return .trailing
        case (0, 1):     return .bottomLeading
        case (0.5, 1):   return .bottom
        case (1, 1):     return .bottomTrailing
        default:         return UnitPoint(x: x, y: y)
        }
    }
}
#endif // DEBUG
