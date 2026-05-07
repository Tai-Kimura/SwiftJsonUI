//
//  SpacerConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Spacer.
//  No direct Ruby converter equivalent -- spacers are typically inserted by
//  view_converter.rb for gravity-based alignment. When explicitly typed as "Spacer"
//  in JSON, this converter handles it.
//
//  Modifier order:
//    1. Spacer() or Color.clear (for sized spacers)
//    2. frame (width / height for fixed-size spacers)
//    3. margins
//    4. opacity
//    5. hidden
//    6. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct SpacerConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let width = component.width
        let height = component.height

        // --- 1. Spacer base ---
        var result: AnyView

        let hasFixedWidth = width != nil && width != .infinity && width != -1 && width! > 0
        let hasFixedHeight = height != nil && height != .infinity && height != -1 && height! > 0

        if hasFixedWidth || hasFixedHeight {
            // Fixed-size spacer: use Color.clear with explicit frame
            // Spacer() ignores fixed frame in some layouts, Color.clear is more reliable
            result = AnyView(
                Color.clear
                    .frame(
                        width: hasFixedWidth ? width : nil,
                        height: hasFixedHeight ? height : nil
                    )
            )
        } else {
            // Flexible spacer: use Spacer() which fills available space
            // Apply maxWidth/maxHeight for matchParent (-1 or .infinity)
            var spacerView = AnyView(Spacer())

            if width == .infinity || width == -1 {
                spacerView = AnyView(spacerView.frame(maxWidth: .infinity))
            }
            if height == .infinity || height == -1 {
                spacerView = AnyView(spacerView.frame(maxHeight: .infinity))
            }

            result = spacerView
        }

        // --- 2. frame constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)

        // --- 3. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 4. opacity ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)

        // --- 5. hidden ---
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 6. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }
}
#endif // DEBUG
