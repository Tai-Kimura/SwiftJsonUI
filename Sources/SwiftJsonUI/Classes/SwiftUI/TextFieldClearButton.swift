//
//  TextFieldClearButton.swift
//  SwiftJsonUI
//
//  `clearButtonMode` for SwiftUI text fields.
//

import SwiftUI

/// When a text field shows its clear button — the four cases of
/// `UITextField.ViewMode`, which is what `clearButtonMode` names.
public enum TextFieldClearButtonMode: String, CaseIterable {
    case never
    case whileEditing
    case unlessEditing
    case always

    /// Parses the layout value. Returns `nil` for anything unrecognised so the
    /// caller can leave the field alone rather than guess a mode.
    public init?(layoutValue: String) {
        let normalized = layoutValue.replacingOccurrences(of: "_", with: "").lowercased()
        guard let match = Self.allCases.first(where: { $0.rawValue.lowercased() == normalized })
        else { return nil }
        self = match
    }
}

/// SwiftUI has no clear button of its own, so this is the overlay UIKit gives
/// `UITextField` for free.
///
/// Like UIKit, the button is hidden while the field is empty — there is nothing
/// to clear — and space for it is reserved only while it is showing, so the text
/// never runs underneath it.
public struct TextFieldClearButtonModifier: ViewModifier {
    private static let buttonWidth: CGFloat = 22

    private let mode: TextFieldClearButtonMode
    @SwiftUI.Binding private var text: String
    private let isEditing: Bool
    private let accessibilityLabel: String
    /// A stop holds the field (JsonUIStoppedControl), or one is handed down.
    @Environment(\.jsonuiControlStopped) private var controlStopped
    @Environment(\.jsonuiInteractionStopped) private var stoppedAround

    public init(
        mode: TextFieldClearButtonMode,
        text: SwiftUI.Binding<String>,
        isEditing: Bool = false,
        accessibilityLabel: String = "Clear text"
    ) {
        self.mode = mode
        self._text = text
        self.isEditing = isEditing
        self.accessibilityLabel = accessibilityLabel
    }

    private var isVisible: Bool {
        guard !text.isEmpty else { return false }
        switch mode {
        case .never: return false
        case .always: return true
        case .whileEditing: return isEditing
        case .unlessEditing: return !isEditing
        }
    }

    public func body(content: Content) -> some View {
        content
            .padding(.trailing, isVisible ? Self.buttonWidth : 0)
            // The clear button is the FIELD's action, not an element of its
            // own. The layout id goes on this composite as a whole, and
            // SwiftUI hands an identifier on a non-element to every element
            // inside: the button was a second element carrying the
            // TextField's id, and the test driver's tap (which ranks buttons
            // first) pressed it and cleared the text (ticket
            // sjui-a-composite-leaf-gives-its-id-to-every-element-inside).
            // VoiceOver reaches it as the field's named action — except
            // while a stop holds the field: the stopped control's treatment
            // takes the field's own action but not a named one, so the clear
            // stayed in VoiceOver's actions and emptied a field the layout
            // stopped (measured, ConformanceHost -a11yActivationProbe
            // -textFields, both routes; ticket
            // sjui-dynamic-radio-item-operable-inside-a-stop).
            .modifier(ClearAction(label: accessibilityLabel, enabled: !(controlStopped || stoppedAround)) {
                if isVisible { text = "" }
            })
            .overlay(alignment: .trailing) {
                if isVisible {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                    .frame(width: Self.buttonWidth)
                    .accessibilityHidden(true)
                }
            }
    }
}

public extension View {
    /// Applies `clearButtonMode`.
    ///
    /// `isEditing` only matters for `whileEditing` / `unlessEditing`; pass the
    /// field's `@FocusState` value there.
    func textFieldClearButton(
        mode: TextFieldClearButtonMode,
        text: SwiftUI.Binding<String>,
        isEditing: Bool = false,
        accessibilityLabel: String = "Clear text"
    ) -> some View {
        modifier(
            TextFieldClearButtonModifier(
                mode: mode,
                text: text,
                isEditing: isEditing,
                accessibilityLabel: accessibilityLabel
            )
        )
    }
}

/// The clear button's named accessibility action, attached only when enabled.
private struct ClearAction: ViewModifier {
    let label: String
    let enabled: Bool
    let clear: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.accessibilityAction(named: Text(label), clear)
        } else {
            content
        }
    }
}
