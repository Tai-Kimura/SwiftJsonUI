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
        let text = viewModel.processText(component.text) ?? ""
        
        // For toggle, check if the component id matches a data property
        if let componentId = component.id {
            // Try to find a matching toggle property in data dictionary
            // Common patterns: toggle1IsOn, checkbox1IsOn, etc.
            let possibleKeys = [
                "\(componentId)IsOn",
                "\(componentId)_isOn",
                componentId
            ]
            
            for key in possibleKeys {
                if viewModel.data[key] != nil {
                    // Create binding that updates the data dictionary
                    let binding = SwiftUI.Binding<Bool>(
                        get: { 
                            viewModel.data[key] as? Bool ?? false
                        },
                        set: { newValue in
                            viewModel.data[key] = newValue
                            viewModel.objectWillChange.send()
                            // Handle onValueChange event
                            if let onValueChange = component.onValueChange {
                                viewModel.handleAction(onValueChange)
                            }
                        }
                    )
                    
                    var toggle = Toggle(text, isOn: binding)
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                        .toggleStyle(SwitchToggleStyle())
                    if let font = DynamicHelpers.fontFromComponent(component) {
                        toggle = toggle.font(font)
                    }
                    
                    // Apply tint color if specified
                    if let tintColor = component.tint ?? component.tintColor,
                       let color = DynamicHelpers.colorFromHex(tintColor) {
                        return AnyView(
                            toggle
                                .tint(color)
                                .modifier(CommonModifiers(component: component, viewModel: viewModel))
                        )
                    } else {
                        return AnyView(
                            toggle
                                .modifier(CommonModifiers(component: component, viewModel: viewModel))
                        )
                    }
                }
            }
        }
        
        // Use static value if no binding found
        let isOn = component.isOn ?? false
        
        var toggle = Toggle(text, isOn: .constant(isOn))
            .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
            .toggleStyle(SwitchToggleStyle())
        if let font = DynamicHelpers.fontFromComponent(component) {
            toggle = toggle.font(font)
        }
        
        // Apply tint color if specified
        if let tintColor = component.tint ?? component.tintColor,
           let color = DynamicHelpers.colorFromHex(tintColor) {
            return AnyView(
                toggle
                    .tint(color)
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        } else {
            return AnyView(
                toggle
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
    }
}