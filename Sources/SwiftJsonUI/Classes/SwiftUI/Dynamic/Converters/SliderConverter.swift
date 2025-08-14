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
        let minValue = component.minValue ?? 0.0
        let maxValue = component.maxValue ?? 1.0
        
        // Check if component id matches a data property
        var binding: SwiftUI.Binding<Double>?
        if let componentId = component.id {
            // Try to find a matching slider property in data dictionary
            // Common patterns: slider1Value, slider1_value, etc.
            let possibleKeys = [
                "\(componentId)Value",
                "\(componentId)_value",
                componentId
            ]
            
            for key in possibleKeys {
                if viewModel.data[key] != nil {
                    // Create binding that updates the data dictionary
                    binding = SwiftUI.Binding<Double>(
                        get: { 
                            viewModel.data[key] as? Double ?? 0.5
                        },
                        set: { newValue in
                            viewModel.data[key] = newValue
                            viewModel.objectWillChange.send()
                        }
                    )
                    break
                }
            }
        }
        
        // Use binding if found, otherwise use static value
        let sliderBinding = binding ?? .constant(component.value ?? 0.5)
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                if let text = component.text {
                    Text(viewModel.processText(text))
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                }
                
                Slider(value: sliderBinding, in: minValue...maxValue)
                    .tint(DynamicHelpers.colorFromHex(component.iconColor ?? component.fontColor) ?? .accentColor)
            }
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}