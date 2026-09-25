//
//  WebViewLoadFailureTests.swift
//  SwiftJsonUITests
//
//  The `Web` attributes `onLoadFailed` and `reloadToken`
//  (ssot-web-component-has-no-load-failure-event-or-reload-trigger).
//
//  The decision arms run without WebKit. The last four drive a real WKWebView
//  with the library's Coordinator as its navigation delegate, because what
//  "main frame", "4xx" and "cancelled" mean is WebKit's to say, not ours:
//  a DNS failure on a name that can never resolve (RFC 2606 `.invalid`),
//  404 / 500 from a loopback HTTP server to the main frame and to an iframe,
//  a page that loads, and a load another one replaces.
//

import XCTest
import WebKit
import Network
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

    /// A loopback HTTP server, because the status has to come from HTTP: a
    /// WKURLSchemeHandler's HTTPURLResponse reaches the navigation delegate as
    /// a plain NSURLResponse with no status (measured on iOS 26.5 — `main=true
    /// type=NSURLResponse`), so a scheme handler cannot serve a 404 to it.
    private final class LoopbackServer {
        private let listener: NWListener
        private let queue = DispatchQueue(label: "sjui.tests.loopback")
        let port: UInt16

        /// `/missing` 404, `/boom` 500, `/ok` a page whose iframe is a 404.
        init() throws {
            listener = try NWListener(using: .tcp, on: .any)
            let ready = DispatchSemaphore(value: 0)
            listener.stateUpdateHandler = { state in
                if case .ready = state { ready.signal() }
            }
            listener.newConnectionHandler = { [queue] connection in
                connection.start(queue: queue)
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, _, _ in
                    let request = String(decoding: data ?? Data(), as: UTF8.self)
                    let path = request.split(separator: " ").dropFirst().first.map(String.init) ?? "/"
                    let (status, body): (Int, String)
                    switch path {
                    case "/ok":
                        (status, body) = (200, "<html><body><p id=\"t\">ok</p><iframe src=\"/missing\"></iframe></body></html>")
                    case "/boom":
                        (status, body) = (500, "<html><body><p id=\"t\">boom</p></body></html>")
                    default:
                        (status, body) = (404, "<html><body><p id=\"t\">not found</p></body></html>")
                    }
                    let head = "HTTP/1.1 \(status) X\r\nContent-Type: text/html\r\n"
                        + "Content-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n"
                    connection.send(content: Data((head + body).utf8), completion: .contentProcessed { _ in
                        connection.cancel()
                    })
                }
            }
            listener.start(queue: queue)
            guard ready.wait(timeout: .now() + 10) == .success, let port = listener.port?.rawValue else {
                listener.cancel()
                throw NSError(domain: "LoopbackServer", code: 1)
            }
            self.port = port
        }

        func url(_ path: String) -> URL { URL(string: "http://127.0.0.1:\(port)\(path)")! }

        deinit { listener.cancel() }
    }

    /// The library's Coordinator, recording every provisional failure WebKit
    /// hands it before deciding — so an arm about cancellation can first show
    /// that a cancellation actually happened.
    private final class RecordingCoordinator: WebView.Coordinator {
        var provisionalErrors: [NSError] = []
        override func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            provisionalErrors.append(error as NSError)
            super.webView(webView, didFailProvisionalNavigation: navigation, withError: error)
        }
    }

    /// A real WKWebView whose delegate is the library's Coordinator; counts
    /// onLoadFailed.
    private final class Harness {
        var failures = 0
        let coordinator: RecordingCoordinator
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        init() {
            var box: Harness?
            coordinator = RecordingCoordinator(WebView(url: nil, onLoadFailed: { box?.failures += 1 }))
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
        // Anything WebKit would still deliver for this load (an iframe's
        // response, a late failure) has had a moment to arrive.
        RunLoop.main.run(until: Date().addingTimeInterval(extra))
    }

    /// The text the page actually shows. A page blocked before any response
    /// (ATS, a refused connection) never shows the server's body, so this is
    /// what tells "reported because of the status" from "reported because
    /// the request never got an answer".
    private func pageText(_ webView: WKWebView) -> String? {
        var text: String?
        let done = expectation(description: "js")
        webView.evaluateJavaScript("document.getElementById('t') ? document.getElementById('t').textContent : null") { value, _ in
            text = value as? String
            done.fulfill()
        }
        wait(for: [done], timeout: 10)
        return text
    }

    func testAnUnresolvableMainFrameHostReportsOnce() {
        let harness = Harness()
        harness.webView.load(URLRequest(url: URL(string: "https://conformance.invalid/")!))
        let reported = expectation(for: NSPredicate { _, _ in harness.failures > 0 }, evaluatedWith: nil)
        wait(for: [reported], timeout: 30)
        waitUntilSettled(harness.webView)
        XCTAssertEqual(harness.failures, 1)
    }

    func testAMainFrame404ReportsOnceAndStillShowsThePage() throws {
        let server = try LoopbackServer()
        let harness = Harness()
        harness.webView.load(URLRequest(url: server.url("/missing")))
        waitUntilSettled(harness.webView)
        XCTAssertEqual(pageText(harness.webView), "not found")
        XCTAssertEqual(harness.failures, 1)
    }

    func testAMainFrame500ReportsOnce() throws {
        let server = try LoopbackServer()
        let harness = Harness()
        harness.webView.load(URLRequest(url: server.url("/boom")))
        waitUntilSettled(harness.webView)
        XCTAssertEqual(pageText(harness.webView), "boom")
        XCTAssertEqual(harness.failures, 1)
    }

    /// The negative the arms above need: the same server, harness and wait,
    /// and a page that loads — with a 404 in a subframe.
    func testAPageThatLoadsWithA404IframeReportsNothing() throws {
        let server = try LoopbackServer()
        let harness = Harness()
        harness.webView.load(URLRequest(url: server.url("/ok")))
        waitUntilSettled(harness.webView, extra: 2.0)
        XCTAssertEqual(pageText(harness.webView), "ok")
        XCTAssertEqual(harness.failures, 0)
    }

    func testALoadReplacedMidFlightReportsNothing() throws {
        let server = try LoopbackServer()
        let harness = Harness()
        // TEST-NET-1 (RFC 5737): never answers, so it is still in flight when
        // the second load replaces it. The replacement waits until the first
        // load is under way: issued back to back, WebKit drops the first
        // before it starts and reports nothing at all, and the arm would pass
        // without ever meeting a cancellation (measured: the filter could be
        // removed and it stayed green).
        harness.webView.load(URLRequest(url: URL(string: "https://192.0.2.1/")!))
        RunLoop.main.run(until: Date().addingTimeInterval(1.0))
        XCTAssertTrue(harness.webView.isLoading, "the first load must still be in flight")
        harness.webView.load(URLRequest(url: server.url("/ok")))
        waitUntilSettled(harness.webView, extra: 2.0)
        XCTAssertEqual(pageText(harness.webView), "ok")
        // The arm's own precondition: WebKit did hand over a cancellation.
        XCTAssertTrue(
            harness.coordinator.provisionalErrors.contains {
                $0.domain == NSURLErrorDomain && $0.code == NSURLErrorCancelled
            },
            "no NSURLErrorCancelled reached the delegate: \(harness.coordinator.provisionalErrors)"
        )
        XCTAssertEqual(harness.failures, 0)
    }
}
