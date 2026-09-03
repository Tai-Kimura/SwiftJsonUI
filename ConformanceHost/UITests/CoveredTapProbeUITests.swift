//
//  CoveredTapProbeUITests.swift
//  ConformanceHostUITests
//
//  Opt-in: TEST_RUNNER_COVERED_TAP_PROBE=1 in the xcodebuild process
//  environment, with the `test` action.
//
//  Does a tap aimed at a covered element land on the cover? The driver routes
//  a non-hittable element whose centre is on screen to `.frameCenter`, which
//  taps the coordinate — so it lands on whatever is drawn there.
//
//  ⚠️ The two self-checks come FIRST and they are the point. `.frameCenter`
//  is reached only when the element is not hittable AND its centre is inside
//  the window; if either fails, the driver takes `.element` or `.offscreen`
//  instead and this arm never touches the branch. A pass would then mean
//  "the arm missed", not "the tap was safe" — which is exactly how the
//  previously-built probes would have produced a vacuous green here.
//

import XCTest

final class CoveredTapProbeUITests: XCTestCase {

    private func result(_ app: XCUIApplication) -> String {
        app.staticTexts["covered_probe_result"].label
    }

    func testTapOnACoveredElementReachesTheElementNotTheCover() throws {
        guard ProcessInfo.processInfo.environment["COVERED_TAP_PROBE"] == "1" else {
            throw XCTSkip("covered tap probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-coveredTapProbe"]
        app.launch()
        XCTAssertTrue(
            app.staticTexts["covered_probe_result"].waitForExistence(timeout: 10),
            "probe did not start")

        let target = app.buttons["covered_target"]
        let cover = app.buttons["covering_bar"]
        XCTAssertTrue(target.exists, "FIXTURE: the target is not in the tree at all")
        XCTAssertTrue(cover.exists, "FIXTURE: the cover is not in the tree at all")

        let frame = target.frame
        let window = app.frame
        let centre = CGPoint(x: frame.midX, y: frame.midY)
        print("CTAP_PROBE_WINDOW \(window)")
        print("CTAP_PROBE_TARGET frame=\(frame) hittable=\(target.isHittable)")
        print("CTAP_PROBE_COVER  frame=\(cover.frame) hittable=\(cover.isHittable)")
        print("CTAP_PROBE_CENTRE \(centre) insideWindow=\(window.contains(centre))")

        // ---- self-checks: does this arm reach `.frameCenter` at all? ----
        XCTAssertFalse(
            target.isHittable,
            "FIXTURE: the target reports hittable, so the driver routes to `.element` and taps the "
            + "element directly — this arm never reaches the `.frameCenter` branch and a pass "
            + "would say nothing about covered taps")
        XCTAssertTrue(
            window.contains(centre),
            "FIXTURE: the target's centre \(centre) is outside the window \(window), so the driver "
            + "routes to `.offscreen` — again not the branch under test")

        // ---- the measurement ----
        app.buttons["covered_probe_reset"].tap()
        XCTAssertEqual(result(app), "tapped: none", "reset did not take")

        let executor = XCUITestActionExecutor(platform: "ios")
        try executor.execute(step: TestStep(action: "tap", id: "covered_target"), in: app)

        let fired = result(app)
        print("CTAP_PROBE_RESULT \(fired)")

        XCTAssertEqual(
            fired, "tapped: target",
            "TAP ROUTING: the tap aimed at 'covered_target' was received by \(fired). "
            + "`.frameCenter` taps the coordinate, so a covered element hands its tap to whatever "
            + "is drawn on top — 'tapped: cover' is that defect reaching the surface, and it is the "
            + "same shape as the 1.9.4 fixed-bar case recorded in TapRouting's docstring")
    }
}
