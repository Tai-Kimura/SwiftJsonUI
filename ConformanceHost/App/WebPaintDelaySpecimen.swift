//
//  WebPaintDelaySpecimen.swift
//  ConformanceHost
//
//  Test-only: keeps every WKWebView covered until a declared delay after its
//  load marker says "loaded", so the screen shows a web view that has finished
//  loading and has not been drawn yet.
//
//  That state is the one a CI capture landed in (run 38470376663, iOS
//  Dynamic, Web/html__static: the load marker had flipped — waitedThenSettled
//  — and the picture was blank, ink 0). The marker flips on didFinish; a
//  WKWebView draws in its own process, so the page can reach the screen
//  later. On a fast machine it never does: 14 local runs of 10.29.11 and
//  10.29.12, alone and in the CI batch's order, found the page already
//  drawn every time, so a capture that does not wait for the drawing passed
//  exactly as one that does. With the delay set it captures the cover, and
//  the host's paint wait (ConformanceUITests.waitForWebPaint) is what tells
//  the two apart.
//
//  The cover is a plain white view on top of the web view's content, not an
//  accessibility element, so the load marker — the web view's own 1x1
//  subview — stays visible to the runner exactly as without it.
//
//  Declared by the run (CONFORMANCE_WEB_PAINT_DELAY, seconds, forwarded as a
//  launch environment variable by ConformanceUITests); unset or 0 is the
//  ordinary run. Choose it from the paint wait's own numbers: an order above
//  its 0.25 s poll and inside its 10 s budget — 2.5.
//

import SwiftJsonUI
import UIKit
import WebKit

@MainActor
enum WebPaintDelaySpecimen {
    static let seconds: Double =
        Double(ProcessInfo.processInfo.environment["CONFORMANCE_WEB_PAINT_DELAY"] ?? "") ?? 0

    private struct Cover {
        weak var webView: WKWebView?
        let cover: UIView
        var loadedAt: Date?
    }

    private static var covers: [ObjectIdentifier: Cover] = [:]
    private static var timer: Timer?

    /// Starts covering web views when the run declared a delay.
    static func startIfDeclared() {
        guard seconds > 0, timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            MainActor.assumeIsolated { tick() }
        }
    }

    private static func tick() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        for window in windows { cover(in: window) }
        let now = Date()
        for (key, var entry) in covers {
            guard let webView = entry.webView else {
                entry.cover.removeFromSuperview()
                covers[key] = nil
                continue
            }
            if entry.loadedAt == nil,
               webView.subviews.contains(where: { $0.accessibilityIdentifier == WebView.webLoadedIdentifier }) {
                entry.loadedAt = now
                covers[key] = entry
            }
            if let loadedAt = entry.loadedAt, now.timeIntervalSince(loadedAt) >= seconds,
               entry.cover.superview != nil {
                entry.cover.removeFromSuperview()
            }
        }
    }

    private static func cover(in view: UIView) {
        if let webView = view as? WKWebView {
            let key = ObjectIdentifier(webView)
            if covers[key] == nil {
                let cover = UIView(frame: webView.bounds)
                cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cover.backgroundColor = .white
                cover.isUserInteractionEnabled = false
                cover.isAccessibilityElement = false
                cover.accessibilityElementsHidden = true
                webView.addSubview(cover)
                covers[key] = Cover(webView: webView, cover: cover, loadedAt: nil)
            }
            return
        }
        for subview in view.subviews { cover(in: subview) }
    }
}
