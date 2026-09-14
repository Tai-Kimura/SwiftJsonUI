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
