//
//  ToggleConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Toggle
//

import SwiftUI

public struct ToggleConverter {
    
    /// Convert DynamicComponent to SwiftUI Toggle
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = component.text ?? ""
        let isOn = component.isOn ?? false
        
        return AnyView(
            Toggle(text, isOn: .constant(isOn))
                .font(DynamicHelpers.fontFromComponent(component))
                .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                .toggleStyle(SwitchToggleStyle())
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}