//
//  PickerConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Picker
//

import SwiftUI

public struct PickerConverter {
    
    /// Convert DynamicComponent to SwiftUI Picker
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let items = component.items ?? []
        let label = viewModel.processText(component.text) ?? "Select"
        
        // Check if component id matches a data property
        var binding: SwiftUI.Binding<String>?
        if let componentId = component.id {
            // Try to find a matching picker property in data dictionary
            // Common patterns: picker1SelectedItem, picker1_selectedItem, picker1Selected, etc.
            let possibleKeys = [
                "\(componentId)SelectedItem",
                "\(componentId)_selectedItem",
                "\(componentId)Selected",
                "\(componentId)_selected",
                "\(componentId)Value",
                "\(componentId)_value",
                componentId
            ]
            
            for key in possibleKeys {
                if viewModel.data[key] != nil {
                    // Create binding that updates the data dictionary
                    binding = SwiftUI.Binding<String>(
                        get: { 
                            viewModel.data[key] as? String ?? items.first ?? ""
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
        let selectionBinding = binding ?? .constant(component.selectedItem ?? items.first ?? "")
        
        var picker = AnyView(
            Picker(label, selection: selectionBinding) {
                ForEach(items, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
        )
        
        if let font = DynamicHelpers.fontFromComponent(component) {
            picker = AnyView(picker.font(font))
        }
        
        return AnyView(
            picker.modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}