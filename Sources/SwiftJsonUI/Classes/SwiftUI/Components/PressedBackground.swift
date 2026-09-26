//
//  PressedBackground.swift
//  SwiftJsonUI
//
//  tapBackground is the background while pressed, on every node with a tap
//  (onClick) and on a Button (jsonui-cli 1.9.0). A Button draws it in its own
//  view (StateAwareButtonView). Every other node splits it in two:
//
//  - `tracksPress()` goes where the tap is, after the tap gesture. It holds
//    the pressed state and hands it down the environment.
//  - `pressedBackground(_:base:)` goes in the background slot. It reads that
//    state, so the pressed colour covers the padded, framed box exactly as the
//    background does, and replaces the background while pressed, as UIKit
//    swaps SJUIView's backgroundColor.
//
//  The press is a long press that never completes, applied after the tap
//  gesture: the tap still fires on a short touch, and a scroll view around the
//  node still scrolls (a long press applied before the tap takes both).
//  Moving the finger off the node ends the press.
//

import SwiftUI

private struct JsonUIPressedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Whether the nearest node that tracks its press (`tracksPress()`) is
    /// being pressed.
    public var jsonUIPressed: Bool {
        get { self[JsonUIPressedKey.self] }
        set { self[JsonUIPressedKey.self] = newValue }
    }
}

/// Tracks the press of the node it is applied to and hands it down.
public struct TracksPress: ViewModifier {
    @State private var isPressed = false
    let enabled: Bool

    /// `enabled: false` tracks nothing and hands down "not pressed", so a
    /// node whose tap is gated off never shows its pressed colour — nor one
    /// inherited from a pressed node around it.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func body(content: Content) -> some View {
        if enabled {
            content
                .environment(\.jsonUIPressed, isPressed)
                .onLongPressGesture(minimumDuration: .infinity, perform: {}, onPressingChanged: { pressing in
                    isPressed = pressing
                })
        } else {
            content.environment(\.jsonUIPressed, false)
        }
    }
}

/// The background slot of a node with a pressed colour: `pressed` while the
/// node is pressed, `base` (or nothing) otherwise.
public struct PressedBackground: ViewModifier {
    @Environment(\.jsonUIPressed) private var isPressed
    let pressed: Color
    let base: Color?

    public init(pressed: Color, base: Color? = nil) {
        self.pressed = pressed
        self.base = base
    }

    public func body(content: Content) -> some View {
        content.background(isPressed ? pressed : (base ?? Color.clear))
    }
}

/// The fill of an empty node that paints its background as content
/// (`Rectangle().fill`, the leaf contract), with the pressed colour.
public struct PressedFill: View {
    @Environment(\.jsonUIPressed) private var isPressed
    let pressed: Color
    let base: Color?

    public init(pressed: Color, base: Color? = nil) {
        self.pressed = pressed
        self.base = base
    }

    public var body: some View {
        Rectangle().fill(isPressed ? pressed : (base ?? Color.clear))
    }
}

extension View {
    /// Tracks this node's press for `pressedBackground` (see the file header).
    public func tracksPress(enabled: Bool = true) -> some View {
        modifier(TracksPress(enabled: enabled))
    }

    /// The background slot: `pressed` while the node is pressed, else `base`.
    public func pressedBackground(_ pressed: Color, base: Color? = nil) -> some View {
        modifier(PressedBackground(pressed: pressed, base: base))
    }
}
