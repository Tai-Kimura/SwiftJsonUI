//
//  SliderConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Slider
//

import SwiftUI
#if DEBUG


public struct SliderConverter {
    
    /// Convert DynamicComponent to SwiftUI Slider
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        // Use minimum/maximum if available, otherwise fall back to minValue/maxValue
        let minValue = Double(component.minimum ?? CGFloat(component.minValue ?? 0.0))
        let maxValue = Double(component.maximum ?? CGFloat(component.maxValue ?? 1.0))
        
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
                            // Removed objectWillChange.send() - @Published will handle notification
                        }
                    )
                    break
                }
            }
        }
        
        // Use binding if found, otherwise use static value
        let sliderBinding = binding ?? .constant(component.value ?? 0.5)
        
        let content = VStack(alignment: .leading, spacing: 8) {
            if let text = component.text {
                let processedText = viewModel.processText(text)
                let textColor = DynamicHelpers.colorFromHex(component.fontColor) ?? .primary
                
                if let font = DynamicHelpers.fontFromComponent(component) {
                    Text(processedText)
                        .font(font)
                        .foregroundColor(textColor)
                } else {
                    Text(processedText)
                        .foregroundColor(textColor)
                }
            }
            
            Slider(value: sliderBinding, in: minValue...maxValue)
                .tint(DynamicHelpers.colorFromHex(component.tintColor ?? component.tint ?? component.iconColor ?? component.fontColor) ?? .accentColor)
        }
        .modifier(CommonModifiers(component: component, viewModel: viewModel))
        
        return AnyView(content)
    }
}
#endif // DEBUG
