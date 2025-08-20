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
        let text = viewModel.processText(component.text ?? component.label) ?? ""
        
        // Check if component id matches a data property
        var isChecked = component.checked ?? component.isOn ?? false
        var binding: SwiftUI.Binding<Bool>?
        
        if let componentId = component.id {
            // Try to find a matching checkbox property in data dictionary
            // Common patterns: checkbox1IsOn, checkbox1_isOn, checkbox1Checked, etc.
            let possibleKeys = [
                "\(componentId)IsOn",
                "\(componentId)_isOn",
                "\(componentId)Checked",
                "\(componentId)_checked",
                componentId
            ]
            
            for key in possibleKeys {
                if viewModel.data[key] != nil {
                    // Create binding that updates the data dictionary
                    binding = SwiftUI.Binding<Bool>(
                        get: { 
                            viewModel.data[key] as? Bool ?? false
                        },
                        set: { newValue in
                            viewModel.data[key] = newValue
                            // Removed objectWillChange.send() - @Published will handle notification
                        }
                    )
                    isChecked = viewModel.data[key] as? Bool ?? false
                    break
                }
            }
        }
        
        // Use binding if found for interactive checkbox
        if let binding = binding {
            return AnyView(
                HStack {
                    // Use custom onSrc image if provided, otherwise use system image
                    Group {
                        if let onSrc = component.onSrc, binding.wrappedValue {
                            Image(onSrc)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: binding.wrappedValue ? "checkmark.square.fill" : "square")
                                .foregroundColor(.blue)
                        }
                    }
                    .onTapGesture {
                        binding.wrappedValue.toggle()
                        // Handle checkbox tap actions
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
                        let textColor = DynamicHelpers.colorFromHex(component.fontColor) ?? .primary
                        if let font = DynamicHelpers.fontFromComponent(component) {
                            Text(text)
                                .font(font)
                                .foregroundColor(textColor)
                        } else {
                            Text(text)
                                .foregroundColor(textColor)
                        }
                    }
                }
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        } else {
            // Use static value if no binding found
            return AnyView(
                HStack {
                    // Use custom onSrc image if provided, otherwise use system image
                    Group {
                        if let onSrc = component.onSrc, isChecked {
                            Image(onSrc)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                .foregroundColor(.blue)
                        }
                    }
                    .onTapGesture {
                        // Handle checkbox tap
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
                        let textColor = DynamicHelpers.colorFromHex(component.fontColor) ?? .primary
                        if let font = DynamicHelpers.fontFromComponent(component) {
                            Text(text)
                                .font(font)
                                .foregroundColor(textColor)
                        } else {
                            Text(text)
                                .foregroundColor(textColor)
                        }
                    }
                }
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
    }
}