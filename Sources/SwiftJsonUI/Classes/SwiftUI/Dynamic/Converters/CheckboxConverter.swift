//
//  CheckboxConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Checkbox
//

import SwiftUI

public struct CheckboxConverter {
    
    /// Convert DynamicComponent to SwiftUI Checkbox
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = component.text ?? ""
        let isOn = component.isOn ?? false
        
        return AnyView(
            HStack {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(.blue)
                    .onTapGesture {
                        // Handle checkbox tap
                        if let onClick = component.onClick {
                            viewModel.handleAction(onClick)
                        }
                        if let action = component.action {
                            viewModel.handleAction(action)
                        }
                    }
                
                if !text.isEmpty {
                    Text(text)
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                }
            }
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}