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
        
        init(_ parent: WebView) {
            self.parent = parent
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
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
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