//
//  TextFieldConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextField
//

import SwiftUI

public struct TextFieldConverter {
    
    /// Extract property name from @{propertyName} syntax
    private static func extractPropertyName(from value: String?) -> String? {
        guard let value = value,
              value.hasPrefix("@{") && value.hasSuffix("}") else {
            return nil
        }
        let startIndex = value.index(value.startIndex, offsetBy: 2)
        let endIndex = value.index(value.endIndex, offsetBy: -1)
        return String(value[startIndex..<endIndex])
    }
    
    
    /// Convert DynamicComponent to SwiftUI TextField
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let placeholder = component.hint ?? component.placeholder ?? ""
        
        // Check if text has @{} binding syntax
        if let propertyName = extractPropertyName(from: component.text) {
            // Get value from data dictionary
            let value = viewModel.data[propertyName] as? String ?? ""
            
            // Create binding that updates the data dictionary
            let binding = SwiftUI.Binding<String>(
                get: { value },
                set: { newValue in
                    viewModel.data[propertyName] = newValue
                    viewModel.objectWillChange.send()
                }
            )
            
            // Choose between TextField and SecureField based on secure property
            if component.secure == true {
                return createSecureField(placeholder: placeholder, text: binding, component: component, viewModel: viewModel)
            } else {
                return createTextField(placeholder: placeholder, text: binding, component: component, viewModel: viewModel)
            }
        } else {
            // Use static text if no binding
            let text = component.text ?? ""
            
            // Choose between TextField and SecureField based on secure property
            if component.secure == true {
                return createSecureField(placeholder: placeholder, text: .constant(text), component: component, viewModel: viewModel)
            } else {
                return createTextField(placeholder: placeholder, text: .constant(text), component: component, viewModel: viewModel)
            }
        }
    }
    
    // Helper function to get keyboard type
    private static func getKeyboardType(from input: String?) -> UIKeyboardType {
        switch input?.lowercased() {
        case "email", "emailaddress":
            return .emailAddress
        case "number", "numeric":
            return .numberPad
        case "phone", "phonenumber":
            return .phonePad
        case "decimal", "decimalpad":
            return .decimalPad
        case "url", "weburl":
            return .URL
        case "twitter":
            return .twitter
        case "websearch":
            return .webSearch
        case "ascii":
            return .asciiCapable
        default:
            return .default
        }
    }
    
    // Helper function to get submit label
    private static func getSubmitLabel(from returnKeyType: String?) -> SubmitLabel {
        switch returnKeyType?.lowercased() {
        case "done":
            return .done
        case "go":
            return .go
        case "next":
            return .next
        case "return":
            return .return
        case "search":
            return .search
        case "send":
            return .send
        case "continue":
            return .continue
        case "join":
            return .join
        case "route":
            return .route
        default:
            return .done
        }
    }
    
    // Helper function to create TextField with proper style
    private static func createTextField(
        placeholder: String,
        text: SwiftUI.Binding<String>,
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let borderStyle = component.borderStyle?.lowercased()
        
        switch borderStyle {
        case "roundedrect", "rounded":
            var textField = AnyView(
                TextField(placeholder, text: text)
                    .keyboardType(getKeyboardType(from: component.input))
                    .submitLabel(getSubmitLabel(from: component.returnKeyType))
                    .onChange(of: text.wrappedValue) { _ in
                        // onTextChange is handled in binding setter
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            )
            
            // Apply font if specified
            if let font = DynamicHelpers.fontFromComponent(component) {
                textField = AnyView(textField.font(font))
            }
            
            // Apply foreground color
            if let fontColor = component.fontColor {
                textField = AnyView(textField.foregroundColor(DynamicHelpers.colorFromHex(fontColor) ?? .primary))
            }
            
            return AnyView(textField.modifier(CommonModifiers(component: component, viewModel: viewModel)))
        case "plain", "none":
            var textField = AnyView(
                TextField(placeholder, text: text)
                    .keyboardType(getKeyboardType(from: component.input))
                    .submitLabel(getSubmitLabel(from: component.returnKeyType))
                    .onChange(of: text.wrappedValue) { _ in
                        // onTextChange is handled in binding setter
                    }
                    .textFieldStyle(PlainTextFieldStyle())
            )
            
            // Apply font if specified
            if let font = DynamicHelpers.fontFromComponent(component) {
                textField = AnyView(textField.font(font))
            }
            
            // Apply foreground color
            if let fontColor = component.fontColor {
                textField = AnyView(textField.foregroundColor(DynamicHelpers.colorFromHex(fontColor) ?? .primary))
            }
            
            return AnyView(textField.modifier(CommonModifiers(component: component, viewModel: viewModel)))
        default:
            // Default style based on platform
            #if os(iOS)
            var textField = AnyView(
                TextField(placeholder, text: text)
                    .keyboardType(getKeyboardType(from: component.input))
                    .submitLabel(getSubmitLabel(from: component.returnKeyType))
                    .onChange(of: text.wrappedValue) { _ in
                        // onTextChange is handled in binding setter
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            )
            #else
            var textField = AnyView(
                TextField(placeholder, text: text)
                    .keyboardType(getKeyboardType(from: component.input))
                    .submitLabel(getSubmitLabel(from: component.returnKeyType))
                    .onChange(of: text.wrappedValue) { _ in
                        // onTextChange is handled in binding setter
                    }
                    .textFieldStyle(PlainTextFieldStyle())
            )
            #endif
            
            // Apply font if specified
            if let font = DynamicHelpers.fontFromComponent(component) {
                textField = AnyView(textField.font(font))
            }
            
            // Apply foreground color
            if let fontColor = component.fontColor {
                textField = AnyView(textField.foregroundColor(DynamicHelpers.colorFromHex(fontColor) ?? .primary))
            }
            
            return AnyView(textField.modifier(CommonModifiers(component: component, viewModel: viewModel)))
        }
    }
    
    // Helper function to create SecureField with proper style
    private static func createSecureField(
        placeholder: String,
        text: SwiftUI.Binding<String>,
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let borderStyle = component.borderStyle?.lowercased()
        
        switch borderStyle {
        case "roundedrect", "rounded":
            var secureField = AnyView(
                SecureField(placeholder, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            )
            
            // Apply font if specified
            if let font = DynamicHelpers.fontFromComponent(component) {
                secureField = AnyView(secureField.font(font))
            }
            
            // Apply foreground color
            if let fontColor = component.fontColor {
                secureField = AnyView(secureField.foregroundColor(DynamicHelpers.colorFromHex(fontColor) ?? .primary))
            }
            
            return AnyView(secureField.modifier(CommonModifiers(component: component, viewModel: viewModel)))
        case "plain", "none":
            var secureField = AnyView(
                SecureField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
            )
            
            // Apply font if specified
            if let font = DynamicHelpers.fontFromComponent(component) {
                secureField = AnyView(secureField.font(font))
            }
            
            // Apply foreground color
            if let fontColor = component.fontColor {
                secureField = AnyView(secureField.foregroundColor(DynamicHelpers.colorFromHex(fontColor) ?? .primary))
            }
            
            return AnyView(secureField.modifier(CommonModifiers(component: component, viewModel: viewModel)))
        default:
            // Default style based on platform
            #if os(iOS)
            var secureField = AnyView(
                SecureField(placeholder, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            )
            #else
            var secureField = AnyView(
                SecureField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
            )
            #endif
            
            // Apply font if specified
            if let font = DynamicHelpers.fontFromComponent(component) {
                secureField = AnyView(secureField.font(font))
            }
            
            // Apply foreground color
            if let fontColor = component.fontColor {
                secureField = AnyView(secureField.foregroundColor(DynamicHelpers.colorFromHex(fontColor) ?? .primary))
            }
            
            return AnyView(secureField.modifier(CommonModifiers(component: component, viewModel: viewModel)))
        }
    }
}