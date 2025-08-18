//
//  SegmentConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Segmented Control
//

import SwiftUI

public struct SegmentConverter {
    
    /// Convert DynamicComponent to SwiftUI Segmented Control (Picker)
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let items = component.items ?? []
        let selectedIndex = component.selectedIndex ?? 0
        
        // Create binding for selected index
        var binding: SwiftUI.Binding<Int>
        if let componentId = component.id {
            // Try to find a matching property in data dictionary
            let possibleKeys = [
                "\(componentId)SelectedIndex",
                "\(componentId)_selectedIndex",
                "\(componentId)Index",
                componentId
            ]
            
            var foundBinding = false
            for key in possibleKeys {
                if viewModel.data[key] != nil {
                    binding = SwiftUI.Binding<Int>(
                        get: { 
                            viewModel.data[key] as? Int ?? 0
                        },
                        set: { newValue in
                            viewModel.data[key] = newValue
                            viewModel.objectWillChange.send()
                            // Handle valueChange event
                            if let valueChange = component.onChange {
                                viewModel.handleAction(valueChange)
                            }
                        }
                    )
                    foundBinding = true
                    break
                }
            }
            
            if !foundBinding {
                binding = .constant(selectedIndex)
            }
        } else {
            binding = .constant(selectedIndex)
        }
        
        return AnyView(
            Picker("", selection: binding) {
                ForEach(0..<items.count, id: \.self) { index in
                    Text(items[index])
                        .tag(index)
                        .foregroundColor(getTextColor(component, isSelected: binding.wrappedValue == index))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(component.enabled == false)
            .accentColor(getTintColor(component))
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func getTextColor(_ component: DynamicComponent, isSelected: Bool) -> Color {
        if isSelected {
            if let selectedColor = component.selectedColor {
                return DynamicHelpers.colorFromHex(selectedColor) ?? .primary
            }
        } else {
            if let normalColor = component.normalColor {
                return DynamicHelpers.colorFromHex(normalColor) ?? .primary
            }
        }
        return .primary
    }
    
    private static func getTintColor(_ component: DynamicComponent) -> Color? {
        if let tintColor = component.tintColor ?? component.tint {
            return DynamicHelpers.colorFromHex(tintColor)
        }
        return nil
    }
}