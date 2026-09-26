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
