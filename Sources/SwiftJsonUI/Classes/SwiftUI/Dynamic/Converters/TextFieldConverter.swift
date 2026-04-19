//
//  TextFieldConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of textfield_converter.rb
//  Creates TextField/SecureField matching tool-generated code exactly.
//
//  Modifier order (matches textfield_converter.rb):
//    1. TextField/SecureField creation
//    2. font modifiers (.font)
//    3. .multilineTextAlignment
//    4. .foregroundColor
//    5. .textFieldStyle
//    6. .keyboardType
//    7. .textContentType
//    8. .submitLabel
//    9. .disabled (enabled == false)
//   10. .tint (tintColor / caretAttributes)
//   11. .padding(.leading, textPaddingLeft)
//   12. .onChange (onTextChange)
//   13. .focused
//   14. .onSubmit (nextFocus)
//   15. apply_padding
//   16. apply_frame_constraints
//   17. apply_frame_size
//   18. .background
//   19. .cornerRadius
//   20. .border overlay
//   21. apply_margins
//   22. .opacity
//   23. .shadow
//   24. .clipped
//   25. .offset
//   26. .hidden
//   27. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct TextFieldConverter {

    /// Convert DynamicComponent to SwiftUI TextField/SecureField
    /// Matches textfield_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let placeholder: String = {
            let raw = component.hint ?? component.placeholder ?? ""
            if let propName = DynamicEventHelper.extractPropertyName(from: raw) {
                if let binding = data[propName] as? SwiftUI.Binding<String> {
                    return binding.wrappedValue
                }
                if let value = data[propName] as? String {
                    return value
                }
            }
            return raw.dynamicLocalized()
        }()
        let id = component.id ?? "textField"

        // --- 1. Get text binding ---
        let textBinding = DynamicBindingHelper.string(component.text, data: data, fallback: "")

        // Check if it should be a SecureField
        let isSecure: Bool = {
            if let secure = component.secure { return secure }
            return component.input?.lowercased() == "password"
        }()

        // Use FocusableTextField when component has an id (for focus chain support)
        if let fieldId = component.id {
            return createFocusableTextField(
                placeholder: placeholder,
                text: textBinding,
                fieldId: fieldId,
                isSecure: isSecure,
                component: component,
                data: data
            )
        }

        // --- 1. Create base field ---
        var result: AnyView
        if isSecure {
            result = AnyView(SecureField(placeholder, text: textBinding))
        } else {
            result = AnyView(TextField(placeholder, text: textBinding))
        }

        // Apply all modifiers in textfield_converter.rb order
        return applyAllModifiers(result, component: component, data: data)
    }

    // MARK: - FocusableTextField path

    private static func createFocusableTextField(
        placeholder: String,
        text: SwiftUI.Binding<String>,
        fieldId: String,
        isSecure: Bool,
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let nextFocusId = component.rawData["nextFocus"] as? String

        var result = AnyView(
            FocusableTextField(
                placeholder: placeholder,
                text: text,
                fieldId: fieldId,
                isSecure: isSecure,
                keyboardType: getKeyboardType(from: component.input),
                submitLabel: getSubmitLabel(from: component.returnKeyType),
                textAlignment: DynamicHelpers.getTextAlignment(from: component),
                nextFocusId: nextFocusId
            )
        )

        // Apply modifiers in textfield_converter.rb order
        // (FocusableTextField handles focused/onSubmit internally)

        // --- 2. font ---
        if let font = DynamicHelpers.fontFromComponent(component) {
            result = AnyView(result.font(font))
        }

        // --- 4. foregroundColor ---
        if let fontColor = component.fontColor {
            result = AnyView(result.foregroundColor(DynamicHelpers.getColor(fontColor) ?? .primary))
        }

        // --- 5. textFieldStyle ---
        result = applyTextFieldStyle(result, component: component)

        // --- 9. disabled ---
        if component.enabled?.value as? Bool == false {
            result = AnyView(result.disabled(true))
        }

        // --- 10. tint (tintColor / caretAttributes) ---
        let caretColor: Color? = {
            if let tintColor = component.tintColor, let c = DynamicHelpers.getColor(tintColor) { return c }
            if let caretAttrs = component.rawData["caretAttributes"] as? [String: Any],
               let caretFontColor = caretAttrs["fontColor"] as? String,
               let c = DynamicHelpers.getColor(caretFontColor) { return c }
            return nil
        }()
        if let color = caretColor {
            result = AnyView(result.tint(color))
        }

        // --- 11. textPaddingLeft ---
        if let textPaddingLeft = component.rawData["textPaddingLeft"] as? CGFloat {
            result = AnyView(result.padding(.leading, textPaddingLeft))
        }

        // --- 15. padding ---
        result = DynamicModifierHelper.applyPadding(result, component: component)

        // --- 16. frame_constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)

        // --- 17. frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 18. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 19. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component)

        // --- 20. border ---
        result = DynamicModifierHelper.applyBorder(result, component: component)

        // --- 21. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 22. opacity ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)

        // --- 23. shadow ---
        result = DynamicModifierHelper.applyShadow(result, component: component)

        // --- 24. clipped ---
        result = DynamicModifierHelper.applyClipped(result, component: component)

        // --- 25. offset ---
        result = DynamicModifierHelper.applyOffset(result, component: component)

        // --- 26. hidden ---
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 27. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }

    // MARK: - Standard TextField/SecureField modifier application

    private static func applyAllModifiers(
        _ view: AnyView,
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        var result = view

        // --- 2. font ---
        if let font = DynamicHelpers.fontFromComponent(component) {
            result = AnyView(result.font(font))
        }

        // --- 3. multilineTextAlignment ---
        if component.textAlign != nil {
            result = AnyView(result.multilineTextAlignment(DynamicHelpers.getTextAlignment(from: component)))
        }

        // --- 4. foregroundColor ---
        if let fontColor = component.fontColor {
            result = AnyView(result.foregroundColor(DynamicHelpers.getColor(fontColor) ?? .primary))
        }

        // --- 5. textFieldStyle ---
        result = applyTextFieldStyle(result, component: component)

        // --- 6. keyboardType ---
        let keyboardType = getKeyboardType(from: component.input)
        if keyboardType != .default {
            result = AnyView(result.keyboardType(keyboardType))
        }

        // --- 7. textContentType ---
        if let contentType = component.rawData["contentType"] as? String {
            result = applyContentType(result, contentType: contentType)
        }

        // --- 8. submitLabel ---
        if let returnKeyType = component.returnKeyType {
            result = AnyView(result.submitLabel(getSubmitLabel(from: returnKeyType)))
        }

        // --- 9. disabled ---
        if component.enabled?.value as? Bool == false {
            result = AnyView(result.disabled(true))
        }

        // --- 10. tint (tintColor / caretAttributes) ---
        let caretColor: Color? = {
            if let tintColor = component.tintColor, let c = DynamicHelpers.getColor(tintColor) { return c }
            if let caretAttrs = component.rawData["caretAttributes"] as? [String: Any],
               let caretFontColor = caretAttrs["fontColor"] as? String,
               let c = DynamicHelpers.getColor(caretFontColor) { return c }
            return nil
        }()
        if let color = caretColor {
            result = AnyView(result.tint(color))
        }

        // --- 11. textPaddingLeft ---
        if let textPaddingLeft = component.rawData["textPaddingLeft"] as? CGFloat {
            result = AnyView(result.padding(.leading, textPaddingLeft))
        }

        // --- 15. padding ---
        result = DynamicModifierHelper.applyPadding(result, component: component)

        // --- 16. frame_constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)

        // --- 17. frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 18. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 19. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component)

        // --- 20. border ---
        result = DynamicModifierHelper.applyBorder(result, component: component)

        // --- 21. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 22. opacity ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)

        // --- 23. shadow ---
        result = DynamicModifierHelper.applyShadow(result, component: component)

        // --- 24. clipped ---
        result = DynamicModifierHelper.applyClipped(result, component: component)

        // --- 25. offset ---
        result = DynamicModifierHelper.applyOffset(result, component: component)

        // --- 26. hidden ---
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 27. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }

    // MARK: - Helpers

    private static func applyTextFieldStyle(_ view: AnyView, component: DynamicComponent) -> AnyView {
        guard let borderStyle = component.borderStyle?.lowercased() else { return view }
        switch borderStyle {
        case "roundedrect", "rounded":
            return AnyView(view.textFieldStyle(.roundedBorder))
        case "plain", "none":
            return AnyView(view.textFieldStyle(.plain))
        default:
            return view
        }
    }

    private static func applyContentType(_ view: AnyView, contentType: String) -> AnyView {
        switch contentType {
        case "username": return AnyView(view.textContentType(.username))
        case "password": return AnyView(view.textContentType(.password))
        case "email": return AnyView(view.textContentType(.emailAddress))
        case "name": return AnyView(view.textContentType(.name))
        case "tel": return AnyView(view.textContentType(.telephoneNumber))
        case "postalCode": return AnyView(view.textContentType(.postalCode))
        default: return view
        }
    }

    private static func getKeyboardType(from input: String?) -> UIKeyboardType {
        switch input?.lowercased() {
        case "email", "emailaddress": return .emailAddress
        case "number", "numeric": return .numberPad
        case "phone", "phonenumber": return .phonePad
        case "decimal", "decimalpad": return .decimalPad
        case "url", "weburl": return .URL
        case "twitter": return .twitter
        case "websearch": return .webSearch
        case "ascii": return .asciiCapable
        case "namephonepad": return .namePhonePad
        default: return .default
        }
    }

    private static func getSubmitLabel(from returnKeyType: String?) -> SubmitLabel {
        switch returnKeyType {
        case "Done": return .done
        case "Go": return .go
        case "Next": return .next
        case "Return": return .return
        case "Search": return .search
        case "Send": return .send
        case "Continue": return .continue
        case "Join": return .join
        case "Route": return .route
        default: return .done
        }
    }
}
#endif // DEBUG
