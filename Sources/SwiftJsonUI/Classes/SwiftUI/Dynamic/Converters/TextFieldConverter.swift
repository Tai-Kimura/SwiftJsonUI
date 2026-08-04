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

        // Placeholder styling (hintColor / placeholderColor / hintFont /
        // hintFontSize). Empty when the layout declared none, in which case
        // the native placeholder is left exactly as it was.
        let hintStyle = placeholderStyle(component: component, data: data)
        // The native field must not draw a placeholder we are overlaying.
        let nativePlaceholder = hintStyle.isEmpty ? placeholder : ""
        let hintAlignment = textFieldPlaceholderAlignment(
            for: DynamicHelpers.getTextAlignment(from: component)
        )

        // --- 1. Get text binding ---
        let textBinding = DynamicBindingHelper.string(component.text, data: data, fallback: "")

        // Check if it should be a SecureField
        let isSecure: Bool = {
            // `secure` is boolean|binding; the hand-decoded slot is nil for
            // `@{expr}`, so a bound declaration silently left the field
            // in the clear.
            if let secure = DynamicHelpers.resolveBool(
                component.typedAttributes(TextFieldAttributes.self).secure,
                legacy: component.secure,
                data: data
            ) { return secure }
            return component.input?.lowercased() == "password"
        }()

        // Field construction shared by the bound and local-state paths
        let build: (SwiftUI.Binding<String>) -> AnyView = { binding in
            var built: AnyView
            // Use FocusableTextField when component has an id (for focus chain support)
            if let fieldId = component.id {
                built = createFocusableTextField(
                    placeholder: nativePlaceholder,
                    styledPlaceholder: hintStyle.isEmpty ? nil : placeholder,
                    hintStyle: hintStyle,
                    hintAlignment: hintAlignment,
                    text: binding,
                    fieldId: fieldId,
                    isSecure: isSecure,
                    component: component,
                    data: data
                )
            } else {
                if isSecure {
                    built = AnyView(SecureField(nativePlaceholder, text: binding))
                } else {
                    built = AnyView(TextField(nativePlaceholder, text: binding))
                }
                if !hintStyle.isEmpty {
                    built = AnyView(
                        built.styledPlaceholder(
                            placeholder,
                            text: binding,
                            style: hintStyle,
                            alignment: hintAlignment
                        )
                    )
                }
                // clearButtonMode without an id: no focus state to read, so
                // `whileEditing` / `unlessEditing` cannot be evaluated. Same
                // trade-off as the focus chain, which also needs an id.
                if let mode = clearButtonMode(from: component.typedAttributes(TextFieldAttributes.self)) {
                    built = AnyView(built.textFieldClearButton(mode: mode, text: binding))
                }
                // Apply all modifiers in textfield_converter.rb order
                built = applyAllModifiers(built, component: component, data: data)
            }

            // --- 12. .onChange (onTextChange) ---
            if let onTextChange = component.onTextChange,
               DynamicEventHelper.handlerName(from: onTextChange) != nil {
                built = AnyView(
                    built.onChange(of: binding.wrappedValue) { _, newValue in
                        DynamicEventHelper.callWithValue(onTextChange, id: id, value: newValue, data: data)
                    }
                )
            }
            return built
        }

        // Bound (or data-resolved) @{var} text: use the resolved binding.
        if DynamicEventHelper.extractPropertyName(from: component.text) != nil {
            return build(textBinding)
        }

        // Unbound literal/absent text: local editing state — a native field
        // is inherently stateful on every other JsonUI runtime, so a
        // `.constant` SwiftUI field would wrongly reject edits here.
        return AnyView(DynamicLocalState(initial: textBinding.wrappedValue, content: build))
    }

    /// Placeholder styling declared by the layout.
    ///
    /// `hintFontSize` / `hintFont` set the placeholder font independently of
    /// the field font; `placeholderColor` and `hintColor` are the two
    /// spellings for its color. All four were dropped on the floor before —
    /// codegen still records them as a comment (`textfield_converter.rb`),
    /// which is what made 41 read the attribute as "emitted".
    ///
    /// `hintAttributes` carries the same three spellings in a nested object,
    /// and **the nested keys win**: a bag scoped to one sub-element is a more
    /// specific declaration than the flat spelling, so it beats it the way
    /// any cascade does. rjui `label_converter.rb`, sjui `label_converter.rb`
    /// and kjui `text_component.rb` all resolve it that way, as does
    /// `selectbox_converter.rb` for `labelAttributes`.
    ///
    /// (`textfield_converter.rb` merges with `||=`, which is the opposite and
    /// contradicts its own comment — 49-B is fixing that. The SSoT also
    /// scopes `hintAttributes` to `mode: uikit` while codegen reads it on the
    /// SwiftUI path; 49-E is adjudicating the declaration.)
    ///
    /// The resolution itself lives in `TextFieldPlaceholderStyle` so the
    /// code `sjui_tools` generates reaches the same picture from the same
    /// layout — this function only extracts the declared values.
    static func placeholderStyle(
        component: DynamicComponent,
        data: [String: Any]
    ) -> TextFieldPlaceholderStyle {
        let attrs = component.typedAttributes(TextFieldAttributes.self)
        let nested = attrs.hintAttributes

        // `hintColor` is canonical and accepts the bound form.
        // `placeholderColor` is its declared alias, so the generated lookup
        // resolves that spelling into `hintColor` itself — there is no
        // separate field to fall back to (49-E folded the second declaration
        // into the alias, matching Radio.selectedIcon and Segment).
        let hintColorRaw = (nested?["fontColor"] as? String)
            ?? (nested?["color"] as? String)
            ?? (attrs.hintColor?.rawRepresentation as? String)

        let hintFont = (nested?["font"] as? String) ?? attrs.hintFont
        let hintFontSize = (nested?["fontSize"] as? Double)
            ?? (nested?["fontSize"] as? Int).map(Double.init)
            ?? attrs.hintFontSize

        return TextFieldPlaceholderStyle(
            hintColor: DynamicHelpers.getColor(hintColorRaw, data: data),
            hintFont: hintFont,
            hintFontSize: hintFontSize.map { CGFloat($0) },
            fontSize: component.fontSize
        )
    }

    /// `clearButtonMode` — UIKit's `UITextField.ViewMode` spelling. An
    /// unrecognised value leaves the field alone rather than guessing a mode.
    private static func clearButtonMode(from attrs: TextFieldAttributes) -> TextFieldClearButtonMode? {
        guard let raw = attrs.clearButtonMode else { return nil }
        return TextFieldClearButtonMode(layoutValue: raw)
    }

    // MARK: - FocusableTextField path

    private static func createFocusableTextField(
        placeholder: String,
        styledPlaceholder: String?,
        hintStyle: TextFieldPlaceholderStyle,
        hintAlignment: Alignment,
        text: SwiftUI.Binding<String>,
        fieldId: String,
        isSecure: Bool,
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let attrs = component.typedAttributes(TextFieldAttributes.self)
        let nextFocusId = attrs.nextFocus

        var result = AnyView(
            FocusableTextField(
                placeholder: placeholder,
                text: text,
                fieldId: fieldId,
                isSecure: isSecure,
                keyboardType: getKeyboardType(from: component.input),
                submitLabel: getSubmitLabel(from: component.returnKeyType),
                textAlignment: DynamicHelpers.getTextAlignment(from: component),
                nextFocusId: nextFocusId,
                clearButtonMode: clearButtonMode(from: attrs)
            )
        )

        // Styled placeholder goes on before any padding/frame modifier so it
        // lands on the field's own text area, not on the padded box.
        if let hintText = styledPlaceholder {
            result = AnyView(
                result.styledPlaceholder(
                    hintText,
                    text: text,
                    style: hintStyle,
                    alignment: hintAlignment
                )
            )
        }

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
        // applyDisabled covers the bound form too; the literal-only check
        // here let `enabled: "@{x}"` fall through silently.
        result = DynamicModifierHelper.applyDisabled(result, component: component, data: data)

        // --- 10. tint (tintColor / caretAttributes) ---
        let caretColor: Color? = {
            if let tintColor = component.tintColor, let c = DynamicHelpers.getColor(tintColor) { return c }
            if let caretAttrs = attrs.caretAttributes,
               let caretFontColor = caretAttrs["fontColor"] as? String,
               let c = DynamicHelpers.getColor(caretFontColor) { return c }
            return nil
        }()
        if let color = caretColor {
            result = AnyView(result.tint(color))
        }

        // --- 11. textPaddingLeft ---
        if let textPaddingLeft = attrs.textPaddingLeft.map({ CGFloat($0) }) {
            result = AnyView(result.padding(.leading, textPaddingLeft))
        }

        // --- 12. fieldPadding ---
        // Uniform inner padding around the field content (codegen:
        // textfield_converter.rb emits .padding(N) into the padding slot).
        if let fieldPadding = component.fieldPadding {
            result = AnyView(result.padding(fieldPadding))
        }

        // --- 15. padding ---
        result = DynamicModifierHelper.applyPadding(result, component: component, data: data)

        // --- 16. frame_constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component, data: data)

        // --- 17. frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 18. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 19. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component, data: data)

        // --- 20. border ---
        result = DynamicModifierHelper.applyBorder(result, component: component, data: data)

        // --- 21. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 22. opacity ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)

        // --- 23. shadow ---
        result = DynamicModifierHelper.applyShadow(result, component: component)

        // --- 24. clipped ---
        result = DynamicModifierHelper.applyClipped(result, component: component, data: data)

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
        let attrs = component.typedAttributes(TextFieldAttributes.self)
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
        if let contentType = attrs.contentType?.value?.knownValue {
            result = applyContentType(result, contentType: contentType)
        }

        // --- 8. submitLabel ---
        if let returnKeyType = component.returnKeyType {
            result = AnyView(result.submitLabel(getSubmitLabel(from: returnKeyType)))
        }

        // --- 9. disabled ---
        // applyDisabled covers the bound form too; the literal-only check
        // here let `enabled: "@{x}"` fall through silently.
        result = DynamicModifierHelper.applyDisabled(result, component: component, data: data)

        // --- 10. tint (tintColor / caretAttributes) ---
        let caretColor: Color? = {
            if let tintColor = component.tintColor, let c = DynamicHelpers.getColor(tintColor) { return c }
            if let caretAttrs = attrs.caretAttributes,
               let caretFontColor = caretAttrs["fontColor"] as? String,
               let c = DynamicHelpers.getColor(caretFontColor) { return c }
            return nil
        }()
        if let color = caretColor {
            result = AnyView(result.tint(color))
        }

        // --- 11. textPaddingLeft ---
        if let textPaddingLeft = attrs.textPaddingLeft.map({ CGFloat($0) }) {
            result = AnyView(result.padding(.leading, textPaddingLeft))
        }

        // --- 12. fieldPadding ---
        // Uniform inner padding around the field content (codegen:
        // textfield_converter.rb emits .padding(N) into the padding slot).
        if let fieldPadding = component.fieldPadding {
            result = AnyView(result.padding(fieldPadding))
        }

        // --- 15. padding ---
        result = DynamicModifierHelper.applyPadding(result, component: component, data: data)

        // --- 16. frame_constraints ---
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component, data: data)

        // --- 17. frame_size ---
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 18. background ---
        result = DynamicModifierHelper.applyBackground(result, component: component, data: data)

        // --- 19. cornerRadius ---
        result = DynamicModifierHelper.applyCornerRadius(result, component: component, data: data)

        // --- 20. border ---
        result = DynamicModifierHelper.applyBorder(result, component: component, data: data)

        // --- 21. margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 22. opacity ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)

        // --- 23. shadow ---
        result = DynamicModifierHelper.applyShadow(result, component: component)

        // --- 24. clipped ---
        result = DynamicModifierHelper.applyClipped(result, component: component, data: data)

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

    /// Maps the declared `contentType` onto SwiftUI's `.textContentType`.
    ///
    /// Switching on the enum rather than a string is what keeps this honest.
    /// 49-E made `contentType` an enum, and the generated parser
    /// **canonicalises** the alias spellings — `tel` and `phone` both arrive
    /// as `.telephoneNumber`, `emailAddress` as `.email`. A string switch on
    /// the old spellings would silently stop matching `tel` the moment that
    /// landed, and half the vocabulary (newPassword, oneTimeCode, givenName,
    /// familyName, streetAddress, country, creditCardNumber, URL) had no
    /// case at all. The compiler now requires every member to be handled.
    private static func applyContentType(
        _ view: AnyView,
        contentType: TextFieldAttributes.ContentType
    ) -> AnyView {
        switch contentType {
        case .username: return AnyView(view.textContentType(.username))
        case .password: return AnyView(view.textContentType(.password))
        case .newPassword: return AnyView(view.textContentType(.newPassword))
        case .oneTimeCode: return AnyView(view.textContentType(.oneTimeCode))
        case .email: return AnyView(view.textContentType(.emailAddress))
        case .name: return AnyView(view.textContentType(.name))
        case .givenName: return AnyView(view.textContentType(.givenName))
        case .familyName: return AnyView(view.textContentType(.familyName))
        case .telephoneNumber: return AnyView(view.textContentType(.telephoneNumber))
        case .streetAddress: return AnyView(view.textContentType(.streetAddressLine1))
        case .postalCode: return AnyView(view.textContentType(.postalCode))
        case .country: return AnyView(view.textContentType(.countryName))
        case .creditCardNumber: return AnyView(view.textContentType(.creditCardNumber))
        case .uRL: return AnyView(view.textContentType(.URL))
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

/// Coerce a JSON-parsed numeric value to `CGFloat?` across Int / Double /
/// CGFloat / NSNumber. Used by converters reading from `component.rawData`
/// where the decoded type depends on the JSON literal form.
#endif // DEBUG
