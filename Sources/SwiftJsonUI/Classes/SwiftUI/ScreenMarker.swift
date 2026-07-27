//
//  ScreenMarker.swift
//  SwiftJsonUI
//
//  Runtime identity beacon for a screen, emitted by code generation.
//
//  Canon: jsonui-cli `shared/core/screen_identity.json`.
//

import SwiftUI

/// Prefix every screen marker identifier carries. Drivers match on
/// `"\(screenMarkerPrefix)\(screenId)"`; tests never spell it themselves.
public let screenMarkerPrefix = "__screen_"

/// Marker identifier for a screen id.
public func screenMarkerIdentifier(_ screenId: String) -> String {
    "\(screenMarkerPrefix)\(screenId)"
}

private struct ScreenMarkerModifier: ViewModifier {
    let screenId: String

    func body(content: Content) -> some View {
        content.overlay(alignment: .center) {
            // A LEAF, deliberately: measured on iOS 18.6, making the screen
            // root an accessibility CONTAINER instead makes the screen's own
            // root identifier disappear, and a container also reports
            // isHittable == false while fully visible — which would break the
            // `exists && isHittable` predicate the drivers use.
            //
            // CENTERED, also deliberately. This shipped aligned .topLeading
            // and every screen assertion failed on real apps with
            // "exists but is not hittable": a generated screen root fills the
            // screen, so its top-left corner sits under the navigation bar,
            // and hit-testing there resolves to the chrome instead of the
            // marker. Measured on iOS 18.6 — same screen, same 0.5pt leaf:
            // topLeading isHittable == false, center isHittable == true.
            // It went unnoticed because the probe marked a small view in the
            // middle of a stack, where the corner is clear.
            //
            // The overlay attaches to the screen root rather than to its
            // content, so a scrollable screen cannot scroll its own marker
            // out of the viewport.
            //
            // allowsHitTesting(false) keeps the marker out of the real touch
            // path. Measured: it does NOT affect isHittable either way, so
            // the marker stays untappable by a user while remaining
            // hit-testable by XCUITest.
            Color.clear
                .frame(width: 0.5, height: 0.5)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier(screenMarkerIdentifier(screenId))
        }
    }
}

public extension View {
    /// Marks this view as the screen `screenId`, so a test can assert that
    /// the screen is displayed without knowing anything about its contents.
    ///
    /// Emitted by `sjui build` on generated screen views only — cells,
    /// partials and responsive variant structs must not carry a marker, and
    /// the modifier is applied at the screen's call site rather than inside
    /// `DynamicView` (which cells, tabs, embeds and dialogs re-enter).
    ///
    /// A rendered screen must expose exactly one marker: zero means stale
    /// generated code or a stale library pin, two or more is a generator bug.
    ///
    /// **DEBUG only.** The marker is test scaffolding and has no place in a
    /// shipped app, so in release builds this is a no-op and nothing is added
    /// to the view hierarchy — the same `#if DEBUG` gate `ViewSwitcher` uses
    /// for Dynamic mode. UI tests therefore have to run against a debug
    /// build, which is already true for Dynamic mode.
    @ViewBuilder
    func jsonUIScreenMarker(_ screenId: String) -> some View {
        #if DEBUG
        modifier(ScreenMarkerModifier(screenId: screenId))
        #else
        self
        #endif
    }
}
