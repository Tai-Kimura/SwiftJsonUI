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
        // Colors + locations may live at the top level (legacy) or nested inside
        // a `gradient` object emitted by the tool: `{colors, locations, startPoint, endPoint}`.
        let gradientObject = component.rawData["gradient"] as? [String: Any]
        let colorArray = (gradientObject?["colors"] as? [String])
            ?? (component.rawData["colors"] as? [String])
            ?? (component.rawData["gradient"] as? [String])
        let locations = (gradientObject?["locations"] as? [Any])
            ?? (component.rawData["locations"] as? [Any])
        if let colorArray = colorArray, !colorArray.isEmpty {
            let gradient = buildLinearGradient(
                colorArray: colorArray,
                locations: locations,
                component: component,
                gradientObject: gradientObject
            )
            result = AnyView(result.background(gradient))
        }

        // --- 3. applyStandardModifiers() ---
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private Helpers

    /// Build a LinearGradient from color hex array and component attributes.
    /// When `locations` is provided with the same cardinality as `colorArray`
    /// the gradient is built with explicit `Gradient.Stop`s for color stops.
    private static func buildLinearGradient(
        colorArray: [String],
        locations: [Any]?,
        component: DynamicComponent,
        gradientObject: [String: Any]?
    ) -> LinearGradient {
        let colors = colorArray.compactMap { DynamicHelpers.getColor($0) }
        let finalColors = colors.isEmpty ? [Color.clear] : colors

        let (startPoint, endPoint) = resolveGradientEndpoints(
            component: component,
            gradientObject: gradientObject
        )

        // Explicit color stops → linearGradient(stops:)
        if let locations = locations,
           let stopValues = normalizedLocations(locations),
           stopValues.count == finalColors.count {
            let stops = zip(finalColors, stopValues).map { Gradient.Stop(color: $0.0, location: CGFloat($0.1)) }
            return LinearGradient(stops: stops, startPoint: startPoint, endPoint: endPoint)
        }

        return LinearGradient(
            colors: finalColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    private static func normalizedLocations(_ raw: [Any]) -> [Double]? {
        let values: [Double] = raw.compactMap { value in
            if let d = value as? Double { return d }
            if let i = value as? Int { return Double(i) }
            if let f = value as? CGFloat { return Double(f) }
            if let n = value as? NSNumber { return n.doubleValue }
            return nil
        }
        return values.count == raw.count ? values : nil
    }

    /// Resolve gradient endpoints from (in priority order):
    ///   1. `startPoint` / `endPoint` as `{x, y}` dicts at top level
    ///   2. Nested `gradient.startPoint` / `gradient.endPoint` (object or named string)
    ///   3. Top-level `startPoint` / `endPoint` as named strings (e.g. "top", "bottomTrailing")
    ///   4. `gradientDirection` string fallback
    private static func resolveGradientEndpoints(
        component: DynamicComponent,
        gradientObject: [String: Any]?
    ) -> (UnitPoint, UnitPoint) {
        if let startDict = component.rawData["startPoint"] as? [String: Any],
           let endDict = component.rawData["endPoint"] as? [String: Any] {
            return (gradientUnitPoint(from: startDict), gradientUnitPoint(from: endDict))
        }
        if let startDict = gradientObject?["startPoint"] as? [String: Any],
           let endDict = gradientObject?["endPoint"] as? [String: Any] {
            return (gradientUnitPoint(from: startDict), gradientUnitPoint(from: endDict))
        }
        let startName = (gradientObject?["startPoint"] as? String)
            ?? (component.rawData["startPoint"] as? String)
        let endName = (gradientObject?["endPoint"] as? String)
            ?? (component.rawData["endPoint"] as? String)
        if let startName = startName, let endName = endName {
            return (namedUnitPoint(startName), namedUnitPoint(endName))
        }

        let direction = component.rawData["gradientDirection"] as? String ?? "Vertical"
        switch direction {
        case "Horizontal", "horizontal", "leftToRight":
            return (.leading, .trailing)
        case "rightToLeft":
            return (.trailing, .leading)
        case "Oblique", "diagonal":
            return (.topLeading, .bottomTrailing)
        case "bottomToTop":
            return (.bottom, .top)
        default:
            return (.top, .bottom)
        }
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

    /// Resolve SwiftUI-style gradient anchor names to `UnitPoint`.
    private static func namedUnitPoint(_ name: String) -> UnitPoint {
        switch name {
        case "top": return .top
        case "bottom": return .bottom
        case "leading", "left": return .leading
        case "trailing", "right": return .trailing
        case "topLeading", "topLeft": return .topLeading
        case "topTrailing", "topRight": return .topTrailing
        case "bottomLeading", "bottomLeft": return .bottomLeading
        case "bottomTrailing", "bottomRight": return .bottomTrailing
        case "center": return .center
        default: return .top
        }
    }
}
#endif // DEBUG
