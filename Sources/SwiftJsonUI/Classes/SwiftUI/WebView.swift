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
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    var onNavigationCommit: ((URL?) -> Void)?
    
    // Simple initializer for basic usage
    public init(url: URL?) {
        self.url = url
        self._isLoading = .constant(false)
        self._canGoBack = .constant(false)
        self._canGoForward = .constant(false)
        self.onNavigationCommit = nil
    }
    
    // Full initializer with bindings
    public init(url: URL?, 
                isLoading: Binding<Bool>,
                canGoBack: Binding<Bool>,
                canGoForward: Binding<Bool>,
                onNavigationCommit: ((URL?) -> Void)? = nil) {
        self.url = url
        self._isLoading = isLoading
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self.onNavigationCommit = onNavigationCommit
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Load initial URL if provided
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if URL has changed
        if let url = url, url != context.coordinator.lastLoadedURL {
            let request = URLRequest(url: url)
            webView.load(request)
            context.coordinator.lastLoadedURL = url
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastLoadedURL: URL?
        
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