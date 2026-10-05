//
//  FocusableTextField.swift
//  SwiftJsonUI
//
//  TextField wrapper with @FocusState support for dynamic mode
//

import SwiftUI
import Combine
#if DEBUG

public struct FocusableTextField: View {
    let placeholder: String
    @SwiftUI.Binding var text: String
    let fieldId: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let submitLabel: SubmitLabel
    let textAlignment: TextAlignment
    let nextFocusId: String?
    let onSubmitAction: (() -> Void)?
    /// Told when the field gains (true) or loses (false) focus — where a
    /// layout's onFocus / onBeginEditing and onBlur / onEndEditing are called.
    let onFocusChange: ((Bool) -> Void)?
    /// `clearButtonMode`. Applied here rather than by the caller because
    /// `whileEditing` / `unlessEditing` need the focus state this view owns.
    let clearButtonMode: TextFieldClearButtonMode?
    /// The layout id, put on the FIELD itself — not around the clear button
    /// and placeholder overlays, which would each take it too (see
    /// View.leafAccessibilityIdentifier).
    let accessibilityIdentifier: String?

    @FocusState private var isFocused: Bool

    public init(
        placeholder: String,
        text: SwiftUI.Binding<String>,
        fieldId: String,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        submitLabel: SubmitLabel = .done,
        textAlignment: TextAlignment = .leading,
        nextFocusId: String? = nil,
        onSubmitAction: (() -> Void)? = nil,
        clearButtonMode: TextFieldClearButtonMode? = nil,
        onFocusChange: ((Bool) -> Void)? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.fieldId = fieldId
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.submitLabel = submitLabel
        self.textAlignment = textAlignment
        self.nextFocusId = nextFocusId
        self.onSubmitAction = onSubmitAction
        self.clearButtonMode = clearButtonMode
        self.onFocusChange = onFocusChange
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    public var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .multilineTextAlignment(textAlignment)
                    .leafAccessibilityIdentifier(accessibilityIdentifier)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .submitLabel(submitLabel)
                    .multilineTextAlignment(textAlignment)
                    .leafAccessibilityIdentifier(accessibilityIdentifier)
            }
        }
        .focused($isFocused)
        .textFieldClearButton(mode: clearButtonMode ?? .never, text: $text, isEditing: isFocused)
        .onSubmit {
            if let nextId = nextFocusId {
                FocusManager.shared.requestFocus(fieldId: nextId)
            }
            onSubmitAction?()
        }
        .onChange(of: isFocused) { _, focused in
            onFocusChange?(focused)
        }
        .onReceive(FocusManager.shared.focusRequestPublisher) { requestedId in
            if requestedId == fieldId {
                isFocused = true
            } else if isFocused {
                isFocused = false
            }
        }
    }
}
#endif // DEBUG
