//
//  SJUIWindowWidth.swift
//  SwiftJsonUI
//
//  The window width a responsive `minWidth:N` / `maxWidth:N` reads
//  (jsonui-cli jui-responsive-width-threshold-conditions).
//

import SwiftUI
import UIKit

/// The width of the window a view is drawn in, in points, kept current.
///
/// Responsive width conditions compare against the WINDOW (the scene), not
/// the space the parent hands the view and not the display: on a folding
/// device, in Split View or under Stage Manager the app owns a fraction of
/// the screen, and that fraction changes while it runs.
///
/// Three properties decide the shape:
///
/// - **Right on the first body.** The width is read synchronously when the
///   object is made, from the foreground-active scene, so the first frame is
///   drawn for the real width. A width measured by a GeometryReader /
///   onGeometryChange into `@State` starts at 0 and draws one wrong frame.
/// - **Kept current from the scene itself.** The width is read from the scene
///   whenever a body reads it, and the scene's `effectiveGeometry` is
///   key-value observed so that a rotation, a fold or a resize redraws.
///   Reading `screen.bounds` in a body is not observed by anything: a
///   consumer measured it freezing at the old width across a fold, because
///   the size class changed first and the body read the stale screen.
/// - **The view's own window.** `.sjuiTracksWindowWidth(_:)` puts a probe
///   behind the view; when the view reaches a window, the object follows
///   that window's scene (several windows: the one the view is in).
@MainActor
public final class SJUIWindowWidth: ObservableObject {

    /// The window's width in points, read when the body reads it: the
    /// window the view is in (once the probe has seen it), else the active
    /// scene's; 0 when no scene exists (unit-test host).
    ///
    /// Read live rather than stored. Measured on an iPhone 16 Pro simulator,
    /// iOS 26.2 (Xcode 26.3), sampling every display frame against the
    /// window's bounds: with a stored width, a rotation ran the body for the
    /// new size classes before the geometry was observed, and it chose by the
    /// old width (1 frame in 3 rotations). Read from the scene, a rotation
    /// requested 0.13 s after the previous one ran the body while the scene
    /// was already landscape and the window still portrait (2 frames in 20).
    /// The window's bounds are what the view is laid out in.
    public var value: CGFloat {
        if let width = window?.bounds.width, width > 0 { return width }
        return Self.width(of: scene) ?? measured
    }

    /// The last width observed; publishing it is what redraws the readers
    /// when nothing else does (an iPad window resized within a size class).
    @Published private(set) var measured: CGFloat

    private weak var scene: UIWindowScene?
    private weak var window: UIWindow?
    private var observation: NSKeyValueObservation?

    public init() {
        let scene = Self.activeScene()
        measured = Self.width(of: scene) ?? SJUIWindowMetrics.bounds().width
        follow(scene)
    }

    /// Follow `window` (and its scene) from now on: the probe calls this with
    /// the window the view is in.
    func follow(window: UIWindow) {
        self.window = window
        follow(window.windowScene)
    }

    /// Follow `scene` from now on.
    func follow(_ scene: UIWindowScene?) {
        guard let scene, scene !== self.scene else { return }
        self.scene = scene
        observation = scene.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
            // KVO delivers on the thread that changed the geometry: UIKit's
            // main thread.
            MainActor.assumeIsolated { self?.update(self?.value) }
        }
    }

    /// The seam the tests drive: a width, as the window would report it.
    func update(_ width: CGFloat?) {
        guard let width, width > 0, width != measured else { return }
        measured = width
    }

    static func width(of scene: UIWindowScene?) -> CGFloat? {
        guard let scene else { return nil }
        // The scene's own coordinate space (iOS 13): its bounds are the
        // window's. effectiveGeometry.coordinateSpace says the same from
        // iOS 26 only; effectiveGeometry is observed for WHEN it changes.
        let width = scene.coordinateSpace.bounds.width
        return width > 0 ? width : nil
    }

    static func activeScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

/// A zero-effect view behind the tracked view: it only reports the window
/// it reached.
private struct SJUIWindowWidthProbe: UIViewRepresentable {
    let width: SJUIWindowWidth

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.width = width
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.width = width
        uiView.report()
    }

    final class ProbeView: UIView {
        weak var width: SJUIWindowWidth?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
            accessibilityElementsHidden = true
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        func report() {
            guard let window else { return }
            width?.follow(window: window)
            let measured = window.bounds.width
            DispatchQueue.main.async { [weak self] in self?.width?.update(measured) }
        }

        // The probe fills the tracked view, so it is laid out again when the
        // window is: a resize that changes no size class and no scene
        // geometry still redraws. Published after this layout pass, not
        // inside it (a change published mid-update is dropped by SwiftUI).
        override func layoutSubviews() {
            super.layoutSubviews()
            guard let window else { return }
            let measured = window.bounds.width
            DispatchQueue.main.async { [weak self] in self?.width?.update(measured) }
        }
    }
}

public extension View {
    /// Keep `width` on the window this view is drawn in. Generated views with
    /// responsive width conditions apply it to their outer container.
    func sjuiTracksWindowWidth(_ width: SJUIWindowWidth) -> some View {
        background(SJUIWindowWidthProbe(width: width).allowsHitTesting(false).accessibilityHidden(true))
    }
}
