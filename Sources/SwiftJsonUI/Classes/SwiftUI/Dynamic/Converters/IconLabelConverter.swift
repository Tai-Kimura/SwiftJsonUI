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
        // The canonical keys are snake_case (`icon_on` / `icon_off`, the
        // SSoT/UIKit spelling) — the legacy camelCase decode slots never
        // matched them, so declared icons silently dropped.
        let attrs = component.typedAttributes(IconLabelAttributes.self)
        let iconOn = attrs.icon_on ?? component.iconOn
        let iconOff = attrs.icon_off ?? component.iconOff
        let iconPosition = resolveIconPosition(component.iconPosition)

        // Optional parameters from JSON
        let iconSize = component.iconSize ?? 24
        let iconMargin = component.iconMargin ?? 5
        let fontSize = component.fontSize ?? 16
        let fontColor = DynamicHelpers.getColor(component.fontColor) ?? .primary
        let selectedFontColor = DynamicHelpers.getColor(component.selectedFontColor) ?? .accentColor
        let fontName = (component.font != nil && component.font != "bold") ? component.font : nil
        // 'font: bold' is the weight spelling; textShadow the shadow object
        // (33 cross-effect: ios rendered default weight and no shadow).
        let fontWeight: Font.Weight? = component.font == "bold" ? .bold : nil
        var shadowColor: Color? = nil
        var shadowRadius: CGFloat = 1
        var shadowOffset = CGSize(width: 0, height: 1)
        if let shadow = component.rawAttribute("textShadow") as? [String: Any] {
            shadowColor = (shadow["color"] as? String).flatMap { DynamicHelpers.getColor($0) }
                ?? Color.black.opacity(0.3)
            if let blur = shadow["blur"] as? Double { shadowRadius = CGFloat(blur) }
            else if let blur = shadow["blur"] as? Int { shadowRadius = CGFloat(blur) }
            if let off = shadow["offset"] as? [Any], off.count >= 2 {
                let x = (off[0] as? Double) ?? Double(off[0] as? Int ?? 0)
                let y = (off[1] as? Double) ?? Double(off[1] as? Int ?? 1)
                shadowOffset = CGSize(width: x, height: y)
            }
        } else if let shadowName = component.rawAttribute("textShadow") as? String,
                  let color = DynamicHelpers.getColor(shadowName) {
            shadowColor = color
        }

        let declaredSelected = resolveSelected(component: component, data: data)

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
                    isSelected: declaredSelected,
                    action: {
                        DynamicEventHelper.call(component.onClick, data: data)
                    }
                )
            )
        } else {
            // IconLabelView (no action)
            let isSelected = declaredSelected ?? false
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
                    isSelected: isSelected,
                    fontWeight: fontWeight,
                    textShadowColor: shadowColor,
                    textShadowRadius: shadowRadius,
                    textShadowOffset: shadowOffset
                )
            )
        }

        // applyStandardModifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private

    /// The `selected` state the layout declared, or `nil` when it declared
    /// none.
    ///
    /// `selected` is the canonical spelling (SSoT). This converter used to
    /// read `isOn`, which IconLabel never declares and `DynamicComponent`
    /// only decodes for the selection controls — so a declared `selected`
    /// never reached the view. With the state frozen at false,
    /// `selectedFontColor` and `icon_on` were unreachable too, which is why
    /// the two arrived paired in the 34 queue.
    ///
    /// The `nil` case is load-bearing: it is what lets `IconLabelButton`
    /// keep its own toggle state instead of following a binding it was never
    /// given.
    static func resolveSelected(component: DynamicComponent, data: [String: Any]) -> Bool? {
        switch component.typedAttributes(IconLabelAttributes.self).selected {
        case .binding(let expr):
            return DynamicBindingHelper.resolveBool("@{\(expr)}", data: data, fallback: false)
        case .value(let v):
            return v
        case nil:
            // Pre-SSoT layouts that spelled it `isOn` keep working.
            return component.isOn
        }
    }

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
