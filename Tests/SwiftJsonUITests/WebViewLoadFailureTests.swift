//
//  WebViewLoadFailureTests.swift
//  SwiftJsonUITests
//
//  The `Web` attributes `onLoadFailed` and `reloadToken`
//  (ssot-web-component-has-no-load-failure-event-or-reload-trigger).
//
//  The decision arms run without WebKit. The HTTP-status arms call the
//  decision `decidePolicyFor(navigationResponse:)` makes, with a real
//  HTTPURLResponse; the cancellation arms call the two failure callbacks with
//  real NSErrors. One arm drives a real
//  WKWebView with the library's Coordinator as its delegate, with no network
//  at all: a custom-scheme load that fails. See "NO NETWORK BELOW" for why.
//

import XCTest
import WebKit
@testable import SwiftJsonUI

final class WebViewLoadFailureTests: XCTestCase {

    // MARK: - What updateUIView loads

    private let a = URL(string: "https://a.test/")!
    private let b = URL(string: "https://b.test/")!

    private func action(
        url: URL?, html: String? = nil,
        lastURL: URL? = nil, lastHTML: String? = nil,
        token: AnyHashable? = nil, lastToken: AnyHashable? = nil
    ) -> WebView.LoadAction {
        WebView.loadAction(
            url: url, html: html, lastLoadedURL: lastURL, lastLoadedHTML: lastHTML,
            reloadToken: token, lastReloadToken: lastToken
        )
    }

    func testAnUnmovedUrlAndTokenLoadNothing() {
        XCTAssertEqual(action(url: a, lastURL: a, token: 1, lastToken: 1), .none)
    }

    func testAMovedTokenLoadsTheSameUrlAgain() {
        XCTAssertEqual(action(url: a, lastURL: a, token: 2, lastToken: 1), .loadURL(a))
    }

    func testAMovedTokenLoadsTheHtmlAgainWhenThereIsNoUrl() {
        XCTAssertEqual(
            action(url: nil, html: "<p>x</p>", lastHTML: "<p>x</p>", token: 2, lastToken: 1),
            .loadHTML("<p>x</p>")
        )
    }

    /// One action per update by construction; this pins which one.
    func testATokenMovingWithTheUrlIsServedByTheUrlsLoad() {
        XCTAssertEqual(action(url: b, lastURL: a, token: 2, lastToken: 1), .loadURL(b))
    }

    func testATokenThatArrivesLaterIsAChange() {
        XCTAssertEqual(action(url: a, lastURL: a, token: 0, lastToken: nil), .loadURL(a))
    }

    func testNoTokenAtAllLoadsNothingExtra() {
        XCTAssertEqual(action(url: a, lastURL: a), .none)
    }

    func testAMovedUrlStillLoadsWithoutAToken() {
        XCTAssertEqual(action(url: b, lastURL: a), .loadURL(b))
    }

    // MARK: - What counts as a failure

    func testACancelledNavigationIsNotAFailure() {
        let cancelled = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        XCTAssertFalse(WebView.Coordinator.isLoadFailure(cancelled))
    }

    func testNetworkFailuresAreFailures() {
        for code in [NSURLErrorCannotFindHost, NSURLErrorNotConnectedToInternet,
                     NSURLErrorTimedOut, NSURLErrorServerCertificateUntrusted] {
            XCTAssertTrue(WebView.Coordinator.isLoadFailure(NSError(domain: NSURLErrorDomain, code: code)), "\(code)")
        }
        // The same number in another domain is not a cancellation.
        XCTAssertTrue(WebView.Coordinator.isLoadFailure(NSError(domain: WKErrorDomain, code: NSURLErrorCancelled)))
    }

    func testOnly4xxAnd5xxAreFailures() {
        XCTAssertFalse(WebView.Coordinator.isLoadFailure(statusCode: 399))
        XCTAssertTrue(WebView.Coordinator.isLoadFailure(statusCode: 400))
        XCTAssertTrue(WebView.Coordinator.isLoadFailure(statusCode: 500))
    }

    func testOneLoadReportsOnceAndTheNextLoadReportsAgain() {
        var calls = 0
        let coordinator = WebView.Coordinator(WebView(url: a, onLoadFailed: { calls += 1 }))
        coordinator.reportLoadFailure()
        coordinator.reportLoadFailure() // e.g. a 404 whose body then fails
        XCTAssertEqual(calls, 1)
        coordinator.webView(WKWebView(), didStartProvisionalNavigation: nil)
        coordinator.reportLoadFailure()
        XCTAssertEqual(calls, 2)
    }

    // MARK: - WebKit

    // 🔻 NO NETWORK BELOW. The first version of these arms served 404 / 500
    // from an NWListener on 127.0.0.1. They passed here (Xcode 26.6 on iOS
    // 26.5 and 18.6) and failed on both CI legs (Xcode 16.4 / iOS 18 and 26.3
    // / iOS 26, run 36075992379): the page never arrived, so an arm that
    // asserts "reported once" could pass for the wrong reason and the page
    // read timed out. What the runner's simulator does with loopback is not
    // ours to decide, so:
    // - the HTTP status goes straight into the decision
    //   `decidePolicyFor(navigationResponse:)` makes (`reportIfFailed`), with
    //   a real HTTPURLResponse. Neither vehicle for a WHOLE navigation
    //   response works here: a WKURLSchemeHandler cannot deliver a status
    //   (measured on iOS 26.5, it arrives as a plain NSURLResponse), and a
    //   WKNavigationResponse subclass crashes in its dealloc on iOS 26.4;
    // - the cancellation of a replaced load goes straight into the two
    //   failure callbacks (whether WebKit reports it at all varies; see that
    //   arm).
    // The one WebKit arm fails its load in a scheme handler rather than at a
    // resolver: `.invalid` passed on both CI legs once and timed out on the
    // 26.3 leg the next time (run 36078332508).

    /// Runs the library's status decision on one response with a real HTTP
    /// status. It is the body of `decidePolicyFor(navigationResponse:)`,
    /// which only adds `decisionHandler(.allow)` — the server's page is
    /// displayed as before.
    private func failures(mainFrame: Bool, status: Int) -> Int {
        var failures = 0
        let coordinator = WebView.Coordinator(WebView(url: nil, onLoadFailed: { failures += 1 }))
        let response = HTTPURLResponse(
            url: URL(string: "https://example.test/page")!, statusCode: status,
            httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "text/html"]
        )!
        coordinator.reportIfFailed(isForMainFrame: mainFrame, response: response)
        return failures
    }

    func testAMainFrame404ReportsOnce() {
        XCTAssertEqual(failures(mainFrame: true, status: 404), 1)
    }

    func testAMainFrame500ReportsOnce() {
        XCTAssertEqual(failures(mainFrame: true, status: 500), 1)
    }

    /// The negatives beside them, through the same method: a page that
    /// loads, a 3xx, a 404 that is only a subframe's, and a response that is
    /// not HTTP at all.
    func testA200AndASubframe404ReportNothing() {
        XCTAssertEqual(failures(mainFrame: true, status: 200), 0)
        XCTAssertEqual(failures(mainFrame: true, status: 399), 0)
        XCTAssertEqual(failures(mainFrame: false, status: 404), 0)
        var calls = 0
        let coordinator = WebView.Coordinator(WebView(url: nil, onLoadFailed: { calls += 1 }))
        coordinator.reportIfFailed(
            isForMainFrame: true,
            response: URLResponse(url: URL(string: "about:blank")!, mimeType: "text/html",
                                  expectedContentLength: 0, textEncodingName: nil)
        )
        XCTAssertEqual(calls, 0)
    }

    /// A custom-scheme request that fails the way a lookup does
    /// (NSURLErrorCannotFindHost), with no resolver and no server involved.
    private final class FailingSchemeHandler: NSObject, WKURLSchemeHandler {
        func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
            task.didFailWithError(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost))
        }
        func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
    }

    /// A real WKWebView whose delegate is the library's Coordinator; counts
    /// onLoadFailed.
    private final class Harness {
        var failures = 0
        let coordinator: WebView.Coordinator
        let webView: WKWebView
        private let failing = FailingSchemeHandler()

        init() {
            let configuration = WKWebViewConfiguration()
            configuration.setURLSchemeHandler(failing, forURLScheme: "sjuifail")
            webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 200), configuration: configuration)
            var box: Harness?
            coordinator = WebView.Coordinator(WebView(url: nil, onLoadFailed: { box?.failures += 1 }))
            box = self
            webView.navigationDelegate = coordinator
        }
    }

    private func waitUntilSettled(_ webView: WKWebView, extra: TimeInterval = 1.0) {
        let settled = expectation(for: NSPredicate { object, _ in
            guard let view = object as? WKWebView else { return false }
            return !view.isLoading
        }, evaluatedWith: webView)
        wait(for: [settled], timeout: 30)
        // Anything WebKit would still deliver for this load has had a moment
        // to arrive.
        RunLoop.main.run(until: Date().addingTimeInterval(extra))
    }

    /// The one arm through WebKit itself: a main-frame load that fails before
    /// any response reaches didFailProvisionalNavigation and reports once.
    /// It used to load `https://conformance.invalid/` — measured, 20 of 20
    /// reported within ~2 s here (Xcode 26.5 / iOS 26.4, Xcode 26.6 / iOS
    /// 18.6), and on CI it passed on both legs once and then waited 30 s for
    /// nothing on the Xcode 26.3 leg (run 36078332508): how fast a runner's
    /// resolver fails `.invalid` is not ours. A failing scheme handler reports
    /// in 0.2–0.5 s on both runtimes here, with no resolver in the path.
    func testAMainFrameLoadThatFailsReportsOnce() {
        let harness = Harness()
        harness.webView.load(URLRequest(url: URL(string: "sjuifail://h/page")!))
        let reported = expectation(for: NSPredicate { _, _ in harness.failures > 0 }, evaluatedWith: nil)
        wait(for: [reported], timeout: 30)
        waitUntilSettled(harness.webView)
        XCTAssertEqual(harness.failures, 1)
    }

    /// A navigation another one replaced ends in NSURLErrorCancelled, through
    /// either failure callback; it is not the page failing. Handed to the
    /// library's delegate methods directly: whether WebKit reports the
    /// cancellation at all varies — measured, a TEST-NET load replaced after
    /// 1 s delivered it on iOS 26.5 and 18.6 here and nothing on either CI
    /// leg, and a stalled custom-scheme load replaced by loadHTMLString
    /// delivered nothing on 26.4 or 18.6 — so an end-to-end arm could pass
    /// without ever meeting one.
    func testACancelledNavigationReportsNothingThroughEitherCallback() {
        var failures = 0
        let coordinator = WebView.Coordinator(WebView(url: nil, onLoadFailed: { failures += 1 }))
        let cancelled = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        coordinator.webView(WKWebView(), didFailProvisionalNavigation: nil, withError: cancelled)
        coordinator.webView(WKWebView(), didFail: nil, withError: cancelled)
        XCTAssertEqual(failures, 0)
    }

    /// The same two callbacks with a real failure: each reports (the flag
    /// resets between loads).
    func testAFailedNavigationReportsThroughEitherCallback() {
        var failures = 0
        let coordinator = WebView.Coordinator(WebView(url: nil, onLoadFailed: { failures += 1 }))
        let notFound = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost)
        coordinator.webView(WKWebView(), didFailProvisionalNavigation: nil, withError: notFound)
        XCTAssertEqual(failures, 1)
        coordinator.webView(WKWebView(), didStartProvisionalNavigation: nil)
        coordinator.webView(WKWebView(), didFail: nil, withError: NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost))
        XCTAssertEqual(failures, 2)
    }
}
