//
//  OffsetHitTargetProbeUITests.swift
//  ConformanceHostUITests
//
//  Does a `.offset` control accept a tap where it is DRAWN? 51-E asked,
//  having stated the point was unmeasured. Opt-in like the other probes: set
//  TEST_RUNNER_OFFSET_PROBE=1.
//
//  The method matters. Tapping the ELEMENT would prove nothing — XCUITest
//  taps an element at its own reported centre, so it would succeed wherever
//  the target is. The probe therefore taps COORDINATES: the drawn position
//  and the pre-offset position, separately, and asks the app which button it
//  heard from.
//

import XCTest

final class OffsetHitTargetProbeUITests: XCTestCase {

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-offsetProbe"]
        app.launch()
        XCTAssertTrue(app.otherElements["offset_probe_root"].waitForExistence(timeout: 10)
                      || app.staticTexts["offset_probe_result"].waitForExistence(timeout: 10))
        return app
    }

    private func result(_ app: XCUIApplication) -> String {
        app.staticTexts["offset_probe_result"].label
    }

    /// Reset first, so a tap that lands on nothing reports "none" instead of
    /// the previous hit.
    private func tapFresh(_ app: XCUIApplication, x: CGFloat, y: CGFloat) -> String {
        app.buttons["offset_probe_reset"].tap()
        XCTAssertEqual(result(app), "tapped: none", "reset did not take")
        tap(app, x: x, y: y)
        return result(app)
    }

    private func tap(_ app: XCUIApplication, x: CGFloat, y: CGFloat) {
        app.windows.firstMatch
            .coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: x, dy: y))
            .tap()
    }

    func testOffsetHitTarget() throws {
        guard ProcessInfo.processInfo.environment["OFFSET_PROBE"] == "1" else {
            throw XCTSkip("offset probe: run with the guard lifted, as the other probes are")
        }
        let app = launch()

        // 1. Report the frames XCUITest sees. If the accessibility frame
        //    tracks the drawing, `inside` sits 120pt right of `control`.
        for id in ["control", "inside", "outside"] {
            let f = app.buttons["\(id)_button"].frame
            print("OFFSET_PROBE_FRAME \(id): \(f)")
        }
        let controlFrame = app.buttons["control_button"].frame
        let insideFrame = app.buttons["inside_button"].frame
        print("OFFSET_PROBE_DELTA inside-control dx=\(insideFrame.minX - controlFrame.minX)")

        // 2. Tap where `inside` is DRAWN.
        let drawn = CGPoint(x: insideFrame.midX, y: insideFrame.midY)
        let atDrawn = tapFresh(app, x: drawn.x, y: drawn.y)
        print("OFFSET_PROBE_TAP at-drawn(\(drawn)) -> \(atDrawn)")

        // 3. Tap where `inside` would be WITHOUT the offset — same row, but
        //    at the control's x. If the target stayed behind, this is what
        //    reaches the button.
        let preOffset = CGPoint(x: controlFrame.midX, y: insideFrame.midY)
        let atPreOffset = tapFresh(app, x: preOffset.x, y: preOffset.y)
        print("OFFSET_PROBE_TAP at-pre-offset(\(preOffset)) -> \(atPreOffset)")

        // 4. Same two questions for the case that leaves the parent's bounds,
        //    which is a separate mechanism (parent clipping) and must not be
        //    conflated with the target staying put.
        let outsideFrame = app.buttons["outside_button"].frame
        print("OFFSET_PROBE_FRAME outside-hittable=\(app.buttons["outside_button"].isHittable)")
        let atOutside = tapFresh(app, x: outsideFrame.midX, y: outsideFrame.midY)
        print("OFFSET_PROBE_TAP outside-at-drawn -> \(atOutside)")

        // The probe RECORDS; it asserts only that the run produced a verdict.
        XCTAssertFalse(atDrawn.isEmpty)
        XCTAssertFalse(atPreOffset.isEmpty)
    }
}
