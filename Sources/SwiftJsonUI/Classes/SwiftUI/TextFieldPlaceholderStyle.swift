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
    public let font: Font?
    public let color: Color?

    public init(font: Font? = nil, color: Color? = nil) {
        self.font = font
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
            self.font = nil
        } else {
            let size = hintFontSize ?? fontSize ?? SwiftJsonUIConfiguration.shared.font.size
            if let hintFont, hintFont != "bold" {
                self.font = .custom(hintFont, size: size)
            } else if hintFont == "bold" {
                self.font = .system(size: size, weight: .bold)
            } else {
                self.font = .system(size: size)
            }
        }
        self.color = hintColor
    }

    /// True when the layout declared no placeholder styling at all. Callers
    /// use this to keep the native placeholder rather than pay for an
    /// overlay that would look identical.
    public var isEmpty: Bool { font == nil && color == nil }
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
        content.overlay(alignment: alignment) {
            if value.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(style.font)
                    // Only the declared color overrides the system default;
                    // a font-only declaration must not repaint the text.
                    .foregroundColor(style.color ?? Color(UIColor.placeholderText))
                    // The overlay sits on top of the field — without this the
                    // placeholder would swallow the tap that focuses it.
                    .allowsHitTesting(false)
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
