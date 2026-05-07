//
//  DividerConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Divider / Rectangle.
//  No direct Ruby converter equivalent -- dividers are a visual separator.
//  Uses Rectangle() for custom color/thickness, Divider() for system default.
//
//  Modifier order:
//    1. Rectangle or Divider base
//    2. frame (height for thickness, width for matchParent)
//    3. padding (paddings / paddingTop etc.)
//    4. frame_size (explicit width / height)
//    5. frame_constraints (minWidth / maxWidth etc.)
//    6. background (only for Divider(), Rectangle uses .fill)
//    7. cornerRadius
//    8. margins
//    9. opacity
//   10. hidden
//   11. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct DividerConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let color = resolveColor(component, data: data)
        let thickness = component.height ?? 1

        // --- 1. Base view ---
        var result: AnyView

        if let color = color {
            // Custom color: use Rectangle with fill for precise control
            result = AnyView(
                Rectangle()
                    .fill(color)
                    .frame(height: thickness)
            )
        } else {
            // System default: use Divider with optional frame
            result = AnyView(
                Divider()
                    .frame(height: thickness)
            )
        }

        // --- 2. matchParent width ---
        let width = component.width
        if width == .infinity || width == -1 {
            result = AnyView(result.frame(maxWidth: .infinity))
        } else if let w = width, w > 0 && w.isFinite {
            result = AnyView(result.frame(width: w))
        }

        // --- 3. padding ---
        result = DynamicModifierHelper.applyPadding(result, component: component)

        // --- 4. frame_size (explicit, skipping height since already applied) ---
        // Only apply if width is set explicitly and not already handled above
        // Height is already set as thickness, so applyFrameSize is skipped to avoid conflict

        // --- 5. frame_constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)

        // --- 6. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component)

        // --- 7. border ---
        result = DynamicModifierHelper.applyBorder(result, component: component)

        // --- 8. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 9. opacity ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)

        // --- 10. hidden ---
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 11. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }

    // MARK: - Color Resolution

    /// Resolve divider color from background or borderColor attributes
    /// Returns nil if no custom color is specified (use system Divider)
    private static func resolveColor(_ component: DynamicComponent, data: [String: Any]) -> Color? {
        if let bgColor = component.background {
            return DynamicHelpers.getColor(bgColor, data: data)
        }
        if let borderColor = component.borderColor {
            return DynamicHelpers.getColor(borderColor)
        }
        return nil
    }
}
#endif // DEBUG
