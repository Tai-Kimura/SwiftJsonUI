//
//  RadioConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Radio Button
//

import SwiftUI

public struct RadioConverter {
    
    /// Convert DynamicComponent to SwiftUI Radio Button
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel,
        viewId: String? = nil
    ) -> AnyView {
        let id = component.id ?? "radio"
        let text = component.text ?? ""
        let isSelected = component.isOn ?? false
        
        return AnyView(
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(.blue)
                    .onTapGesture {
                        // Handle radio selection
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
            .disabled(component.userInteractionEnabled == false)
            .opacity((component.userInteractionEnabled == false) ? 0.6 : 1.0)
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}