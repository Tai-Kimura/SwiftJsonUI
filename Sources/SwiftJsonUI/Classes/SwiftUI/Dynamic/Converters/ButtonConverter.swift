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
                    .padding(getButtonPadding(component))
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
    
    
    private static func getButtonPadding(_ component: DynamicComponent) -> EdgeInsets {
        // Get padding value from AnyCodable
        var paddingValue: CGFloat? = nil
        if let padding = component.padding {
            if let intValue = padding.value as? Int {
                paddingValue = CGFloat(intValue)
            } else if let doubleValue = padding.value as? Double {
                paddingValue = CGFloat(doubleValue)
            } else if let floatValue = padding.value as? CGFloat {
                paddingValue = floatValue
            }
        }
        
        // If padding is specified, use it for all sides
        if let padding = paddingValue {
            return EdgeInsets(
                top: component.paddingTop ?? component.topPadding ?? padding,
                leading: component.paddingLeft ?? component.leftPadding ?? padding,
                bottom: component.paddingBottom ?? component.bottomPadding ?? padding,
                trailing: component.paddingRight ?? component.rightPadding ?? padding
            )
        }
        
        // No padding specified - button should have no internal padding
        // (background and cornerRadius are applied by DynamicButtonStyle)
        return EdgeInsets(
            top: component.paddingTop ?? component.topPadding ?? 0,
            leading: component.paddingLeft ?? component.leftPadding ?? 0,
            bottom: component.paddingBottom ?? component.bottomPadding ?? 0,
            trailing: component.paddingRight ?? component.rightPadding ?? 0
        )
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
            // Apply margins only (background and cornerRadius are handled by DynamicButtonStyle)
            .padding(getMargins())
            .opacity(getOpacity())
            .opacity(isHidden() ? 0 : 1)
    }
    
    private func getMargins() -> EdgeInsets {
        // Use margin properties for outer spacing
        let top = component.topMargin ?? 0
        let leading = component.leftMargin ?? 0
        let bottom = component.bottomMargin ?? 0
        let trailing = component.rightMargin ?? 0
        
        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
    
    private func getOpacity() -> Double {
        if let opacity = component.opacity {
            return Double(opacity)
        }
        if let alpha = component.alpha {
            return Double(alpha)
        }
        return 1.0
    }
    
    private func isHidden() -> Bool {
        return component.hidden == true || component.visibility == "gone"
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
