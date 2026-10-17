//
//  WebViewContentProcessTerminationTests.swift
//  SwiftJsonUITests
//
//  When WebKit ends a web view's WebContent process, the view stays blank
//  until something loads again. WebView.Coordinator loads the view's own
//  source again (conformance-mobile run 38958247680: Web/html__static was
//  captured blank by the Dynamic host).
//
//  No arm here loads anything through WebKit. A spy subclass records which
//  load the delegate method asks for. The arm that ends a real process lives
//  outside the suite: it needs a process killed from the host machine. The
//  WebView.swift comment records what that arm measured.
//

import XCTest
import WebKit
@testable import SwiftJsonUI

final class WebViewContentProcessTerminationTests: XCTestCase {

    private let page = URL(string: "https://a.test/page")!
    private let other = URL(string: "https://b.test/elsewhere")!
    private let blank = URL(string: "about:blank")!

    private func action(committed: URL?, url: URL? = nil, html: String? = nil) -> WebView.Coordinator.RecoveryAction {
        WebView.Coordinator.recoveryAction(committedURL: committed, lastLoadedURL: url, lastLoadedHTML: html)
    }

    // MARK: - What the recovery loads

    func testAnHtmlSourceIsLoadedAgainOverTheAboutBlankItCommitted() {
        XCTAssertEqual(action(committed: blank, html: "<p>x</p>"), .loadHTML("<p>x</p>"))
    }

    func testAnHtmlSourceWithNothingCommittedIsLoadedAgain() {
        XCTAssertEqual(action(committed: nil, html: "<p>x</p>"), .loadHTML("<p>x</p>"))
    }

    func testAUrlSourceWithNothingCommittedIsLoadedAgain() {
        XCTAssertEqual(action(committed: nil, url: page), .loadURL(page))
    }

    /// The user followed a link: the page on screen is reloaded, not the
    /// source the view was created with.
    func testACommittedPageWithARealAddressIsReloaded() {
        XCTAssertEqual(action(committed: other, url: page), .reload)
        XCTAssertEqual(action(committed: page, url: page), .reload)
    }

    /// The url wins over the html, as in loadAction (and on the web platform).
    func testAUrlWinsOverHtmlWhenBothWereGiven() {
        XCTAssertEqual(action(committed: nil, url: page, html: "<p>x</p>"), .loadURL(page))
    }

    func testAViewThatNeverLoadedLoadsNothing() {
        XCTAssertEqual(action(committed: nil), .none)
        XCTAssertEqual(action(committed: blank), .none)
    }

    // MARK: - WebKit can find the method

    /// WebKit calls an optional delegate method only when it can find the
    /// selector. If the Swift signature is misspelled, it still compiles,
    /// WebKit never calls it, and the view stays blank. So the arm checks the
    /// selector, not the Swift name.
    func testTheCoordinatorAnswersTheDelegateSelector() {
        let coordinator = WebView.Coordinator(WebView(url: nil, html: "<p>x</p>"))
        XCTAssertTrue(coordinator.responds(to: #selector(WKNavigationDelegate.webViewWebContentProcessDidTerminate(_:))))
    }

    // MARK: - The delegate method asks the web view for that load

    private final class SpyWebView: WKWebView {
        var committed: URL?
        var calls: [String] = []
        override var url: URL? { committed }
        override func reload() -> WKNavigation? { calls.append("reload"); return nil }
        override func load(_ request: URLRequest) -> WKNavigation? {
            calls.append("load \(request.url?.absoluteString ?? "nil")"); return nil
        }
        override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
            calls.append("loadHTML \(string)"); return nil
        }
    }

    private func spy(committed: URL?) -> SpyWebView {
        let view = SpyWebView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        view.committed = committed
        return view
    }

    func testTerminationLoadsTheHtmlAgain() {
        let coordinator = WebView.Coordinator(WebView(url: nil, html: "<p>x</p>"))
        coordinator.lastLoadedHTML = "<p>x</p>"
        let view = spy(committed: blank)
        coordinator.webViewWebContentProcessDidTerminate(view)
        XCTAssertEqual(view.calls, ["loadHTML <p>x</p>"])
    }

    func testTerminationReloadsTheCommittedPage() {
        let coordinator = WebView.Coordinator(WebView(url: page))
        coordinator.lastLoadedURL = page
        let view = spy(committed: other)
        coordinator.webViewWebContentProcessDidTerminate(view)
        XCTAssertEqual(view.calls, ["reload"])
    }

    func testTerminationBeforeAnythingCommittedLoadsTheUrlAgain() {
        let coordinator = WebView.Coordinator(WebView(url: page))
        coordinator.lastLoadedURL = page
        let view = spy(committed: nil)
        coordinator.webViewWebContentProcessDidTerminate(view)
        XCTAssertEqual(view.calls, ["load \(page.absoluteString)"])
    }

    /// One termination is one load: a second load in the same call would
    /// cancel the first.
    func testTerminationAsksForExactlyOneLoad() {
        let coordinator = WebView.Coordinator(WebView(url: page, html: "<p>x</p>"))
        coordinator.lastLoadedURL = page
        coordinator.lastLoadedHTML = "<p>x</p>"
        let view = spy(committed: nil)
        coordinator.webViewWebContentProcessDidTerminate(view)
        XCTAssertEqual(view.calls.count, 1)
    }
}
