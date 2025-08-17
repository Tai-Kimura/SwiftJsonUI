//
//  ButtonConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Button view
//

import SwiftUI

// Dynamic mode button converter
// Generated code equivalent: sjui_tools/lib/swiftui/views/button_converter.rb
public struct ButtonConverter {
    
    /// Convert DynamicComponent to SwiftUI Button view
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = viewModel.processText(component.text) ?? ""
        
        return AnyView(
            Button(action: {
                handleButtonAction(component: component, viewModel: viewModel)
            }) {
                Text(text)
                    .font(DynamicHelpers.fontFromComponent(component))
                    .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .white)
                    .frame(maxWidth: component.width == .infinity ? .infinity : nil)
                    .padding(DynamicHelpers.getPadding(from: component))
            }
            .buttonStyle(getDynamicButtonStyle(component))
            .modifier(ButtonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func handleButtonAction(component: DynamicComponent, viewModel: DynamicViewModel) {
        // Debug: Print all keys in data dictionary
        print("📘 [ButtonConverter] Data dictionary keys: \(viewModel.data.keys.sorted())")
        print("📘 [ButtonConverter] Data dictionary count: \(viewModel.data.count)")
        
        // Debug: Print values and types
        for (key, value) in viewModel.data {
            let valueType = String(describing: type(of: value))
            print("📘 [ButtonConverter] data[\"\(key)\"] = \(valueType)")
        }
        
        // Check onclick (lowercase) - this is usually the action name from JSON
        if let action = component.onclick {
            print("📘 [ButtonConverter] Looking for onclick action: \(action)")
            // First check if it exists as a closure in data dictionary
            // Note: Closures might return Optional<()> due to weak references
            if let closure = viewModel.data[action] as? () -> Void {
                print("📘 [ButtonConverter] Found closure (Void) for action: \(action)")
                // Execute the closure from data dictionary
                closure()
            } else if let closure = viewModel.data[action] as? () -> Void? {
                print("📘 [ButtonConverter] Found closure (Optional) for action: \(action)")
                // Execute the closure from data dictionary
                closure()
            } else {
                print("📘 [ButtonConverter] No closure found, calling handleAction: \(action)")
                // Fall back to handleAction for navigation
                viewModel.handleAction(action)
            }
        }
        // Check onClick (camelCase) for backward compatibility
        else if let action = component.onClick {
            if let closure = viewModel.data[action] as? () -> Void {
                // Execute the closure from data dictionary
                closure()
            } else if let closure = viewModel.data[action] as? () -> Void? {
                // Execute the closure from data dictionary
                closure()
            } else {
                // Fall back to handleAction for navigation
                viewModel.handleAction(action)
            }
        }
        
        // Handle action property
        if let action = component.action {
            if let closure = viewModel.data[action] as? () -> Void {
                // Execute the closure from data dictionary
                closure()
            } else if let closure = viewModel.data[action] as? () -> Void? {
                // Execute the closure from data dictionary
                closure()
            } else {
                // Fall back to handleAction
                viewModel.handleAction(action)
            }
        }
    }
    
    
    
    private static func getDynamicButtonStyle(_ component: DynamicComponent) -> some ButtonStyle {
        DynamicButtonStyle(
            backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? .blue,
            cornerRadius: component.cornerRadius ?? 8
        )
    }
}

// MARK: - Button Modifiers (without background/cornerRadius which are handled by ButtonStyle)
// Generated code equivalent: sjui_tools/lib/swiftui/views/button_converter.rb:58-59 (apply_margins)
struct ButtonModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            // Apply frame size and constraints
            .frame(
                width: (component.width != nil && component.width != .infinity) ? component.width : nil,
                height: (component.height != nil && component.height != .infinity) ? component.height : nil
            )
            .frame(
                minWidth: component.minWidth,
                maxWidth: (component.width == .infinity) ? .infinity : component.maxWidth,
                minHeight: component.minHeight,
                maxHeight: (component.height == .infinity) ? .infinity : component.maxHeight
            )
            // Apply margins only (background and cornerRadius are handled by DynamicButtonStyle)
            .padding(DynamicHelpers.getMargins(from: component))
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1)
            .disabled(isDisabled())
    }
    
    private func isDisabled() -> Bool {
        // Check enabled property
        if let enabled = component.enabled {
            // Check if it's a string with data binding
            if let enabledString = enabled.value as? String {
                if enabledString.hasPrefix("@{") && enabledString.hasSuffix("}") {
                    // Extract property name
                    let startIndex = enabledString.index(enabledString.startIndex, offsetBy: 2)
                    let endIndex = enabledString.index(enabledString.endIndex, offsetBy: -1)
                    let propertyName = String(enabledString[startIndex..<endIndex])
                    
                    // Get value from viewModel
                    if let value = viewModel.data[propertyName] as? Bool {
                        return !value  // disabled is the opposite of enabled
                    } else if let value = viewModel.variables[propertyName] as? Bool {
                        return !value
                    } else if let stringValue = viewModel.data[propertyName] as? String {
                        return stringValue.lowercased() != "true"
                    } else if let stringValue = viewModel.variables[propertyName] as? String {
                        return stringValue.lowercased() != "true"
                    }
                    // Default to enabled if property not found
                    return false
                } else {
                    // Static string value
                    return enabledString.lowercased() != "true"
                }
            } else if let enabledBool = enabled.value as? Bool {
                return !enabledBool
            }
        }
        return false  // Default to enabled
    }
}

// MARK: - Custom Button Style
struct DynamicButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
