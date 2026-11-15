//
//  NetworkImageRetryTests.swift
//  SwiftJsonUITests
//
//  A tap on NetworkImage's failed image (NetworkImageLoader.retry) loads the
//  URL again at once: it lifts the URL's failed mark, which otherwise holds
//  every load of it off for 30 seconds. Until SwiftJsonUI 10.41.0 the tap
//  kept the mark and went straight back to failed without a request (ticket
//  sjui-networkimage-retry-tap-blocked-by-failed-mark). A URL nobody tapped
//  keeps its mark.
//

import XCTest
import UIKit
@testable import SwiftJsonUI

private final class RetryCountingProtocol: URLProtocol {
    static let host = "nwretry.test"
    private static let lock = NSLock()
    private static var _requests: [String] = []
    static var requests: [String] {
        lock.lock(); defer { lock.unlock() }
        return _requests
    }
    static var onRequest: ((String) -> Void)?

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!.absoluteString
        Self.lock.lock(); Self._requests.append(url); Self.lock.unlock()
        let png = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).pngData { ctx in
            UIColor.red.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "image/png"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: png)
        client?.urlProtocolDidFinishLoading(self)
        Self.onRequest?(url)
    }

    override func stopLoading() {}
}

@MainActor
final class NetworkImageRetryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(RetryCountingProtocol.self)
    }

    override func tearDown() {
        RetryCountingProtocol.onRequest = nil
        URLProtocol.unregisterClass(RetryCountingProtocol.self)
        super.tearDown()
    }

    func testATapOnTheFailedImageLoadsTheURLAgainAtOnce() {
        let tapped = "https://\(RetryCountingProtocol.host)/tapped-\(UUID().uuidString).png"
        let untouched = "https://\(RetryCountingProtocol.host)/untouched-\(UUID().uuidString).png"
        // Both failed a moment ago: inside the 30s cooldown.
        SwiftUIImageCache.shared.markFailed(tapped)
        SwiftUIImageCache.shared.markFailed(untouched)

        // Without a tap, a load of a recently failed URL goes to failed
        // without a request.
        let idle = NetworkImageLoader()
        idle.loadIfNeeded(url: untouched, headers: [:])
        XCTAssertTrue(idle.hasFailed)
        XCTAssertFalse(idle.isLoading)

        let requested = expectation(description: "the tap sends a request for the tapped URL")
        RetryCountingProtocol.onRequest = { url in if url == tapped { requested.fulfill() } }
        let loader = NetworkImageLoader()
        loader.loadIfNeeded(url: tapped, headers: [:])
        XCTAssertTrue(loader.hasFailed, "the first load is held off by the failed mark")
        loader.retry(url: tapped, headers: [:])
        XCTAssertFalse(loader.hasFailed, "the tap leaves failed")
        XCTAssertTrue(loader.isLoading, "the tap starts a load")
        wait(for: [requested], timeout: 5)
        XCTAssertEqual(RetryCountingProtocol.requests.filter { $0 == tapped }.count, 1)

        // The URL nobody tapped keeps its mark and sent nothing.
        XCTAssertTrue(SwiftUIImageCache.shared.isRecentlyFailed(untouched))
        XCTAssertEqual(RetryCountingProtocol.requests.filter { $0 == untouched }.count, 0)
    }

    func testClearFailedLiftsOnlyThatURLsMark() {
        let a = "https://\(RetryCountingProtocol.host)/a-\(UUID().uuidString).png"
        let b = "https://\(RetryCountingProtocol.host)/b-\(UUID().uuidString).png"
        SwiftUIImageCache.shared.markFailed(a)
        SwiftUIImageCache.shared.markFailed(b)
        SwiftUIImageCache.shared.clearFailed(a)
        XCTAssertFalse(SwiftUIImageCache.shared.isRecentlyFailed(a))
        XCTAssertTrue(SwiftUIImageCache.shared.isRecentlyFailed(b))
    }
}
