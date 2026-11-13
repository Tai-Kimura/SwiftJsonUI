//
//  TextFieldPlaceholderStyle.swift
//  SwiftJsonUI
//
//  Styled placeholders for SwiftUI text fields.
//
//  `TextField(_:text:)` takes the placeholder as a plain `String`, so the
//  field's own font and the system placeholder color are the only thing the
//  user ever sees — `hintColor` / `hintFont` / `hintFontSize` /
//  `placeholderColor` had nowhere to land. The fix is not an attributed
//  string: it is to hand the native field an empty placeholder and overlay a
//  `Text` we style ourselves, shown while the field is empty. That is the
//  same visual contract (placeholder until the user types) with the styling
//  hooks the layout asked for.
//

import SwiftUI

/// The placeholder styling a layout declared. `nil` in a slot means "the
/// layout said nothing", which keeps the native placeholder appearance.
public struct TextFieldPlaceholderStyle: Equatable {
    /// A font handed in as it is (`init(font:color:)`); drawn as given.
    public let font: Font?
    /// The declared hint font, drawn through `sjuiFont` (the app's fontProvider, the text size rule; 2026-11-13).
    public let spec: FontSpec?
    public let color: Color?

    public init(font: Font? = nil, color: Color? = nil) {
        self.font = font
        self.spec = nil
        self.color = color
    }

    /// Resolves the layout's declared values into a style.
    ///
    /// **This is the single rule both render paths use** — the dynamic
    /// converter and the code `sjui_tools` generates. Keeping the resolution
    /// in the library rather than in each emitter is what stops codegen and
    /// dynamic from drifting into two different pictures for one layout.
    ///
    /// The spellings and the font rule deliberately match
    /// `TextViewWithPlaceholder.init` — TextView already solved this, and a
    /// second convention for the same idea is how a vocabulary drifts.
    ///
    /// - Parameter fontSize: the *field's* font size, used when `hintFont` is
    ///   declared without `hintFontSize`, so naming a placeholder font does
    ///   not silently resize it.
    public init(
        hintColor: Color? = nil,
        hintFont: String? = nil,
        hintFontSize: CGFloat? = nil,
        fontSize: CGFloat? = nil
    ) {
        if hintFont == nil && hintFontSize == nil {
            // No font declared: the field's own font keeps applying, exactly
            // as the native placeholder behaves.
            self.spec = nil
        } else {
            let size = hintFontSize ?? fontSize ?? SwiftJsonUIConfiguration.shared.font.size
            if let hintFont, hintFont != "bold" {
                self.spec = FontSpec(family: hintFont, size: size)
            } else if hintFont == "bold" {
                self.spec = FontSpec(weight: .bold, size: size)
            } else {
                self.spec = FontSpec(size: size)
            }
        }
        self.font = nil
        self.color = hintColor
    }

    /// True when the layout declared no placeholder styling at all. Callers
    /// use this to keep the native placeholder rather than pay for an
    /// overlay that would look identical.
    public var isEmpty: Bool { font == nil && spec == nil && color == nil }
}

private struct StyledPlaceholderModifier: ViewModifier {
    let placeholder: String
    // Held as a plain value, not `@Binding`: SwiftJsonUI ships its own UIKit
    // `Binding` class, so the property wrapper spelling does not resolve here.
    // The binding is only read, and the parent re-renders on every text
    // change, so the wrapper buys nothing.
    let value: SwiftUI.Binding<String>
    let style: TextFieldPlaceholderStyle
    let alignment: Alignment

    func body(content: Content) -> some View {
        content
            // The field carries the placeholder for VoiceOver; the overlay is
            // drawn only. The layout id goes on this composite as a whole,
            // and SwiftUI hands an identifier on a non-element to every
            // element inside: a visible placeholder Text was a second element
            // carrying the TextField's id (ticket
            // sjui-a-composite-leaf-gives-its-id-to-every-element-inside).
            .accessibilityHint(placeholder)
            .overlay(alignment: alignment) {
                if value.wrappedValue.isEmpty {
                    Text(placeholder)
                        .placeholderFont(style)
                        // Only the declared color overrides the system default;
                        // a font-only declaration must not repaint the text.
                        .foregroundColor(style.color ?? Color(UIColor.placeholderText))
                        // The overlay sits on top of the field — without this the
                        // placeholder would swallow the tap that focuses it.
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}

public extension View {
    /// Overlays a styled placeholder, shown while `text` is empty.
    ///
    /// The caller is responsible for handing the underlying field an *empty*
    /// native placeholder — otherwise both would draw.
    ///
    /// - Parameter alignment: must match the field's `textAlign`, or the
    ///   placeholder and the typed text would sit in different places.
    func styledPlaceholder(
        _ placeholder: String,
        text: SwiftUI.Binding<String>,
        style: TextFieldPlaceholderStyle,
        alignment: Alignment = .leading
    ) -> some View {
        modifier(
            StyledPlaceholderModifier(
                placeholder: placeholder,
                value: text,
                style: style,
                alignment: alignment
            )
        )
    }
}

/// Maps `textAlign` to the overlay alignment. Vertical stays `.center`
/// because the placeholder tracks the field's single text line.
public func textFieldPlaceholderAlignment(for textAlignment: TextAlignment) -> Alignment {
    switch textAlignment {
    case .leading: return .leading
    case .center: return .center
    case .trailing: return .trailing
    }
}

private extension View {
    /// The declared hint font through `sjuiFont`, a font handed in as it is, else the field's own.
    @ViewBuilder
    func placeholderFont(_ style: TextFieldPlaceholderStyle) -> some View {
        if let spec = style.spec {
            sjuiFont(spec)
        } else {
            font(style.font)
        }
    }
}
