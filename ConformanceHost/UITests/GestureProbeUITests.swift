//
//  GestureProbeUITests.swift
//  ConformanceHostUITests
//
//  Manual gesture-delegation probe driver (04a-design.md §2) — NOT part of
//  the conformance suite: it only runs when the GESTURE_PROBE=1 test
//  environment is set (pass TEST_RUNNER_GESTURE_PROBE=1 to xcodebuild),
//  so scheduled conformance runs skip it (edge-swipe synthesis is too
//  timing-sensitive for CI).
//
//  The tests assert only the cross-platform INVARIANTS (the embed never
//  closes itself; a swipe pops exactly one level of SOME stack) and log
//  which stack the OS routed the gesture to — the routing itself is
//  platform-delegated, recorded, not promised.
//

import XCTest

final class GestureProbeUITests: XCTestCase {

    private func edgeSwipe(_ app: XCUIApplication) {
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        sleep(2)
    }

    func testEdgeSwipeDelegation() throws {
        guard ProcessInfo.processInfo.environment["GESTURE_PROBE"] == "1" else {
            throw XCTSkip("gesture probe: set TEST_RUNNER_GESTURE_PROBE=1 to run")
        }

        let app = XCUIApplication()
        app.launchArguments = ["-gestureProbe"]
        app.launch()

        // Navigate: probe-root -> detail (parent stack depth 1)
        XCTAssertTrue(app.buttons["go-detail"].waitForExistence(timeout: 10))
        app.buttons["go-detail"].tap()
        XCTAssertTrue(app.staticTexts["detail-marker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["embed-root-probe"].waitForExistence(timeout: 5))

        // Drive the embed to depth 1 through the registry-backed button.
        app.buttons["push-embed"].tap()
        XCTAssertTrue(app.staticTexts["embed-pushed"].waitForExistence(timeout: 5))

        // ── Item 1: edge swipe at embed depth > 0 ──
        edgeSwipe(app)
        let embedPopped = app.staticTexts["embed-root-probe"].waitForExistence(timeout: 3)
        let parentPopped = app.staticTexts["probe-root"].exists && !app.staticTexts["detail-marker"].exists
        print("GESTURE_PROBE_RESULT depth1: embedPopped=\(embedPopped) parentPopped=\(parentPopped)")
        // Invariant: exactly one stack moved, and the embed never closed
        // itself (either its root is back, or the whole detail screen left
        // with the parent pop — never a dangling/blank embed).
        XCTAssertTrue(embedPopped || parentPopped)

        // Re-establish: detail on screen, embed at depth 0.
        if parentPopped {
            app.buttons["go-detail"].tap()
            XCTAssertTrue(app.staticTexts["detail-marker"].waitForExistence(timeout: 5))
        }
        XCTAssertTrue(app.staticTexts["embed-root-probe"].waitForExistence(timeout: 5))

        // ── Item 2: edge swipe at embed depth == 0 ──
        edgeSwipe(app)
        let atRoot = app.staticTexts["probe-root"].waitForExistence(timeout: 3)
        print("GESTURE_PROBE_RESULT depth0: parentPopped=\(atRoot)")
        // Invariant: with the embed stack empty the swipe must fall through
        // to the parent stack (the embed cannot consume it — it has nothing
        // to pop and never closes itself).
        XCTAssertTrue(atRoot)
    }
}
