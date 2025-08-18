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
        let text = viewModel.processText(component.text) ?? ""
        
        // Check if component id matches a data property
        var isSelected = component.checked ?? component.isOn ?? false
        let group = component.group ?? "defaultRadioGroup"
        
        if let componentId = component.id {
            // Try to find a matching radio property in data dictionary
            // Common patterns: radioGroupSelected, radio1IsSelected, etc.
            let possibleKeys = [
                "\(componentId)IsSelected",
                "\(componentId)_isSelected",
                "\(componentId)Selected",
                "\(componentId)_selected",
                componentId
            ]
            
            for key in possibleKeys {
                if let dataValue = viewModel.data[key] as? Bool {
                    isSelected = dataValue
                    break
                } else if let stringValue = viewModel.data[key] as? String {
                    // For radio groups, check if this radio's value matches the selected value
                    isSelected = (stringValue == text || stringValue == componentId)
                    break
                }
            }
            
            // Also check for radio group selection (where value is stored in a parent group id)
            if let radioGroupKey = viewModel.data[group] as? String {
                isSelected = (radioGroupKey == componentId || radioGroupKey == text)
            } else if let radioGroupKey = viewModel.data["selectedRadio"] as? String {
                isSelected = (radioGroupKey == componentId || radioGroupKey == text)
            }
        }
        
        return AnyView(
            HStack {
                // Use custom icons if provided
                if let selectedIcon = component.selectedIcon, isSelected {
                    Image(selectedIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else if let icon = component.icon, !isSelected {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.blue)
                }
                    .onTapGesture {
                        // Update data if component has an id
                        if let componentId = component.id {
                            // Update this radio's selection state
                            viewModel.data[componentId] = true
                            // Update radio group selection
                            viewModel.data[group] = componentId
                            viewModel.data["selectedRadio"] = componentId  // Keep for backward compatibility
                            viewModel.objectWillChange.send()
                        }
                        
                        // Handle radio selection actions
                        if let onClick = component.onClick {
                            if let closure = viewModel.data[onClick] as? () -> Void {
                                closure()
                            } else {
                                viewModel.handleAction(onClick)
                            }
                        }
                        if let action = component.action {
                            if let closure = viewModel.data[action] as? () -> Void {
                                closure()
                            } else {
                                viewModel.handleAction(action)
                            }
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