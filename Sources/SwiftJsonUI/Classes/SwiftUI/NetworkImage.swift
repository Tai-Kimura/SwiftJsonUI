//
//  NetworkImage.swift
//  SwiftJsonUI
//
//  SwiftUI implementation of network image loading with retry and caching.
//  The reads are NetworkImageLoadTable's (one per URL, shared by the frames
//  showing it, stopped when none does); a frame naming a loadingRenderer
//  draws it while the image is read, and the image fades in over
//  transitionDuration (ticket jui-networkimage-load-listener, the
//  requester's ruling 2026-11-15).
//

import SwiftUI
import Combine
import QuartzCore

// MARK: - Network Image Cache (shared)

public final class SwiftUIImageCache {
    public static let shared = SwiftUIImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private var failedURLs: [String: Date] = [:]
    private let failedLock = NSLock()
    /// How long a failed URL stays blacklisted before allowing retry
    private let failedCooldown: TimeInterval = 30

    /// The default byte budget of the decoded images held (64 MiB).
    public static let defaultTotalCostLimit = 64 * 1024 * 1024

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = Self.defaultTotalCostLimit
    }

    /// The byte budget of the decoded images held: the images are kept
    /// prepared for display (decoded), and each costs its decoded bytes.
    /// `countLimit` 200 stays as well.
    public var totalCostLimit: Int {
        get { cache.totalCostLimit }
        set { cache.totalCostLimit = newValue }
    }

    public func get(_ key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    public func set(_ key: String, image: UIImage) {
        cache.setObject(image, forKey: key as NSString, cost: Self.decodedBytes(image))
        // Clear from failed list on success
        failedLock.lock()
        failedURLs.removeValue(forKey: key)
        failedLock.unlock()
    }

    /// The decoded size of `image` in bytes (4 a pixel when it has no CGImage).
    static func decodedBytes(_ image: UIImage) -> Int {
        if let cg = image.cgImage { return cg.bytesPerRow * cg.height }
        return Int(image.size.width * image.scale * image.size.height * image.scale * 4)
    }

    /// Drop `key`'s image from memory (the next load reads the URL again).
    func remove(_ key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    /// Returns true if this URL recently failed and should not be retried yet
    public func isRecentlyFailed(_ key: String) -> Bool {
        failedLock.lock()
        defer { failedLock.unlock() }
        guard let failedAt = failedURLs[key] else { return false }
        if Date().timeIntervalSince(failedAt) > failedCooldown {
            failedURLs.removeValue(forKey: key)
            return false
        }
        return true
    }

    /// Mark a URL as failed
    public func markFailed(_ key: String) {
        failedLock.lock()
        failedURLs[key] = Date()
        failedLock.unlock()
    }

    /// Lift a URL's failed mark before its cooldown runs out. Only a tap on
    /// the failed image does (NetworkImageLoader.retry): every other load of
    /// the URL still waits the cooldown out.
    public func clearFailed(_ key: String) {
        failedLock.lock()
        failedURLs.removeValue(forKey: key)
        failedLock.unlock()
    }
}

// MARK: - Image Loader (ObservableObject to avoid re-triggering on parent redraw)

/// A frame's view of its URL's load: the three states its body draws,
/// written on a change only (progress never touches them, so it never
/// redraws the body), the loading renderer's layer view while one is named,
/// and the frame's onLoadStateChange / onLoadEvent.
@MainActor
final class NetworkImageLoader: ObservableObject {
    @Published var loadedImage: UIImage?
    @Published var isLoading = false
    @Published var hasFailed = false
    /// The frame draws its layer view (the renderer, then the image fading in).
    @Published var hostActive = false
    /// How the error image comes in.
    @Published var errorFade: NetworkImageFade = .none
    /// The SwiftUI Image is drawn under the layer view (which shows the same
    /// image) before the layer view goes, so a container that crossfades the
    /// change never shows the ground through.
    @Published var imageUnderLayer = false

    /// What the frame draws, in the order its body decides: the renderer's
    /// layer view, the image, the loading state, the error image (errorImage,
    /// else defaultImage, else placeholder), or the no-src state (defaultImage,
    /// else placeholder — networkImage.noSrc = defaultImage).
    enum Face: String { case renderer, image, loading, failed, noSrc }

    var face: Face {
        if hostActive { return .renderer }
        if loadedImage != nil { return .image }
        if isLoading { return .loading }
        if hasFailed { return .failed }
        return .noSrc
    }

    private(set) var currentUrl: String?
    private var headers: [String: String] = [:]
    private(set) var load: NetworkImageLoad?
    private var observation: NetworkImageObservation?
    private weak var host: NetworkImageLayerView?
    private var reportedState: String?
    /// The shown image came from the memory cache (no fade, no renderer).
    private(set) var fromMemory = false

    // The frame's declaration, refreshed by the view.
    var rendererFactory: (() -> NetworkImageLoadingRenderer)?
    var loadingDelay: CFTimeInterval = 0.2
    var transition: CFTimeInterval = 0
    var gravity: CALayerContentsGravity = .resizeAspect
    var onLoadStateChange: ((String) -> Void)?
    var onLoadEvent: ((NetworkImageLoadEvent) -> Void)?

    init() {}

    /// No src: nil, "" or only whitespace (which URL(string:) would otherwise
    /// percent-encode into a URL that fails, drawing the error image).
    static func isNoSrc(_ url: String?) -> Bool {
        url?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }

    func loadIfNeeded(url: String?, headers: [String: String]) {
        if Self.isNoSrc(url) {
            // networkImage.noSrc = defaultImage. A frame whose src went away
            // drops the read and the image it had and draws the no-src state;
            // nothing is reported (no state name for it), and a src that
            // comes back is reported afresh (loading, or loaded from memory).
            guard currentUrl != nil else { return }
            stop()
            currentUrl = nil
            loadedImage = nil
            hasFailed = false
            isLoading = false
            hostActive = false
            reportedState = nil
            if imageUnderLayer { imageUnderLayer = false }
            return
        }
        guard let urlString = url, let requestUrl = URL(string: urlString) else { return }

        if currentUrl == urlString {
            // Loaded, failed, or reading: nothing to start.
            if loadedImage != nil || hasFailed || load != nil { return }
        } else {
            stop()
            loadedImage = nil
            hasFailed = false
            isLoading = false
            hostActive = false
            reportedState = nil
            if imageUnderLayer { imageUnderLayer = false }
        }
        currentUrl = urlString
        self.headers = headers

        if let cached = SwiftUIImageCache.shared.get(urlString) {
            fromMemory = true
            loadedImage = cached
            isLoading = false
            hasFailed = false
            report("loaded")
            onLoadEvent?(.finished(source: .memory))
            return
        }

        // A URL that failed a moment ago is not read again by itself (30 s);
        // a tap on the failed image is (retry).
        if SwiftUIImageCache.shared.isRecentlyFailed(urlString) {
            errorFade = .none
            isLoading = false
            hasFailed = true
            report("failed")
            return
        }

        start(urlString, url: requestUrl)
    }

    private func start(_ urlString: String, url: URL) {
        let load = NetworkImageLoadTable.shared.acquire(urlString, url: url, headers: headers)
        self.load = load
        fromMemory = false
        hasFailed = false
        isLoading = true
        if rendererFactory != nil { hostActive = true }
        report("loading")
        observation = load.observe { [weak self] event in self?.handle(event) }
        if let host { attachHost(host, colorScheme: nil) }
    }

    private func handle(_ event: NetworkImageLoadEvent) {
        onLoadEvent?(event)
        switch event {
        case .finished(let source): finish(source, image: load?.image)
        case .failed: fail()
        default: break
        }
    }

    /// The load's own image is shown; the memory cache is only the shortcut
    /// for the next frame of the URL, and may have let it go already.
    private func finish(_ source: NetworkImageSource, image: UIImage?) {
        guard currentUrl != nil, let image else {
            fail()
            return
        }
        letGo()
        if hostActive, let host {
            host.finish(image: image, source: source) { [weak self] in self?.handOver() }
            isLoading = false
            loadedImage = image
        } else {
            let fade = NetworkImageFade.fade(.image, transition: transition, rendererNamed: rendererFactory != nil,
                                             rendererAttached: false, fromMemory: false)
            let apply = {
                self.hostActive = false
                self.isLoading = false
                self.loadedImage = image
            }
            if fade.duration > 0 { withAnimation(fade.swiftUIAnimation, apply) } else { apply() }
        }
        report("loaded")
    }

    /// The layer view's fade is over: the SwiftUI Image goes under it first,
    /// and once that is on screen the layer view goes.
    private func handOver() {
        imageUnderLayer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self, self.imageUnderLayer else { return }
            self.hostActive = false
            self.imageUnderLayer = false
        }
    }

    private func fail() {
        letGo()
        if hostActive, let host {
            errorFade = host.fail { [weak self] in self?.hostActive = false }
        } else {
            errorFade = NetworkImageFade.fade(.error, transition: transition, rendererNamed: rendererFactory != nil,
                                              rendererAttached: false, fromMemory: false)
            hostActive = false
        }
        let apply = {
            self.isLoading = false
            self.hasFailed = true
        }
        if errorFade.duration > 0 { withAnimation(errorFade.swiftUIAnimation, apply) } else { apply() }
        report("failed")
    }

    /// A tap on the failed image: a new read of the URL, its failed mark and
    /// its entry gone (level 0, attempt 0).
    func retry(url: String?, headers: [String: String]) {
        guard let urlString = url else { return }
        NetworkImageLoadTable.shared.forget(urlString, headers: headers)
        stop()
        currentUrl = nil
        loadedImage = nil
        hasFailed = false
        loadIfNeeded(url: urlString, headers: headers)
    }

    /// The frame left the screen: stop watching (the read stops when no frame
    /// watches it). The state stays "loading"; coming back reads again.
    func disappear() {
        guard let load, !load.isDone else { return }
        stop()
        host?.takeOff()
    }

    private func letGo() {
        observation?.cancel()
        observation = nil
        if let load { NetworkImageLoadTable.shared.release(load) }
        load = nil
    }

    private func stop() {
        letGo()
        host?.takeOff()
    }

    private func report(_ state: String) {
        guard reportedState != state else { return }
        reportedState = state
        onLoadStateChange?(state)
    }

    private var lastScheme: ColorScheme = .light

    /// The layer view is up: it waits for the renderer on the load.
    func attachHost(_ view: NetworkImageLayerView, colorScheme: ColorScheme?) {
        host = view
        if let colorScheme { lastScheme = colorScheme }
        guard let load, !load.isDone, let factory = rendererFactory else { return }
        view.begin(load: load, factory: factory, delay: loadingDelay, transition: transition,
                   gravity: gravity, colorScheme: lastScheme)
    }

    deinit {
        let load = self.load
        let observation = self.observation
        let host = self.host
        Task { @MainActor in
            observation?.cancel()
            if let load { NetworkImageLoadTable.shared.release(load) }
            host?.takeOff()
        }
    }
}

// MARK: - NetworkImage View

public struct NetworkImage: View {
    /// Draws again when the colour mode changes: its images are the mode's own pictures (ThemedImage).
    @ObservedObject private var jsonUITheme = SwiftJsonUIConfiguration.shared
    let url: String?
    let placeholder: String?
    let defaultImage: String?
    let errorImage: String?
    let loadingImage: String?
    let contentMode: ContentMode
    let renderingMode: Image.TemplateRenderingMode?
    let headers: [String: String]
    let loadingRenderer: String?
    let loadingDelay: Int?
    let transitionDuration: Int?
    let onLoadStateChange: ((String) -> Void)?
    let onLoadEvent: ((NetworkImageLoadEvent) -> Void)?

    @StateObject private var loader = NetworkImageLoader()

    public enum ContentMode {
        case fit
        case fill
        case center
        /// fill = stretch (canonical image.fill = stretch,
        /// shared/core/attribute_semantics.json): resizable without an
        /// aspectRatio modifier — SwiftUI has no stretch ContentMode member.
        case stretch
        // Positional modes: the image draws UNSCALED, aligned inside the
        // available frame and cropped (UIKit contentMode positions).
        case top
        case bottom
        case left
        case right
    }

    /// - Parameters:
    ///   - loadingRenderer: a renderer registered with
    ///     `NetworkImageLoadingRenderers.register`, drawn while the image is
    ///     read from disk or the network, after `loadingDelay`; nil, "" or an
    ///     unregistered name draws the loading state as before.
    ///   - loadingDelay: milliseconds before the renderer is made (0-2000, 200).
    ///   - transitionDuration: T, the milliseconds the fades into the image and
    ///     the error image are measured from (0-1000; 240 with a renderer, 0 without).
    ///   - onLoadStateChange: "loading", "loaded", "failed", on a change only.
    ///   - onLoadEvent: every event of the frame's load (progress thinned).
    public init(
        url: String? = nil,
        placeholder: String? = nil,
        defaultImage: String? = nil,
        errorImage: String? = nil,
        loadingImage: String? = nil,
        contentMode: ContentMode = .fit,
        renderingMode: Image.TemplateRenderingMode? = nil,
        headers: [String: String] = [:],
        loadingRenderer: String? = nil,
        loadingDelay: Int? = nil,
        transitionDuration: Int? = nil,
        onLoadStateChange: ((String) -> Void)? = nil,
        onLoadEvent: ((NetworkImageLoadEvent) -> Void)? = nil
    ) {
        self.url = url
        // Kept distinct from defaultImage: the no-src state shows
        // defaultImage FIRST (canonical networkImage.noSrc = defaultImage,
        // shared/core/attribute_semantics.json); placeholder belongs to the
        // loading state.
        self.placeholder = placeholder
        self.defaultImage = defaultImage
        self.errorImage = errorImage
        self.loadingImage = loadingImage
        self.contentMode = contentMode
        self.renderingMode = renderingMode
        self.headers = headers
        self.loadingRenderer = loadingRenderer
        self.loadingDelay = loadingDelay
        self.transitionDuration = transitionDuration
        self.onLoadStateChange = onLoadStateChange
        self.onLoadEvent = onLoadEvent
    }

    /// Hands the frame's declaration to its loader (plain properties: setting
    /// them redraws nothing).
    private func configureLoader() {
        let factory = NetworkImageLoadingRenderers.factory(for: loadingRenderer)
        loader.rendererFactory = factory
        loader.loadingDelay = NetworkImageTiming.loadingDelay(loadingDelay)
        loader.transition = NetworkImageTiming.transition(transitionDuration, rendererFound: factory != nil)
        loader.gravity = contentMode.layerGravity
        loader.onLoadStateChange = onLoadStateChange
        loader.onLoadEvent = onLoadEvent
    }

    public var body: some View {
        configureLoader()
        return ZStack {
            // The image's own slot: the same view while the layer view is
            // above it and after the layer view goes.
            if let image = loader.loadedImage, loader.face == .image || loader.imageUnderLayer {
                styledImage(Image(uiImage: image))
                    .transition(.opacity)
            }
            switch loader.face {
            case .renderer:
                // The renderer's layers, then the image fading in on its
                // layer. One image element for VoiceOver (the alt goes on it
                // from outside); the layers themselves are hidden.
                ZStack {
                    NetworkImageLayerHost(loader: loader)
                        .accessibilityElement(children: .ignore)
                        .accessibilityAddTraits(.isImage)
                    if loader.hasFailed {
                        failedView
                            .transition(.opacity)
                    }
                }
            case .image:
                EmptyView()
            case .loading:
                if loader.rendererFactory != nil {
                    Color.clear
                } else if let loadingImage = loadingImage {
                    styledImage(Image(jsonUIAsset: loadingImage))
                } else if let placeholder = placeholder {
                    styledImage(Image(jsonUIAsset: placeholder))
                } else if let defaultImage = defaultImage {
                    styledImage(Image(jsonUIAsset: defaultImage))
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .failed:
                failedView
                    .transition(.opacity)
            case .noSrc:
                // No src at all: defaultImage first (canonical
                // networkImage.noSrc = defaultImage), then placeholder.
                if let defaultImage = defaultImage {
                    styledImage(Image(jsonUIAsset: defaultImage))
                } else if let placeholder = placeholder {
                    styledImage(Image(jsonUIAsset: placeholder))
                } else {
                    Color.clear
                }
            }
        }
        .onAppear {
            loader.loadIfNeeded(url: url, headers: headers)
        }
        .onDisappear {
            loader.disappear()
        }
        // Two-parameter form (iOS 17). The old value is not needed: `loadIfNeeded`
        // compares against its OWN `currentUrl` and no-ops when the string is
        // unchanged, so the previous value adds nothing here.
        .onChange(of: url) { _, newUrl in
            loader.loadIfNeeded(url: newUrl, headers: headers)
        }
    }

    /// The failed image: a button that reads the URL again.
    private var failedView: some View {
        Button {
            loader.retry(url: url, headers: headers)
        } label: {
            if let errorImage = errorImage {
                styledImage(Image(jsonUIAsset: errorImage))
            } else if let defaultImage = defaultImage {
                // error falls back to defaultImage (canonical chain).
                styledImage(Image(jsonUIAsset: defaultImage))
            } else if let placeholder = placeholder {
                styledImage(Image(jsonUIAsset: placeholder))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gray)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    /// Applies `.aspectRatio` only when a SwiftUI ContentMode exists —
    /// `.stretch` deliberately has none (absence of the modifier IS the
    /// stretch spelling).
    private struct AspectRatioIfPresent: ViewModifier {
        let mode: SwiftUI.ContentMode?
        func body(content: Content) -> some View {
            if let mode = mode {
                content.aspectRatio(contentMode: mode)
            } else {
                content
            }
        }
    }

    private func contentModeToSwiftUI() -> SwiftUI.ContentMode? {
        switch contentMode {
        case .fit:
            return .fit
        case .fill:
            return .fill
        case .stretch, .center, .top, .bottom, .left, .right:
            // nil = no aspectRatio modifier (stretch), or a positional mode
            // handled by styledImage's unscaled-aligned branch.
            return nil
        }
    }

    /// Alignment for the positional modes; nil for the scaling ones.
    private var positionalAlignment: Alignment? {
        switch contentMode {
        case .center: return .center
        case .top: return .top
        case .bottom: return .bottom
        case .left: return .leading
        case .right: return .trailing
        default: return nil
        }
    }

    /// One image-styling path for every state branch: positional modes are
    /// unscaled + aligned + clipped; scaling modes are resizable with or
    /// without an aspect ratio (nil aspect = the stretch spelling).
    @ViewBuilder
    private func styledImage(_ img: Image) -> some View {
        if let alignment = positionalAlignment {
            img
                .renderingMode(renderingMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .clipped()
                .contentShape(Rectangle())
        } else if let mode = contentModeToSwiftUI(), mode == .fill {
            // AspectFill is the crop: SwiftUI's `.fill` alone is fill-and-
            // overflow, drawn past the frame over the neighbours (jsonui-cli
            // ticket sjui-aspectfill-image-is-not-cropped-to-its-frame). Take
            // the offered size, as the positional branch does, and clip.
            img
                .resizable()
                .renderingMode(renderingMode)
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                // Drawing only is clipped; the hit shape is the frame
                // (sjui-aspectfill-image-takes-touches-outside-its-frame).
                .contentShape(Rectangle())
        } else if let mode = contentModeToSwiftUI() {
            img
                .resizable()
                .renderingMode(renderingMode)
                .aspectRatio(contentMode: mode)
        } else {
            img
                .resizable()
                .renderingMode(renderingMode)
        }
    }
}

// MARK: - Preview
struct NetworkImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Network Image Examples")
                .font(.headline)

            NetworkImage(
                url: "https://via.placeholder.com/150",
                contentMode: .fit
            )
            .frame(width: 150, height: 150)
            .background(Color.gray.opacity(0.2))

            NetworkImage(
                url: "https://invalid-url",
                placeholder: "placeholder_image",
                contentMode: .fill
            )
            .frame(width: 150, height: 100)
            .clipped()
            .background(Color.gray.opacity(0.2))
        }
        .padding()
    }
}
