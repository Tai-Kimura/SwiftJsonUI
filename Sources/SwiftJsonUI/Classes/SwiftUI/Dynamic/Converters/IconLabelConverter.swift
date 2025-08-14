//
//  IconLabelConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI IconLabelView or IconLabelButton
//

import SwiftUI

public struct IconLabelConverter {
    
    /// Convert DynamicComponent to SwiftUI IconLabelView or IconLabelButton
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        let text = component.text ?? ""
        let iconOn = component.iconOn
        let iconOff = component.iconOff
        let iconPosition = getIconPosition(component.iconPosition)
        let isSelected = component.isOn ?? false
        
        // Determine if it's a button (has onClick or action)
        let hasAction = component.onClick != nil || component.action != nil
        
        if hasAction {
            // IconLabelButton
            return AnyView(
                IconLabelButton(
                    text: text,
                    iconOn: iconOn,
                    iconOff: iconOff,
                    iconPosition: iconPosition,
                    iconSize: component.fontSize ?? 24,
                    iconMargin: 5,
                    fontSize: component.fontSize ?? 16,
                    fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                    selectedFontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .accentColor,
                    fontName: component.font,
                    action: {
                        if let onClick = component.onClick {
                            viewModel.handleAction(onClick)
                        }
                        if let action = component.action {
                            viewModel.handleAction(action)
                        }
                    }
                )
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        } else {
            // IconLabelView
            return AnyView(
                IconLabelView(
                    text: text,
                    iconOn: iconOn,
                    iconOff: iconOff,
                    iconPosition: iconPosition,
                    iconSize: component.fontSize ?? 24,
                    iconMargin: 5,
                    fontSize: component.fontSize ?? 16,
                    fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                    selectedFontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .accentColor,
                    fontName: component.font,
                    isSelected: isSelected
                )
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
    }
    
    private static func getIconPosition(_ position: String?) -> IconLabelView.IconPosition {
        guard let position = position else { return .left }
        
        switch position.lowercased() {
        case "top":
            return .top
        case "right":
            return .right
        case "bottom":
            return .bottom
        default:
            return .left
        }
    }
}