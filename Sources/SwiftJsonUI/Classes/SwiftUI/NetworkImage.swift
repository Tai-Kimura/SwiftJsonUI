//
//  NetworkImage.swift
//  SwiftJsonUI
//
//  SwiftUI implementation of network image loading with retry and caching
//

import SwiftUI
import Combine

// MARK: - Network Image Cache (shared)

public final class SwiftUIImageCache {
    public static let shared = SwiftUIImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private var failedURLs: [String: Date] = [:]
    private let failedLock = NSLock()
    /// How long a failed URL stays blacklisted before allowing retry
    private let failedCooldown: TimeInterval = 30

    private init() {
        cache.countLimit = 200
    }

    public func get(_ key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    public func set(_ key: String, image: UIImage) {
        cache.setObject(image, forKey: key as NSString)
        // Clear from failed list on success
        failedLock.lock()
        failedURLs.removeValue(forKey: key)
        failedLock.unlock()
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
}

// MARK: - Image Loader (ObservableObject to avoid re-triggering on parent redraw)

private final class NetworkImageLoader: ObservableObject {
    @Published var loadedImage: UIImage?
    @Published var isLoading = false
    @Published var hasFailed = false

    private var currentUrl: String?
    private var loadTask: Task<Void, Never>?

    func loadIfNeeded(url: String?, headers: [String: String]) {
        guard let urlString = url, !urlString.isEmpty,
              URL(string: urlString) != nil else { return }

        // Already loaded this exact URL — no-op
        if currentUrl == urlString && loadedImage != nil { return }

        // Already failed this exact URL — don't retry automatically
        if currentUrl == urlString && hasFailed { return }

        // URL changed — cancel previous and start new
        if currentUrl != urlString {
            loadTask?.cancel()
            loadedImage = nil
            hasFailed = false
        }

        currentUrl = urlString

        // Check cache synchronously
        if let cached = SwiftUIImageCache.shared.get(urlString) {
            loadedImage = cached
            isLoading = false
            hasFailed = false
            return
        }

        // Skip recently failed URLs
        if SwiftUIImageCache.shared.isRecentlyFailed(urlString) {
            isLoading = false
            hasFailed = true
            return
        }

        // Already loading this URL
        if isLoading { return }

        isLoading = true
        hasFailed = false

        loadTask = Task { [weak self] in
            await self?.performLoad(urlString: urlString, headers: headers)
        }
    }

    func retry(url: String?, headers: [String: String]) {
        guard let urlString = url else { return }
        // Clear failed state to allow retry
        currentUrl = nil
        loadedImage = nil
        hasFailed = false
        loadIfNeeded(url: urlString, headers: headers)
    }

    private func performLoad(urlString: String, headers: [String: String]) async {
        guard let requestUrl = URL(string: urlString) else {
            await MainActor.run { isLoading = false }
            return
        }

        let shortUrl = urlString.suffix(40)
        Logger.debug("[NetworkImage] start loading ...\(shortUrl)")

        let maxRetries = 2
        for attempt in 0...maxRetries {
            if Task.isCancelled { return }

            if attempt > 0 {
                Logger.debug("[NetworkImage] retry \(attempt)/\(maxRetries) ...\(shortUrl)")
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 2_000_000_000)
                if Task.isCancelled { return }
            }

            do {
                var request = URLRequest(url: requestUrl)
                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }

                // Network + decode on background
                let (data, _) = try await URLSession.shared.data(for: request)
                if Task.isCancelled { return }

                let uiImage = UIImage(data: data)
                if Task.isCancelled { return }

                if let uiImage = uiImage {
                    Logger.debug("[NetworkImage] success ...\(shortUrl) size=\(uiImage.size)")
                    SwiftUIImageCache.shared.set(urlString, image: uiImage)

                    // UI update on MainActor only
                    await MainActor.run {
                        guard currentUrl == urlString else { return }
                        loadedImage = uiImage
                        isLoading = false
                    }
                    return
                }
            } catch {
                if Task.isCancelled { return }
                Logger.debug("[NetworkImage] error ...\(shortUrl): \(error.localizedDescription)")
            }
        }

        Logger.debug("[NetworkImage] failed after retries ...\(shortUrl)")
        SwiftUIImageCache.shared.markFailed(urlString)
        await MainActor.run {
            isLoading = false
            hasFailed = true
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - NetworkImage View

public struct NetworkImage: View {
    let url: String?
    let placeholder: String?
    let defaultImage: String?
    let errorImage: String?
    let loadingImage: String?
    let contentMode: ContentMode
    let renderingMode: Image.TemplateRenderingMode?
    let headers: [String: String]

    @StateObject private var loader = NetworkImageLoader()

    public enum ContentMode {
        case fit
        case fill
        case center
    }

    public init(
        url: String? = nil,
        placeholder: String? = nil,
        defaultImage: String? = nil,
        errorImage: String? = nil,
        loadingImage: String? = nil,
        contentMode: ContentMode = .fit,
        renderingMode: Image.TemplateRenderingMode? = nil,
        headers: [String: String] = [:]
    ) {
        self.url = url
        self.placeholder = placeholder ?? defaultImage
        self.defaultImage = defaultImage
        self.errorImage = errorImage
        self.loadingImage = loadingImage
        self.contentMode = contentMode
        self.renderingMode = renderingMode
        self.headers = headers
    }

    public var body: some View {
        Group {
            if let image = loader.loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(renderingMode)
                    .aspectRatio(contentMode: contentModeToSwiftUI())
            } else if loader.isLoading {
                if let loadingImage = loadingImage {
                    Image(loadingImage)
                        .resizable()
                        .renderingMode(renderingMode)
                        .aspectRatio(contentMode: contentModeToSwiftUI())
                } else if let placeholder = placeholder {
                    Image(placeholder)
                        .resizable()
                        .renderingMode(renderingMode)
                        .aspectRatio(contentMode: contentModeToSwiftUI())
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if loader.hasFailed {
                Button {
                    loader.retry(url: url, headers: headers)
                } label: {
                    if let errorImage = errorImage {
                        Image(errorImage)
                            .resizable()
                            .renderingMode(renderingMode)
                            .aspectRatio(contentMode: contentModeToSwiftUI())
                    } else if let placeholder = placeholder {
                        Image(placeholder)
                            .resizable()
                            .renderingMode(renderingMode)
                            .aspectRatio(contentMode: contentModeToSwiftUI())
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
            } else {
                if let placeholder = placeholder {
                    Image(placeholder)
                        .resizable()
                        .renderingMode(renderingMode)
                        .aspectRatio(contentMode: contentModeToSwiftUI())
                } else {
                    Color.clear
                }
            }
        }
        .onAppear {
            loader.loadIfNeeded(url: url, headers: headers)
        }
        .onChange(of: url) { newUrl in
            loader.loadIfNeeded(url: newUrl, headers: headers)
        }
    }

    private func contentModeToSwiftUI() -> SwiftUI.ContentMode {
        switch contentMode {
        case .fit:
            return .fit
        case .fill:
            return .fill
        case .center:
            return .fit
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
