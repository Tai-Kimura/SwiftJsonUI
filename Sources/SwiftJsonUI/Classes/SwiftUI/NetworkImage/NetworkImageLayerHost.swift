//
//  NetworkImageLayerHost.swift
//  SwiftJsonUI
//
//  The UIView a NetworkImage frame with a loading renderer draws while its
//  image is read from disk or the network (an image the memory cache holds
//  never makes one): the renderer's layers, put on after loadingDelay, and
//  the image on a CALayer above them, faded in by Core Animation in the same
//  CATransaction the renderer is told to finish in. The renderer's layers
//  stay under the fading image until the fade is over; then the renderer is
//  taken off, the frame puts its SwiftUI Image under this view (which shows
//  the same picture) and this view goes 50 ms later, so a container that
//  crossfades the change shows nothing through (ticket
//  jui-networkimage-load-listener, the requester's ruling 2026-11-15; ticket
//  sjui-networkimage-load-complete-flickers).
//
//  Hidden from VoiceOver: the NetworkImage stays one image element carrying
//  its alt, made by the SwiftUI around it.
//

import QuartzCore
import SwiftUI
import UIKit

@MainActor
final class NetworkImageLayerView: UIView {
    private let rendererLayer = CALayer()
    private let imageLayer = CALayer()
    private var renderer: NetworkImageLoadingRenderer?
    private var factory: (() -> NetworkImageLoadingRenderer)?
    private var load: NetworkImageLoad?
    private var delay: CFTimeInterval = 0.2
    private var transition: CFTimeInterval = 0.24
    private var colorScheme: ColorScheme = .light
    private var attachWork: DispatchWorkItem?
    private var ended = false
    private var reduceMotionObserver: NSObjectProtocol?

    var rendererAttached: Bool { renderer != nil }

    static let noImplicitActions: [String: CAAction] = [
        "contents": NSNull(), "opacity": NSNull(), "contentsScale": NSNull(), "contentsGravity": NSNull(),
        "bounds": NSNull(), "position": NSNull(),
    ]

    /// The image layer (tests read its animations).
    var imageLayerForTesting: CALayer { imageLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        isUserInteractionEnabled = false
        clipsToBounds = true
        layer.addSublayer(rendererLayer)
        // The image layer moves only by the fade added in finish: a bare
        // CALayer would also animate its contents and opacity by itself for
        // 0.25 s, and a fade shorter than that (T/2 when the load was done
        // before the renderer came) ended with the image dimmed for a frame
        // and fading in again.
        imageLayer.actions = NetworkImageLayerView.noImplicitActions
        imageLayer.opacity = 0
        imageLayer.masksToBounds = true
        layer.addSublayer(imageLayer)
        reduceMotionObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.contextChanged() }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    deinit {
        if let reduceMotionObserver { NotificationCenter.default.removeObserver(reduceMotionObserver) }
    }

    /// Starts the frame's wait for its renderer on `load`.
    func begin(load: NetworkImageLoad, factory: @escaping () -> NetworkImageLoadingRenderer,
               delay: CFTimeInterval, transition: CFTimeInterval, gravity: CALayerContentsGravity, colorScheme: ColorScheme) {
        guard self.load !== load else { return }
        takeOff()
        self.load = load
        self.factory = factory
        self.delay = delay
        self.transition = transition
        self.colorScheme = colorScheme
        imageLayer.contentsGravity = gravity
        ended = false
        let wait = max(0, delay - (CACurrentMediaTime() - load.startedAt))
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NetworkImageAttachQueue.shared.enqueue(self) { [weak self] in self?.putOn() }
        }
        attachWork = work
        // Past the delay already (a frame that joined or came back): the
        // next display frame, in its turn.
        DispatchQueue.main.asyncAfter(deadline: .now() + wait, execute: work)
    }

    func setColorScheme(_ scheme: ColorScheme) {
        guard scheme != colorScheme else { return }
        colorScheme = scheme
        contextChanged()
    }

    private var context: NetworkImageRendererContext {
        NetworkImageRendererContext(
            reduceMotion: UIAccessibility.isReduceMotionEnabled,
            colorScheme: colorScheme,
            elapsedSinceStart: load.map { CACurrentMediaTime() - $0.startedAt } ?? 0
        )
    }

    private func contextChanged() {
        renderer?.update(context: context)
    }

    private func putOn() {
        guard !ended, renderer == nil, let load, let factory else { return }
        let renderer = factory()
        self.renderer = renderer
        rendererLayer.frame = bounds
        renderer.attach(to: rendererLayer, load: load, size: bounds.size, context: context)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rendererLayer.frame = bounds
        imageLayer.frame = bounds
        CATransaction.commit()
        renderer?.resize(to: bounds.size)
    }

    /// The image is ready: tell the renderer and fade the image in, in one
    /// CATransaction. When the fade is over the renderer is taken off, then
    /// `done` runs.
    func finish(image: UIImage, source: NetworkImageSource, done: @escaping () -> Void) {
        guard !ended else { return }
        ended = true
        cancelWait()
        let fade = NetworkImageFade.fade(.image, transition: transition, rendererNamed: true,
                                         rendererAttached: rendererAttached, fromMemory: false)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            MainActor.assumeIsolated {
                self?.takeOff()
                done()
            }
        }
        renderer?.finish(source: source, transition: fade.duration)
        imageLayer.contents = image.cgImage
        imageLayer.contentsScale = image.scale
        imageLayer.opacity = 1
        if fade.duration > 0 {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = fade.duration
            animation.timingFunction = fade.mediaTimingFunction
            animation.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            imageLayer.add(animation, forKey: "networkImageFade")
        }
        CATransaction.commit()
    }

    /// The load failed: tell the renderer and keep the layers until the error
    /// image (drawn above by SwiftUI) has faded in. Returns that fade.
    func fail(done: @escaping () -> Void) -> NetworkImageFade {
        guard !ended else { return .none }
        ended = true
        cancelWait()
        let fade = NetworkImageFade.fade(.error, transition: transition, rendererNamed: true,
                                         rendererAttached: rendererAttached, fromMemory: false)
        renderer?.fail(transition: transition)
        DispatchQueue.main.asyncAfter(deadline: .now() + fade.delay + fade.duration) { [weak self] in
            self?.takeOff()
            done()
        }
        return fade
    }

    private func cancelWait() {
        attachWork?.cancel()
        attachWork = nil
        NetworkImageAttachQueue.shared.remove(self)
    }

    /// Takes the renderer off (the fade is over, or the frame went).
    func takeOff() {
        cancelWait()
        renderer?.detach()
        renderer = nil
        load = nil
    }
}

/// The layer view in SwiftUI.
struct NetworkImageLayerHost: UIViewRepresentable {
    let loader: NetworkImageLoader
    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> NetworkImageLayerView {
        let view = NetworkImageLayerView(frame: .zero)
        loader.attachHost(view, colorScheme: colorScheme)
        return view
    }

    func updateUIView(_ view: NetworkImageLayerView, context: Context) {
        view.setColorScheme(colorScheme)
        loader.attachHost(view, colorScheme: colorScheme)
    }

    static func dismantleUIView(_ view: NetworkImageLayerView, coordinator: ()) {
        view.takeOff()
    }
}

extension NetworkImage.ContentMode {
    /// The CALayer gravity drawing the image as the SwiftUI Image does. UIKit
    /// layers are not flipped, so top and bottom swap.
    var layerGravity: CALayerContentsGravity {
        switch self {
        case .fit: return .resizeAspect
        case .fill: return .resizeAspectFill
        case .stretch: return .resize
        case .center: return .center
        case .top: return .bottom
        case .bottom: return .top
        case .left: return .left
        case .right: return .right
        }
    }
}
