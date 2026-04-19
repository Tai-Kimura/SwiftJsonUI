//
//  BlurConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of blur_converter.rb
//  Creates a view with blur (material) background matching tool-generated code exactly.
//
//  Modifier order (matches blur_converter.rb):
//    1. Single child view or ZStack (multiple children) or Color.clear (no children)
//    2. .background(.ultraThinMaterial)
//    3. .preferredColorScheme(.dark/.light)  -- when style is "dark" or "light"
//    4. applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct BlurConverter {

    /// Convert DynamicComponent to SwiftUI View with Blur Effect
    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        // --- 1. Create content from children ---
        // Ruby: child_data.is_a?(Array) ? child_data : [child_data]
        let children = component.childComponents ?? []
        var result: AnyView

        // Strip weighted child flags before passing to children
        var cData = data
        cData.removeValue(forKey: "__isWeightedChild")
        cData.removeValue(forKey: "__weightedParentOrientation")

        if children.isEmpty {
            result = AnyView(Color.clear)
        } else if children.count == 1 {
            // Single child: render directly (no wrapper)
            result = AnyView(
                DynamicComponentBuilder(component: children[0], data: cData, viewId: viewId)
            )
        } else {
            // Multiple children: wrap in ZStack (matches Ruby converter)
            result = AnyView(
                ZStack {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        DynamicComponentBuilder(component: child, data: cData, viewId: viewId)
                    }
                }
            )
        }

        // --- 2. .background(.ultraThinMaterial) ---
        result = AnyView(result.background(.ultraThinMaterial))

        // --- 3. .preferredColorScheme() based on style ---
        let style = component.rawData["style"] as? String ?? "regular"
        switch style {
        case "dark":
            result = AnyView(result.preferredColorScheme(.dark))
        case "light":
            result = AnyView(result.preferredColorScheme(.light))
        default:
            break // "regular" or other: no color scheme override
        }

        // --- 4. applyStandardModifiers() ---
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
