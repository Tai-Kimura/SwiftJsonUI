//
//  IconLabelConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI IconLabelView or IconLabelButton.
//
//  Modifier order (matches icon_label_converter.rb):
//    IconLabelButton(...) or IconLabelView(...)
//    -> applyStandardModifiers()    // base_view_converter apply_modifiers
//
//  Two paths:
//    onClick present -> IconLabelButton with action closure
//    no onClick      -> IconLabelView with isSelected state

import SwiftUI
#if DEBUG

public struct IconLabelConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        let text = DynamicHelpers.processText(component.text, data: data).dynamicLocalized()
        let iconOn = component.iconOn
        let iconOff = component.iconOff
        let iconPosition = resolveIconPosition(component.iconPosition)

        // Optional parameters from JSON
        let iconSize = component.iconSize ?? 24
        let iconMargin = component.iconMargin ?? 5
        let fontSize = component.fontSize ?? 16
        let fontColor = DynamicHelpers.getColor(component.fontColor) ?? .primary
        let selectedFontColor = DynamicHelpers.getColor(component.selectedFontColor) ?? .accentColor
        let fontName = (component.font != nil && component.font != "bold") ? component.font : nil

        // Determine if it's a button (has onClick)
        let hasAction = component.onClick != nil

        var result: AnyView

        if hasAction {
            // IconLabelButton with action
            result = AnyView(
                IconLabelButton(
                    text: text,
                    iconOn: iconOn,
                    iconOff: iconOff,
                    iconPosition: iconPosition,
                    iconSize: iconSize,
                    iconMargin: iconMargin,
                    fontSize: fontSize,
                    fontColor: fontColor,
                    selectedFontColor: selectedFontColor,
                    fontName: fontName,
                    action: {
                        DynamicEventHelper.call(component.onClick, data: data)
                    }
                )
            )
        } else {
            // IconLabelView (no action)
            let isSelected = component.isOn ?? false
            result = AnyView(
                IconLabelView(
                    text: text,
                    iconOn: iconOn,
                    iconOff: iconOff,
                    iconPosition: iconPosition,
                    iconSize: iconSize,
                    iconMargin: iconMargin,
                    fontSize: fontSize,
                    fontColor: fontColor,
                    selectedFontColor: selectedFontColor,
                    fontName: fontName,
                    isSelected: isSelected
                )
            )
        }

        // applyStandardModifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private

    private static func resolveIconPosition(_ position: String?) -> IconLabelView.IconPosition {
        guard let position = position else { return .left }
        switch position.lowercased() {
        case "top": return .top
        case "right": return .right
        case "bottom": return .bottom
        default: return .left
        }
    }
}
#endif // DEBUG
