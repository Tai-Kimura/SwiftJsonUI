//
//  TextFieldConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextField
//

import SwiftUI

// MARK: - TextField-specific modifiers (margins only)
// Corresponding to Generated code: textfield_converter.rb
struct TextFieldModifiers: ViewModifier {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    
    func body(content: Content) -> some View {
        content
            .padding(DynamicHelpers.getMargins(from: component))  // Apply margins as outer padding
            .opacity(DynamicHelpers.getOpacity(from: component))
            .opacity(DynamicHelpers.isHidden(component) ? 0 : 1)
    }
}

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
            let textFieldView: AnyView
            if component.secure == true {
                textFieldView = AnyView(
                    SecureField(placeholder, text: binding)
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                )
            } else {
                textFieldView = AnyView(
                    TextField(placeholder, text: binding)
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                        .keyboardType(getKeyboardType(from: component.input))
                        .submitLabel(getSubmitLabel(from: component.returnKeyType))
                )
            }
            
            return AnyView(
                textFieldView
                    .textFieldStyle(getTextFieldStyle(from: component.borderStyle))
                    .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
                    .background(DynamicHelpers.getBackground(from: component))
                    .cornerRadius(component.cornerRadius ?? 0)
                    .overlay(
                        Group {
                            if let borderWidth = component.borderWidth,
                               borderWidth > 0 {
                                let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
                                RoundedRectangle(cornerRadius: component.cornerRadius ?? 0)
                                    .stroke(borderColor, lineWidth: borderWidth)
                            }
                        }
                    )  // Border after cornerRadius, before margins
                    .modifier(TextFieldModifiers(component: component, viewModel: viewModel))  // Margins only
            )
        } else {
            // Use static text if no binding
            let text = component.text ?? ""
            
            // Choose between TextField and SecureField based on secure property
            let textFieldView: AnyView
            if component.secure == true {
                textFieldView = AnyView(
                    SecureField(placeholder, text: .constant(text))
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                )
            } else {
                textFieldView = AnyView(
                    TextField(placeholder, text: .constant(text))
                        .font(DynamicHelpers.fontFromComponent(component))
                        .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
                        .keyboardType(getKeyboardType(from: component.input))
                        .submitLabel(getSubmitLabel(from: component.returnKeyType))
                )
            }
            
            return AnyView(
                textFieldView
                    .textFieldStyle(getTextFieldStyle(from: component.borderStyle))
                    .padding(DynamicHelpers.getPadding(from: component))  // Internal padding
                    .background(DynamicHelpers.getBackground(from: component))
                    .cornerRadius(component.cornerRadius ?? 0)
                    .overlay(
                        Group {
                            if let borderWidth = component.borderWidth,
                               borderWidth > 0 {
                                let borderColor = DynamicHelpers.colorFromHex(component.borderColor) ?? .gray
                                RoundedRectangle(cornerRadius: component.cornerRadius ?? 0)
                                    .stroke(borderColor, lineWidth: borderWidth)
                            }
                        }
                    )  // Border after cornerRadius, before margins
                    .modifier(TextFieldModifiers(component: component, viewModel: viewModel))  // Margins only
            )
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
    
    // Helper function to get text field style
    private static func getTextFieldStyle(from borderStyle: String?) -> any TextFieldStyle {
        switch borderStyle?.lowercased() {
        case "roundedrect", "rounded":
            return RoundedBorderTextFieldStyle()
        case "plain", "none":
            return PlainTextFieldStyle()
        default:
            // Default style based on platform
            #if os(iOS)
            return RoundedBorderTextFieldStyle()
            #else
            return PlainTextFieldStyle()
            #endif
        }
    }
}