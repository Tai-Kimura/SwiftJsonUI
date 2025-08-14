//
//  SliderConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Slider
//

import SwiftUI

public struct SliderConverter {
    
    /// Convert DynamicComponent to SwiftUI Slider
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let value = component.value ?? 0.5
        let minValue = component.minValue ?? 0.0
        let maxValue = component.maxValue ?? 1.0
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                if let text = component.text {
                    Text(text)
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                }
                
                Slider(value: .constant(value), in: minValue...maxValue)
                    .tint(DynamicHelpers.colorFromHex(component.iconColor ?? component.fontColor) ?? .accentColor)
            }
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}