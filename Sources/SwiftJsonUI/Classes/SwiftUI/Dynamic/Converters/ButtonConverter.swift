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
        
        // Debug logging for Button properties
        print("🔘 [ButtonConverter] Creating button with:")
        print("  - id: \(component.id ?? "no-id")")
        print("  - width: \(String(describing: component.width)) (raw: \(component.widthRaw ?? "nil"))")
        print("  - height: \(String(describing: component.height)) (raw: \(component.heightRaw ?? "nil"))")
        print("  - minWidth: \(String(describing: component.minWidth))")
        print("  - maxWidth: \(String(describing: component.maxWidth))")
        print("  - minHeight: \(String(describing: component.minHeight))")
        print("  - maxHeight: \(String(describing: component.maxHeight))")
        print("  - padding: \(String(describing: component.padding))")
        print("  - margin: \(String(describing: component.margin))")
        
        return AnyView(
            Button(action: {
                handleButtonAction(component: component, viewModel: viewModel)
            }) {
                // Check if width/height were actually specified with specific numeric values
                // wrapContent should not expand the button
                let isWrapContentWidth = component.widthRaw == "wrapContent"
                let isWrapContentHeight = component.heightRaw == "wrapContent"
                let hasExplicitWidth = component.width != nil && !isWrapContentWidth
                let hasExplicitHeight = component.height != nil && !isWrapContentHeight
                
                // Only expand to fill if button has explicit numeric size (not wrapContent)
                if hasExplicitWidth || hasExplicitHeight {
                    Text(text)
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .white)
                        .padding(DynamicHelpers.getPadding(from: component))
                        // Apply frame to Text to fill button area when button has explicit size
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text(text)
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .white)
                        .padding(DynamicHelpers.getPadding(from: component))
                        // No frame expansion for buttons without explicit size or with wrapContent
                }
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
        // Debug log the frame values being applied
        // Check if width/height were actually specified in JSON using raw values
        let isWrapContentWidth = component.widthRaw == "wrapContent"
        let isWrapContentHeight = component.heightRaw == "wrapContent"
        let hasWidthSpec = component.widthRaw != nil && !isWrapContentWidth
        let hasHeightSpec = component.heightRaw != nil && !isWrapContentHeight
        
        // For width: nil if infinity, wrapContent, or not specified, otherwise use the value
        let width = (hasWidthSpec && component.width != nil && component.width != .infinity) ? component.width : nil
        // For height: use the value if it was specified and is not infinity or wrapContent
        let height = (hasHeightSpec && component.height != nil && component.height != .infinity) ? component.height : nil
        // For maxWidth: infinity if width is infinity, otherwise use maxWidth if specified (but not for wrapContent)
        let maxWidth = (component.width == .infinity) ? CGFloat.infinity : (isWrapContentWidth ? nil : component.maxWidth)
        // For maxHeight: infinity if height is infinity, otherwise use maxHeight if specified (but not for wrapContent)
        let maxHeight = (component.height == .infinity) ? CGFloat.infinity : (isWrapContentHeight ? nil : component.maxHeight)
        
        print("🔘 [ButtonModifiers] Applying frame:")
        print("  - component.width raw: \(String(describing: component.width))")
        print("  - component.height raw: \(String(describing: component.height))")
        print("  - width to apply: \(String(describing: width))")
        print("  - height to apply: \(String(describing: height))")
        print("  - minWidth: \(String(describing: component.minWidth))")
        print("  - maxWidth: \(String(describing: maxWidth))")
        print("  - minHeight: \(String(describing: component.minHeight))")
        print("  - maxHeight: \(String(describing: maxHeight))")
        
        // Apply frame modifiers based on what was actually specified
        var modifiedContent = AnyView(content)
        
        // Apply min/max constraints if any were specified
        if component.minWidth != nil || maxWidth != nil || component.minHeight != nil || maxHeight != nil {
            modifiedContent = AnyView(
                modifiedContent.frame(
                    minWidth: component.minWidth,
                    maxWidth: maxWidth,
                    minHeight: component.minHeight,
                    maxHeight: maxHeight
                )
            )
        }
        
        // Apply exact size only if specified
        if width != nil || height != nil {
            modifiedContent = AnyView(
                modifiedContent.frame(
                    width: width,
                    height: height
                )
            )
        }
        
        return modifiedContent
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
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
