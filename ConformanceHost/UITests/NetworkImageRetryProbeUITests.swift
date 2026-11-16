//
//  NetworkImageRetryProbeUITests.swift
//  ConformanceHostUITests
//
//  A tap on NetworkImage's failed image loads the URL again at once
//  (NetworkImageRetryProbeView). OPT-IN: it needs a local HTTP server that
//  fails a path's first three requests and serves a PNG after, named by
//  CONFORMANCE_NW_RETRY_URL (a fresh path each run); skipped without it.
//  The failed image shows after the load and its 2s + 4s retries, inside
//  the 30s failed mark; until SwiftJsonUI 10.41.0 the tap kept the mark and
//  went straight back to failed (ticket
//  sjui-networkimage-retry-tap-blocked-by-failed-mark).
//

import XCTest

final class NetworkImageRetryProbeUITests: XCTestCase {
    func testATapOnTheFailedImageLoadsItAgainAtOnce() throws {
        guard let url = ProcessInfo.processInfo.environment["CONFORMANCE_NW_RETRY_URL"], !url.isEmpty else {
            throw XCTSkip("CONFORMANCE_NW_RETRY_URL is not set (opt-in: needs a local server)")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-networkImageRetryProbe", url]
        app.launch()
        XCTAssertTrue(app.staticTexts["nw_retry_ready"].waitForExistence(timeout: 15), "probe did not start")

        let failed = app.buttons["nw_retry_image"]
        XCTAssertTrue(failed.waitForExistence(timeout: 20), "the failed image (a button) did not show")
        let tappedAt = Date()
        failed.tap()
        // Loaded, the image is no longer a button. Well inside the 30s mark.
        let gone = NSPredicate(format: "exists == false")
        let wait = expectation(for: gone, evaluatedWith: app.buttons["nw_retry_image"])
        XCTAssertEqual(XCTWaiter().wait(for: [wait], timeout: 5), .completed, "the tap did not load the image again")
        print("NWR loaded \(String(format: "%.1f", Date().timeIntervalSince(tappedAt)))s after the tap")
        XCTAssertTrue(app.images["nw_retry_image"].exists || app.otherElements["nw_retry_image"].exists, "the loaded image is not drawn")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "network_image_retry"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
