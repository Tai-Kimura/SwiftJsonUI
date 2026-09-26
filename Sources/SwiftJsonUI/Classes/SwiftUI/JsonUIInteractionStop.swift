//
//  JsonUIInteractionStop.swift
//  SwiftJsonUI
//
//  `userInteractionEnabled` stops a view and everything in it. The tap rule
//  (jsonui-cli shared/core/tap_accessibility.rb) says no tap — no gesture, no
//  button trait — for what a stopping view holds; what it draws in a view of
//  its own (a Collection's cells, an Embed's screen, a TabView tab's view) the
//  build's annotation cannot reach, so the stop is handed down at run time:
//  the stopping view sets `jsonuiInteractionStopped`, and the drawn view's
//  taps read it. Both render paths use this one key — the code `sjui build`
//  emits (release builds included) and the Dynamic runtime
//  (DynamicComponentBuilder).
//

import SwiftUI

private struct JsonUIInteractionStoppedKey: EnvironmentKey {
    static var defaultValue: Bool { false }
}

public extension EnvironmentValues {
    /// True inside a view whose `userInteractionEnabled` is false, or a
    /// binding that is false.
    var jsonuiInteractionStopped: Bool {
        get { self[JsonUIInteractionStoppedKey.self] }
        set { self[JsonUIInteractionStoppedKey.self] = newValue }
    }
}

/// A control a stop holds — a Switch, a Button, a Slider, a text field
/// inside `userInteractionEnabled: false` (or a binding while it is false),
/// or with the flag of its own. The hit-test stop keeps a touch out, and
/// nothing else: VoiceOver's activation called the control's default action
/// through it (measured, ConformanceHost `-a11yActivationProbe`, iOS 26.5: a
/// Switch inside a stop switched, codegen and Dynamic). While `stopped`, or
/// while a stop is handed down (`jsonuiInteractionStopped`), the default
/// action is replaced by nothing, the button and toggle traits are removed,
/// and the element does not respond to user interaction — so a screen
/// reader neither operates it nor reads it as something to operate. Nothing
/// drawn changes (measured against the control as drawn without it; the
/// alternative `.disabled(true)` dims it). Not stopped: the view as it is.
///
/// `items`: a control whose items are elements of their own — a Segment
/// (a segmented Picker: UIKit's segments). What the modifiers above change is
/// the control's element, and a segment is not one: inside a stop each
/// segment still read as a button that responds (measured, ConformanceHost
/// `-a11yActivationProbe -wrappers`, iOS 26.5; a touch was stopped). With
/// `items`, a screen reader reads the same control disabled instead
/// (`accessibilityRepresentation`, which is not drawn): each segment is still
/// there, with its selection, and reads not enabled and not responding.
/// Nothing drawn changes (measured; `.disabled(true)` on the control itself
/// dims it). 4f's ruling (jsonui-cli 1.9.0): the items are told they are
/// stopped too, as Compose marks each one disabled.
public struct JsonUIStoppedControl: ViewModifier {
    @Environment(\.jsonuiInteractionStopped) private var handedDown
    let stopped: Bool
    let items: Bool

    public init(stopped: Bool, items: Bool = false) {
        self.stopped = stopped
        self.items = items
    }

    public func body(content: Content) -> some View {
        if (stopped || handedDown) && items {
            content.accessibilityRepresentation { content.disabled(true) }
        } else if stopped || handedDown {
            content
                .accessibilityAction { }
                .accessibilityRemoveTraits([.isButton, .isToggle])
                .accessibilityRespondsToUserInteraction(false)
        } else {
            content
        }
    }
}

public extension View {
    /// JsonUIStoppedControl: `stopped` is the stop the build can see (the
    /// flag on the control or around it, or its binding); a stop handed down
    /// from another layout is read from the environment. `items` for a
    /// control whose items are elements of their own (a Segment).
    func jsonuiStoppedControl(_ stopped: Bool = false, items: Bool = false) -> some View {
        modifier(JsonUIStoppedControl(stopped: stopped, items: items))
    }
}
