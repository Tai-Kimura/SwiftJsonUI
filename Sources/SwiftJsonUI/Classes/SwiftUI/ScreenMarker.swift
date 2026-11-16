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

/// The app's Info.plist key that turns the marker on in a build that is not
/// DEBUG — a UI-test configuration made from Release, so the tests run the
/// optimized code that ships. Docs/ui-tests-on-release-builds.md says how to
/// set it (the value is normally `$(JSONUI_SCREEN_MARKER)`, which Xcode
/// expands to a string per configuration).
public let screenMarkerInfoPlistKey = "com.swiftjsonui.SCREEN_MARKER"

/// Whether an Info.plist value turns the marker on: `YES` / `TRUE` / `1` as a
/// string (any case, surrounding spaces ignored), a Bool true or a nonzero
/// number. Absent, empty, `NO` or anything else is off.
func screenMarkerFlagIsOn(_ value: Any?) -> Bool {
    switch value {
    case let flag as Bool:
        return flag
    case let number as NSNumber:
        return number.boolValue
    case let text as String:
        let word = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return word == "YES" || word == "TRUE" || word == "1"
    default:
        return false
    }
}

/// Whether ``jsonUIScreenMarker(_:)`` draws: in a DEBUG build, or when the app's
/// Info.plist turns ``screenMarkerInfoPlistKey`` on. A shipped app is neither,
/// so it draws nothing.
func screenMarkerEnabled(isDebugBuild: Bool, infoPlistValue: Any?) -> Bool {
    isDebugBuild || screenMarkerFlagIsOn(infoPlistValue)
}

#if DEBUG
private let screenMarkerIsDebugBuild = true
#else
private let screenMarkerIsDebugBuild = false
#endif

/// Decided once per process: the build configuration and the app's bundle do
/// not change while it runs.
let screenMarkerIsEnabled: Bool = screenMarkerEnabled(
    isDebugBuild: screenMarkerIsDebugBuild,
    infoPlistValue: Bundle.main.object(forInfoDictionaryKey: screenMarkerInfoPlistKey)
)

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
    /// **DEBUG builds, or a build that asks for it.** The marker is test
    /// scaffolding and has no place in a shipped app, so a Release build adds
    /// nothing to the view hierarchy. A build that is not DEBUG draws it when
    /// the app's Info.plist turns `com.swiftjsonui.SCREEN_MARKER` on
    /// (``screenMarkerInfoPlistKey``), so the UI tests can run on the optimized
    /// code a release ships (ticket
    /// sjui-screenmarker-compiled-out-in-release-blocks-optimized-ui-tests).
    ///
    /// A run-time gate, not a compile-time one: SwiftPM compiles this package
    /// with its own settings, and an app's SWIFT_ACTIVE_COMPILATION_CONDITIONS
    /// — on the target or the project — does not reach it (measured, Xcode 27
    /// RC: only an xcodebuild command-line override or -xcconfig does, which
    /// Xcode's own Test action never passes). Dynamic mode keeps its
    /// `#if DEBUG` (`ViewSwitcher`): it is not shipped at all.
    @ViewBuilder
    func jsonUIScreenMarker(_ screenId: String) -> some View {
        if screenMarkerIsEnabled {
            modifier(ScreenMarkerModifier(screenId: screenId))
        } else {
            self
        }
    }
}
