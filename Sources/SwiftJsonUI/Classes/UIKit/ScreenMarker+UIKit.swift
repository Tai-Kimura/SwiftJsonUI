//
//  ScreenMarker+UIKit.swift
//  SwiftJsonUI
//
//  Runtime identity beacon for a screen, emitted by code generation into
//  the generated Binding's bindView().
//
//  Canon: jsonui-cli `shared/core/screen_identity.json`.
//

import UIKit

public extension Binding {
    /// Adds this screen's marker to the holder's root view, so a test can
    /// assert that the screen is displayed without knowing anything about
    /// its contents.
    ///
    /// Emitted by `sjui build` on generated screen bindings only — cells and
    /// partials render inside a host and must not each grow a marker.
    ///
    /// `bindView()` can run more than once for the same holder, so an
    /// existing marker is replaced rather than duplicated: a rendered screen
    /// must expose exactly one.
    func applyScreenMarker(_ screenId: String) {
        // DEBUG only: the marker is test scaffolding and has no place in a
        // shipped app. Same gate as the SwiftUI modifier and as Dynamic mode
        // (`ViewSwitcher.isDynamicMode`) — the library is distributed as
        // source, so this follows the CONSUMER's build configuration.
        #if DEBUG
        // Screens are view controllers in UIKit mode; a cell or reusable
        // view holder is by definition not a screen, so there is nothing to
        // mark and nothing to guess at.
        guard let root = (viewHolder as? UIViewController)?.view else { return }

        let identifier = screenMarkerIdentifier(screenId)
        for existing in root.subviews where existing.accessibilityIdentifier == identifier {
            existing.removeFromSuperview()
        }

        // A sibling view rather than an identifier on the root itself: the
        // root's own identifier is load-bearing for existing tests, and
        // every platform has one identifier slot per node.
        //
        // CENTERED, not at the origin. The marker first shipped at (0, 0)
        // and every screen assertion failed with "exists but is not
        // hittable": the root view's top-left corner sits under the
        // navigation bar, so hit-testing there resolves to the chrome. The
        // driver predicate is `exists && isHittable`, and the SwiftUI marker
        // was measured to flip from false to true on the same screen purely
        // by moving topLeading -> center. Autoresizing keeps it centred
        // across rotation and layout changes.
        let marker = UIView(frame: CGRect(x: root.bounds.midX, y: root.bounds.midY, width: 1, height: 1))
        marker.autoresizingMask = [
            .flexibleLeftMargin, .flexibleRightMargin,
            .flexibleTopMargin, .flexibleBottomMargin,
        ]
        marker.isUserInteractionEnabled = false
        marker.isAccessibilityElement = true
        marker.accessibilityIdentifier = identifier
        root.addSubview(marker)
        #endif
    }
}
