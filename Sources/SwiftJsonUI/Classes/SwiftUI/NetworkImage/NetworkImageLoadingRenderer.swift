//
//  NetworkImageLoadingRenderer.swift
//  SwiftJsonUI
//
//  The loading renderer seat of NetworkImage (`loadingRenderer`): a native
//  drawer the app registers by name, laid over the frame only while the image
//  is read from disk or the network, after loadingDelay, and told the bytes
//  as they arrive — layers on a CALayer, not a SwiftUI View, so progress
//  never redraws a body (ticket jui-networkimage-load-listener, the
//  requester's ruling 2026-11-15).
//

import QuartzCore
import SwiftUI
import UIKit

/// What a renderer is told when it is put on a frame and when it changes.
public struct NetworkImageRendererContext {
    /// Reduce Motion is on (`UIAccessibility.isReduceMotionEnabled`).
    public let reduceMotion: Bool
    public let colorScheme: ColorScheme
    /// Seconds since the URL's load started (`NetworkImageLoad.startedAt`):
    /// a renderer put on a load already past loadingDelay (a frame that came
    /// back, a frame that joined later) shows without rising in.
    public let elapsedSinceStart: CFTimeInterval

    public init(reduceMotion: Bool, colorScheme: ColorScheme, elapsedSinceStart: CFTimeInterval) {
        self.reduceMotion = reduceMotion
        self.colorScheme = colorScheme
        self.elapsedSinceStart = elapsedSinceStart
    }
}

/// A frame's renderer. Made by the registered factory, one per frame and
/// load; called on the main thread. It adds its layers to the layer it is
/// attached to and removes them in `detach()`.
@MainActor
public protocol NetworkImageLoadingRenderer: AnyObject {
    /// Put on the frame: add layers to `layer` (the frame's size) and watch
    /// `load` (`load.observe`) for its progress.
    func attach(to layer: CALayer, load: NetworkImageLoad, size: CGSize, context: NetworkImageRendererContext)
    /// Reduce Motion or the colour scheme changed.
    func update(context: NetworkImageRendererContext)
    func resize(to size: CGSize)
    /// The image is about to fade in over `transition` seconds: called inside
    /// the CATransaction that adds the image's animation, so the renderer's
    /// own animations start on the same frame. The image fades in on a layer
    /// ABOVE the renderer's, and the renderer's layers stay on the frame until
    /// that fade ends (`detach()` comes then): keep something under the image
    /// until the fade ends. A renderer that empties the frame sooner — removes
    /// or hides its layers here, or animates them out faster than the fade —
    /// lets the half-faded image show what is behind the frame (on a dark
    /// ground, the image dims and comes back). Nothing is called on each
    /// frame: the renderer's own Core Animation runs on.
    func finish(source: NetworkImageSource, transition: CFTimeInterval)
    /// The load failed; the error image fades in after `transition` / 6, over
    /// 5 × `transition` / 6, drawn above the renderer's layers, which stay on
    /// the frame until it is in (`detach()` comes then).
    func fail(transition: CFTimeInterval)
    /// Taken off the frame: remove the layers and stop watching. Called when
    /// the image's fade ends (the frame then draws the image itself, with
    /// nothing under it that shows), when the error image is in, and when the
    /// frame leaves the screen or its URL changes mid-load.
    func detach()
}

public extension NetworkImageLoadingRenderer {
    func update(context: NetworkImageRendererContext) {}
    func resize(to size: CGSize) {}
}

/// Renderers by name: `register("progressFill") { ProgressFillRenderer() }` at launch,
/// `"loadingRenderer": "progressFill"` in a layout.
@MainActor
public enum NetworkImageLoadingRenderers {
    private static var factories: [String: () -> NetworkImageLoadingRenderer] = [:]
    private static var warned: Set<String> = []

    public static func register(_ name: String, factory: @escaping () -> NetworkImageLoadingRenderer) {
        factories[name] = factory
    }

    public static func unregister(_ name: String) {
        factories[name] = nil
    }

    /// The factory for `name`; nil for nil, "" or a name nothing registered
    /// (the frame then draws the loading state as before — the placeholder
    /// chain). An unregistered name is logged once in DEBUG.
    static func factory(for name: String?) -> (() -> NetworkImageLoadingRenderer)? {
        guard let name, !name.isEmpty else { return nil }
        if let factory = factories[name] { return factory }
        #if DEBUG
        if !warned.contains(name) {
            warned.insert(name)
            print("[NetworkImage] loadingRenderer '\(name)' is not registered (NetworkImageLoadingRenderers.register): the loading state is drawn as without one")
        }
        #endif
        return nil
    }
}

// MARK: - The fades

/// One fade into the loaded image or the error image: wait `delay`, then run
/// `duration` along the cubic Bézier `curve` (seconds).
struct NetworkImageFade: Equatable {
    var delay: CFTimeInterval
    var duration: CFTimeInterval
    var curve: (Float, Float, Float, Float)

    static func == (a: NetworkImageFade, b: NetworkImageFade) -> Bool {
        abs(a.delay - b.delay) < 1e-9 && abs(a.duration - b.duration) < 1e-9
            && a.curve.0 == b.curve.0 && a.curve.1 == b.curve.1 && a.curve.2 == b.curve.2 && a.curve.3 == b.curve.3
    }

    static let none = NetworkImageFade(delay: 0, duration: 0, curve: (0, 0, 1, 1))
    /// ease-in-out cubic: cubic-bezier(0.65, 0, 0.35, 1).
    static let easeInOutCubic: (Float, Float, Float, Float) = (0.65, 0, 0.35, 1)
    /// ease-out quadratic, 1 - (1 - t)^2, exactly: the quadratic Bézier
    /// through (0.5, 1) raised to a cubic.
    static let easeOutQuad: (Float, Float, Float, Float) = (1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0, 1)

    enum Target { case image, error }

    /// The fade for the case (the ruling's table, T = transitionDuration in
    /// seconds): a memory-cache image never fades; with a renderer on the
    /// frame the image fades over T (ease-in-out cubic) and the error image
    /// waits T/6 then fades over 5T/6; done before the renderer was put on
    /// (within loadingDelay or waiting its turn), either fades over T/2
    /// (ease-out quadratic); with no renderer named, a written T fades over T
    /// (ease-out quadratic).
    static func fade(_ target: Target, transition t: CFTimeInterval, rendererNamed: Bool, rendererAttached: Bool, fromMemory: Bool) -> NetworkImageFade {
        guard !fromMemory, t > 0 else { return .none }
        guard rendererNamed else {
            return NetworkImageFade(delay: 0, duration: t, curve: easeOutQuad)
        }
        guard rendererAttached else {
            return NetworkImageFade(delay: 0, duration: t / 2, curve: easeOutQuad)
        }
        switch target {
        case .image: return NetworkImageFade(delay: 0, duration: t, curve: easeInOutCubic)
        case .error: return NetworkImageFade(delay: t / 6, duration: t * 5 / 6, curve: easeInOutCubic)
        }
    }

    var swiftUIAnimation: Animation {
        Animation.timingCurve(Double(curve.0), Double(curve.1), Double(curve.2), Double(curve.3), duration: duration).delay(delay)
    }

    var mediaTimingFunction: CAMediaTimingFunction {
        CAMediaTimingFunction(controlPoints: curve.0, curve.1, curve.2, curve.3)
    }
}

/// The milliseconds a layout wrote, as the ruling reads them: loadingDelay
/// 0...2000 (200 when a renderer is named), transitionDuration 0...1000
/// (240 when a renderer was found at run time, otherwise 0).
enum NetworkImageTiming {
    static func loadingDelay(_ written: Int?) -> CFTimeInterval {
        guard let written else { return 0.2 }
        return CFTimeInterval(min(2000, max(0, written))) / 1000
    }

    static func transition(_ written: Int?, rendererFound: Bool) -> CFTimeInterval {
        guard let written else { return rendererFound ? 0.24 : 0 }
        return CFTimeInterval(min(1000, max(0, written))) / 1000
    }
}

// MARK: - At most four renderers put on in one frame

/// Renderers start in turns: at most four frames get theirs in one display
/// frame, the rest the next. A frame whose load ends while it waits its turn
/// is taken out (its image fades as "done before the renderer was put on").
@MainActor
final class NetworkImageAttachQueue: NSObject {
    static let shared = NetworkImageAttachQueue()
    static let perFrame = 4

    private var waiting: [(id: ObjectIdentifier, run: () -> Void)] = []
    private var link: CADisplayLink?

    func enqueue(_ owner: AnyObject, _ run: @escaping () -> Void) {
        let id = ObjectIdentifier(owner)
        waiting.removeAll { $0.id == id }
        waiting.append((id, run))
        if link == nil {
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            self.link = link
        }
    }

    func remove(_ owner: AnyObject) {
        let id = ObjectIdentifier(owner)
        waiting.removeAll { $0.id == id }
    }

    @objc private func tick() {
        let now = Array(waiting.prefix(Self.perFrame))
        waiting.removeFirst(now.count)
        now.forEach { $0.run() }
        if waiting.isEmpty {
            link?.invalidate()
            link = nil
        }
    }
}
