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

    // Simple initializer for basic usage
    public init(
        url: URL?,
        html: String? = nil,
        backgroundColor: UIColor? = nil,
        allowsLinkPreview: Bool = true,
        allowsBackForwardNavigationGestures: Bool = true
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
                onNavigationCommit: ((URL?) -> Void)? = nil) {
        self.url = url
        self.html = html
        self.backgroundColor = backgroundColor
        self.allowsLinkPreview = allowsLinkPreview
        self.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        self._isLoading = isLoading
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self.onNavigationCommit = onNavigationCommit
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
        } else if let html = html {
            webView.loadHTMLString(html, baseURL: nil)
            context.coordinator.lastLoadedHTML = html
        }

        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if URL has changed
        if let url = url, url != context.coordinator.lastLoadedURL {
            let request = URLRequest(url: url)
            webView.load(request)
            context.coordinator.lastLoadedURL = url
        } else if url == nil, let html = html, html != context.coordinator.lastLoadedHTML {
            // Guarded on the string so a re-render does not reload the document
            // and throw away scroll position, the same way the URL path is.
            webView.loadHTMLString(html, baseURL: nil)
            context.coordinator.lastLoadedHTML = html
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastLoadedURL: URL?
        var lastLoadedHTML: String?
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
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
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
        }
        
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            markSettled(webView)
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            print("WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(url: URL(string: "https://www.apple.com"))
    }
}