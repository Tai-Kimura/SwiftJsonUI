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

    /// What the driver writes to stderr while `body` runs. The driver's
    /// notices (`ActionExecutor.note`) go to this process's standard error
    /// and nowhere else, so the probe reads them by pointing fd 2 at a pipe
    /// for the duration of one step.
    private func capturingStandardError(_ body: () throws -> Void) rethrows -> String {
        let pipe = Pipe()
        let saved = dup(STDERR_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        defer {
            dup2(saved, STDERR_FILENO)
            close(saved)
        }
        try body()
        fflush(stderr)
        dup2(saved, STDERR_FILENO)
        pipe.fileHandleForWriting.closeFile()
        let text = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        FileHandle.standardError.write(Data(text.utf8))  // still visible in the log
        return text
    }

    private func result(_ app: XCUIApplication) -> String {
        app.staticTexts["covered_probe_result"].label
    }

    /// The ruling (jsonui-cli v1.8.24 report §6, driver 1.9.12): a covered
    /// element's tap goes by coordinate and is NOT refused — that branch is
    /// right for remote-process UI (a photo picker, an iPad keyboard key),
    /// and XCUITest publishes no z-order to tell the two apart. What the
    /// driver owes is to say so: the switch to the frame centre, and the
    /// other elements at that point. This probe pins that behaviour: the cover
    /// receives the tap AND both notices are written. Until 2026-10-13 it
    /// asserted the opposite ("the target receives it"), which the ruling
    /// decided against, and it never ran in CI (ticket
    /// conformance-mobile-ios-probe-guards-never-run-in-dispatch).
    func testACoveredTapGoesToTheCoverAndTheDriverSaysSo() throws {
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
        let notices = try capturingStandardError {
            try executor.execute(step: TestStep(action: "tap", id: "covered_target"), in: app)
        }

        let fired = result(app)
        print("CTAP_PROBE_RESULT \(fired)")

        // Not refused: the coordinate tap goes ahead, and lands on the cover.
        XCTAssertEqual(
            fired, "tapped: cover",
            "TAP ROUTING: the tap aimed at 'covered_target' was received by \(fired). By the ruling "
            + "the driver taps the frame centre and does not refuse, so the cover drawn there "
            + "receives it; anything else means the route or the fixture changed")

        // Said so. The fragments are the driver's own text
        // (jsonui-test-runner-ios ActionExecutor.tapResolvingHittability).
        XCTAssertTrue(
            notices.contains("tap 'covered_target': exists but isHittable == false")
                && notices.contains("tapping the frame center instead of the element"),
            "the driver did not announce the switch to the frame centre; stderr was: \(notices)")
        XCTAssertTrue(
            notices.contains("tap 'covered_target': ⚠️")
                && notices.contains("other element(s) have that coordinate inside their frame"),
            "the driver did not name the other elements at the tapped point; stderr was: \(notices)")
    }
}
