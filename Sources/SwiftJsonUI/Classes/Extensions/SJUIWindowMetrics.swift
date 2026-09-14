//
//  SJUIWindowMetrics.swift
//  SwiftJsonUI
//
//  Added 2026-09-14 while preparing for iOS 27.
//

import UIKit

/// Where "the screen" comes from, for code that compares a rect against it.
///
/// `UIScreen.main` is deprecated from iOS 26, and the deprecation is the smaller
/// problem. A window is not the screen: under iPad Split View, Stage Manager, or a
/// folding device the app owns a fraction of the display, and that fraction changes
/// while the app runs. Keyboard notifications carry a frame in SCREEN coordinates,
/// so comparing it against the full screen height reads "keyboard dismissed" for a
/// window that does not reach the bottom of the display.
///
/// Order: the window the view is actually in, then the foreground-active scene's key
/// window, then — only where neither exists — the deprecated screen.
public enum SJUIWindowMetrics {

    /// The rect to treat as the visible area for `view`.
    @MainActor
    public static func bounds(for view: UIView?) -> CGRect {
        resolve(viewWindow: view?.window?.bounds,
                activeSceneWindow: activeSceneWindowBounds(),
                fallback: legacyScreenBounds())
    }

    /// The rect for callers with no view at hand (a SwiftUI observable, say).
    @MainActor
    public static func bounds() -> CGRect {
        bounds(for: nil)
    }

    /// For callers the compiler cannot see are on the main actor: UIKit delivers
    /// keyboard notifications on the main thread, but a Combine `sink` is a
    /// nonisolated context, so the isolation is real and invisible.
    ///
    /// ⚠️ `assumeIsolated` traps if the assumption is false. That is deliberate: the
    /// alternative — hopping to the main actor and answering later — would return a
    /// size measured after the layout it was meant to inform, which is a wrong
    /// number rather than a crash. A wrong size is the defect this file exists to
    /// remove, so it must not be reintroduced to avoid a trap that cannot fire on
    /// UIKit's own delivery thread.
    public static func boundsAssumingMainActor(for view: UIView? = nil) -> CGRect {
        MainActor.assumeIsolated { bounds(for: view) }
    }

    // MARK: - The seam
    //
    // The choice is a pure function so that BOTH branches can be measured. A
    // UIWindowScene cannot be built in a unit test, so a helper that only reads the
    // live scene graph is one whose fallback path no arm ever runs — and the
    // fallback is exactly the path that runs where the arms cannot go.
    static func resolve(viewWindow: CGRect?, activeSceneWindow: CGRect?, fallback: CGRect) -> CGRect {
        if let viewWindow, !viewWindow.isEmpty { return viewWindow }
        if let activeSceneWindow, !activeSceneWindow.isEmpty { return activeSceneWindow }
        return fallback
    }

    @MainActor
    static func activeSceneWindowBounds() -> CGRect? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let scene else { return nil }
        let window = scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
        return window?.bounds ?? scene.screen.bounds
    }

    /// The last resort: there is no scene at all, so there is nothing to read.
    ///
    /// ⚠️ `#available` asks the RUNTIME version, not the deployment target. A first
    /// draft put `UIScreen.main` in the `else` branch to keep old systems working;
    /// on any iOS 26 device that branch is not taken, so the fallback silently
    /// became `.zero` there while still reading the screen on iOS 17-25 — two
    /// different answers for the same situation, decided by the device. Measured:
    /// the unit-test host has no scene, and the helper returned an empty rect.
    ///
    /// So there is no version split. With no scene the honest answer is "unknown",
    /// spelled as an empty rect, and every caller already has to handle it: they
    /// fall back to their own bounds, which is the right frame of reference anyway.
    /// This is also what keeps the deprecated symbol out of the source entirely.
    @MainActor
    static func legacyScreenBounds() -> CGRect {
        .zero
    }
}

/// Keyboard geometry against a window rather than the display.
///
/// Keyboard notifications report a frame in SCREEN coordinates. Every caller here
/// used to compare it against the full display height, which answers "dismissed"
/// whenever the window does not reach the bottom of the display — the normal case
/// in iPad Split View and Stage Manager, and on a folding device after a fold.
public enum SJUIKeyboardGeometry {

    /// How much of `area` the keyboard covers, or `nil` when the area is unknown.
    ///
    /// `nil` is not zero. Zero means "measured, and the keyboard covers nothing";
    /// nil means "there is no window to measure against", and a caller that treats
    /// the two the same will hide a keyboard that is on screen.
    public static func overlapHeight(keyboardFrameInScreen frame: CGRect, area: CGRect) -> CGFloat? {
        guard !area.isEmpty else { return nil }
        let overlap = area.maxY - frame.origin.y
        if overlap <= 0 { return 0 }
        return min(overlap, area.height)
    }

    /// `true` when the keyboard is off the bottom of `area`. `nil` when unknown.
    public static func isDismissed(keyboardFrameInScreen frame: CGRect, area: CGRect) -> Bool? {
        guard let overlap = overlapHeight(keyboardFrameInScreen: frame, area: area) else { return nil }
        return overlap == 0
    }
}
