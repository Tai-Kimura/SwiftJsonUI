//
//  DynamicIconLabelView.swift
//  SwiftJsonUI
//
//  Dynamic icon label component
//

import SwiftUI

struct DynamicIconLabelView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let hasAction = component.action != nil
        
        if hasAction {
            IconLabelButton(
                text: component.text ?? "",
                iconOn: component.iconOn,
                iconOff: component.iconOff,
                iconPosition: DynamicHelpers.iconPositionFromString(component.iconPosition),
                fontSize: component.fontSize ?? 16,
                fontColor: DynamicHelpers.colorFromHex(component.iconColor) ?? DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                fontName: component.font,
                action: { viewModel.handleAction(component.action) }
            )
        } else {
            IconLabelView(
                text: component.text ?? "",
                iconOn: component.iconOn,
                iconOff: component.iconOff,
                iconPosition: DynamicHelpers.iconPositionFromString(component.iconPosition),
                fontSize: component.fontSize ?? 16,
                fontColor: DynamicHelpers.colorFromHex(component.iconColor) ?? DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                fontName: component.font
            )
        }
    }
}