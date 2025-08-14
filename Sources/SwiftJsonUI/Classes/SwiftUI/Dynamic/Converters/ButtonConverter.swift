//
//  ButtonConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Button view
//

import SwiftUI

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
                    .padding(getButtonPadding(component))
            }
            .buttonStyle(getDynamicButtonStyle(component))
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
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
            if let closure = viewModel.data[action] as? () -> Void {
                print("📘 [ButtonConverter] Found closure for action: \(action)")
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
            } else {
                // Fall back to handleAction
                viewModel.handleAction(action)
            }
        }
    }
    
    
    private static func getButtonPadding(_ component: DynamicComponent) -> EdgeInsets {
        // Default button padding if not specified
        let defaultPadding: CGFloat = 12
        
        let top = component.paddingTop ?? component.topPadding ?? component.padding?.value as? CGFloat ?? defaultPadding
        let leading = component.paddingLeft ?? component.leftPadding ?? component.padding?.value as? CGFloat ?? defaultPadding * 2
        let bottom = component.paddingBottom ?? component.bottomPadding ?? component.padding?.value as? CGFloat ?? defaultPadding
        let trailing = component.paddingRight ?? component.rightPadding ?? component.padding?.value as? CGFloat ?? defaultPadding * 2
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    private static func getDynamicButtonStyle(_ component: DynamicComponent) -> some ButtonStyle {
        DynamicButtonStyle(
            backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? .blue,
            cornerRadius: component.cornerRadius ?? 8
        )
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
