//
//  WebView.swift
//  SwiftJsonUI
//
//  SwiftUI WebView implementation using WKWebView
//

import SwiftUI
import WebKit
import Combine

public struct WebView: UIViewRepresentable {
    // MARK: - Conformance load markers
    //
    // 🔻 A WKWebView EXISTS THE INSTANT IT IS MADE, and the conformance host's
    // only gate before a screenshot is "the fixture's screen is on". So the
    // capture raced `loadHTMLString`, and BOTH SIDES of that race are present
    // in committed baselines: one bake caught `Web/html__static` blank, an
    // earlier one caught its control blank and hashed all zeroes. Either way
    // `control_diff` reported the fixture ACTIVE — a race satisfies "differs
    // from its control" for the wrong reason, so no Web attribute was being
    // measured on iOS at all.
    //
    // The completion signal already existed (`didFinish`, below) and simply
    // was not reachable from a UI test. It is surfaced here on the UIKit view
    // rather than as a SwiftUI `.accessibilityIdentifier` on a wrapper: the
    // host learned the hard way that an identifier on a wrapper is pushed down
    // onto the content and clobbers the ids underneath it.
    //
    // ⚠️ OFF UNLESS ASKED. A consumer's own UI tests must not acquire a new
    // element, so this does nothing until the host sets the variable at launch.
    public static let webPendingIdentifier = "sjui_web_pending"
    public static let webLoadedIdentifier = "sjui_web_loaded"
    /// Read once: `ProcessInfo.environment` bridges a dictionary on every
    /// access, and this is consulted from each navigation callback.
    public static let conformanceLoadMarkersEnabled: Bool =
        ProcessInfo.processInfo.environment["JSONUI_CONFORMANCE_WEB_MARKERS"] == "1"

    let url: URL?
    /// Raw HTML to render when there is no `url`, matching the web platform's
    /// own precedence (iframe `src` wins over `srcdoc`).
    let html: String?
    var backgroundColor: UIColor?
    /// WebKit defaults both of these to true, so the defaults here keep the
    /// previous behaviour for callers that do not pass them.
    var allowsLinkPreview: Bool
    var allowsBackForwardNavigationGestures: Bool
    @SwiftUI.Binding var isLoading: Bool
    @SwiftUI.Binding var canGoBack: Bool
    @SwiftUI.Binding var canGoForward: Bool
    var onNavigationCommit: ((URL?) -> Void)?
    /// Called when the MAIN-FRAME load fails: the navigation failed (no
    /// connection, timeout, DNS, TLS) or the response is HTTP 4xx/5xx. Never
    /// for a subresource or a subframe, never for a navigation cancelled by
    /// the next one, and at most once per load (the `Web` attribute
    /// `onLoadFailed` in attribute_definitions.json).
    var onLoadFailed: (() -> Void)?
    /// Each CHANGE of this value reloads the view's own source — `url`, or
    /// `html` when there is no url. The value the view is created with loads
    /// nothing extra (the `Web` attribute `reloadToken`).
    var reloadToken: AnyHashable?

    // Simple initializer for basic usage
    public init(
        url: URL?,
        html: String? = nil,
        backgroundColor: UIColor? = nil,
        allowsLinkPreview: Bool = true,
        allowsBackForwardNavigationGestures: Bool = true,
        onLoadFailed: (() -> Void)? = nil,
        reloadToken: AnyHashable? = nil
    ) {
        self.url = url
        self.html = html
        self.backgroundColor = backgroundColor
        self.allowsLinkPreview = allowsLinkPreview
        self.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        self._isLoading = .constant(false)
        self._canGoBack = .constant(false)
        self._canGoForward = .constant(false)
        self.onNavigationCommit = nil
        self.onLoadFailed = onLoadFailed
        self.reloadToken = reloadToken
    }

    // Full initializer with bindings
    public init(url: URL?,
                html: String? = nil,
                backgroundColor: UIColor? = nil,
                allowsLinkPreview: Bool = true,
                allowsBackForwardNavigationGestures: Bool = true,
                isLoading: SwiftUI.Binding<Bool>,
                canGoBack: SwiftUI.Binding<Bool>,
                canGoForward: SwiftUI.Binding<Bool>,
                onNavigationCommit: ((URL?) -> Void)? = nil,
                onLoadFailed: (() -> Void)? = nil,
                reloadToken: AnyHashable? = nil) {
        self.url = url
        self.html = html
        self.backgroundColor = backgroundColor
        self.allowsLinkPreview = allowsLinkPreview
        self.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        self._isLoading = isLoading
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self.onNavigationCommit = onNavigationCommit
        self.onLoadFailed = onLoadFailed
        self.reloadToken = reloadToken
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if Self.conformanceLoadMarkersEnabled {
            // ⚠️ A MARKER SUBVIEW, NOT AN IDENTIFIER ON THE WEB VIEW. Setting
            // `webView.accessibilityIdentifier` was the first attempt and was
            // MEASURED not to reach the element tree: with it in place the
            // host queried `pending=false loaded=false` on both Web fixtures.
            // A WKWebView is an accessibility CONTAINER for the page content,
            // so naming the container does not produce an element. A 1x1 view
            // that IS an accessibility element does — the same shape the
            // conformance host uses for its own fixture markers.
            //
            // Pending is stamped before any load starts: the window between
            // makeUIView and didStartProvisionalNavigation is exactly the
            // window the capture used to land in.
            let marker = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            marker.isAccessibilityElement = true
            marker.accessibilityIdentifier = Self.webPendingIdentifier
            marker.isUserInteractionEnabled = false
            marker.backgroundColor = .clear
            webView.addSubview(marker)
            context.coordinator.loadMarker = marker
        }
        webView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        webView.allowsLinkPreview = allowsLinkPreview

        // Background color
        if let bgColor = backgroundColor {
            webView.isOpaque = false
            webView.backgroundColor = bgColor
            webView.scrollView.backgroundColor = bgColor
        }

        // Load initial URL if provided, otherwise the raw HTML
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
            // Recorded here, as the html branch always was. Without it the
            // first updateUIView — which SwiftUI runs right after this —
            // saw a url it had "never loaded" and loaded it again, cancelling
            // this load (NSURLErrorCancelled) on every Web that has a url.
            context.coordinator.lastLoadedURL = url
        } else if let html = html {
            webView.loadHTMLString(html, baseURL: nil)
            context.coordinator.lastLoadedHTML = html
        }
        // The token the view is created with is the baseline, not a request.
        context.coordinator.lastReloadToken = reloadToken

        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        // The coordinator was made with the FIRST struct. Without this the
        // delegate callbacks keep calling that struct's closures — a handler
        // passed on a later render (onLoadFailed, onNavigationCommit) would
        // never be the one called.
        context.coordinator.parent = self

        let coordinator = context.coordinator
        switch Self.loadAction(
            url: url, html: html,
            lastLoadedURL: coordinator.lastLoadedURL, lastLoadedHTML: coordinator.lastLoadedHTML,
            reloadToken: reloadToken, lastReloadToken: coordinator.lastReloadToken
        ) {
        case .loadURL(let url):
            webView.load(URLRequest(url: url))
            coordinator.lastLoadedURL = url
        case .loadHTML(let html):
            webView.loadHTMLString(html, baseURL: nil)
            coordinator.lastLoadedHTML = html
        case .none:
            break
        }
        coordinator.lastReloadToken = reloadToken
    }

    /// What `updateUIView` loads, if anything.
    enum LoadAction: Equatable {
        case none
        case loadURL(URL)
        case loadHTML(String)
    }

    /// Decided apart from the view so every branch can be tested without one.
    ///
    /// - A url that moved since the last load loads.
    /// - With no url, html that moved loads — guarded on the string so a
    ///   re-render does not reload the document and throw away scroll
    ///   position, the same way the url path is.
    /// - Otherwise a moved `reloadToken` loads the SAME source again. Not
    ///   `WKWebView.reload()`: after a failed provisional navigation there is
    ///   no committed item for it to reload, which is exactly the state a
    ///   retry is issued from.
    /// - At most one load per update: a token that moves together with the
    ///   url is served by the url's own load, not by a second one that would
    ///   cancel it.
    static func loadAction(
        url: URL?, html: String?,
        lastLoadedURL: URL?, lastLoadedHTML: String?,
        reloadToken: AnyHashable?, lastReloadToken: AnyHashable?
    ) -> LoadAction {
        if let url = url, url != lastLoadedURL { return .loadURL(url) }
        if url == nil, let html = html, html != lastLoadedHTML { return .loadHTML(html) }
        guard reloadToken != lastReloadToken else { return .none }
        if let url = url { return .loadURL(url) }
        if let html = html { return .loadHTML(html) }
        return .none
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastLoadedURL: URL?
        var lastLoadedHTML: String?
        var lastReloadToken: AnyHashable?
        /// Set once onLoadFailed has been called for the current load, so a
        /// 4xx/5xx response whose body then fails to arrive is one failure.
        var loadFailureReported = false
        /// The 1x1 element whose identifier says whether the page has painted.
        /// Only made when the host asks for it; nil for every other caller.
        weak var loadMarker: UIView?
        
        init(_ parent: WebView) {
            self.parent = parent
        }

        /// Navigation reached a TERMINAL outcome — finished or failed.
        ///
        /// A failure flips the marker too, on purpose: the host must not hang
        /// waiting for a page that will never arrive, and a capture of the
        /// failed state is a real answer the fixture-vs-control arm can judge.
        /// Silence is the only outcome nobody can read.
        func markSettled(_ webView: WKWebView) {
            guard WebView.conformanceLoadMarkersEnabled else { return }
            loadMarker?.accessibilityIdentifier = WebView.webLoadedIdentifier
        }

        /// Whether a navigation error is a load FAILURE. A navigation that
        /// another one replaced (a link tapped mid-load, a reloadToken retry)
        /// ends with NSURLErrorCancelled; that is not the page failing.
        static func isLoadFailure(_ error: Error) -> Bool {
            let nsError = error as NSError
            return !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled)
        }

        /// Whether a main-frame response status is a load failure.
        static func isLoadFailure(statusCode: Int) -> Bool {
            statusCode >= 400
        }

        func reportLoadFailure() {
            guard !loadFailureReported else { return }
            loadFailureReported = true
            parent.onLoadFailed?()
        }
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            loadFailureReported = false
            parent.isLoading = true
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        /// Main-frame HTTP status. The response is still allowed — the page
        /// the server sent is displayed exactly as before; the handler decides
        /// whether to cover it.
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            reportIfFailed(isForMainFrame: navigationResponse.isForMainFrame, response: navigationResponse.response)
            decisionHandler(.allow)
        }

        /// The decision `decidePolicyFor(navigationResponse:)` makes, apart
        /// from the delegate method so it can be tested: a WKNavigationResponse
        /// cannot be made outside WebKit (a subclass crashes in
        /// -[WKNavigationResponse dealloc] on iOS 26), and a real one needs a
        /// server, which the CI simulators could not reach.
        func reportIfFailed(isForMainFrame: Bool, response: URLResponse) {
            if isForMainFrame,
               let http = response as? HTTPURLResponse,
               Self.isLoadFailure(statusCode: http.statusCode) {
                reportLoadFailure()
            }
        }

        public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.onNavigationCommit?(webView.url)
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            markSettled(webView)
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            markSettled(webView)
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            print("WebView navigation failed: \(error.localizedDescription)")
            if Self.isLoadFailure(error) { reportLoadFailure() }
        }
        
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            markSettled(webView)
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            print("WebView provisional navigation failed: \(error.localizedDescription)")
            if Self.isLoadFailure(error) { reportLoadFailure() }
        }
    }
}

// MARK: - Preview
struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(url: URL(string: "https://www.apple.com"))
    }
}