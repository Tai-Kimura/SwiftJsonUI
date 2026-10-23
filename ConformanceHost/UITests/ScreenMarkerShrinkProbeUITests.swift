import XCTest

/// Screen markers that leave while the driver reads them
/// (ScreenMarkerShrinkProbeView; jsonui-cli ticket
/// 2026-10-23-test-ios-hittable-screens-index-race-on-shrinking-marker-query).
///
/// An XCUIElement read (identifier, frame, label, …) of an element the query
/// no longer matches is not answered: XCUITest retries for about two seconds,
/// then records "Failed to get matching snapshot" as a test failure and stops
/// the test, whatever continueAfterFailure says. The driver read the markers
/// as `0..<query.count` and an attribute per index, so a marker that left
/// after the count failed the step that asked, on a tablet three runs in three.
///
/// Two readings the fix stands on, then the driver's own functions over a
/// hierarchy that shrinks while they read it. A recorded failure is the red:
/// each test passes only when nothing was recorded.
///
/// Only API every vendored driver has is called here, so the target builds
/// on any driver and an old one fails these tests rather than the build: the
/// helper 2.1.2 added (snapshotsBoundByIndex) is reached through
/// presentMarkers, never called by name. A test that called it took the
/// whole UITests target down on a 2.1.1 driver.
///
/// Opt-in, like the other probes: TEST_RUNNER_SCREEN_MARKER_SHRINK_PROBE=1.
final class ScreenMarkerShrinkProbeUITests: XCTestCase {

    private let markerPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "__screen_")

    override func setUpWithError() throws {
        guard ProcessInfo.processInfo.environment["SCREEN_MARKER_SHRINK_PROBE"] == "1" else {
            throw XCTSkip("set TEST_RUNNER_SCREEN_MARKER_SHRINK_PROBE=1 to run the screen marker shrink probe")
        }
        continueAfterFailure = true
    }

    private func launch(intervalMs: Int = 100, leavingRenamed: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-screenMarkerShrinkProbe", "-shrinkIntervalMs", "\(intervalMs)"]
            + (leavingRenamed ? ["-leavingRenamed"] : [])
        app.launch()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "__screen_shrink_target").firstMatch
                .waitForExistence(timeout: 15),
            "the probe did not come up"
        )
        return app
    }

    private func markers(_ app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(markerPredicate)
    }

    /// Waits until no leaving marker is left, so a test ends on the shrink's end.
    private func waitUntilAllLeft(_ app: XCUIApplication) {
        let gone = NSPredicate(format: "label == %@", "left 0")
        let left = app.staticTexts["shrink_left"]
        expectation(for: gone, evaluatedWith: left)
        waitForExpectations(timeout: 15)
    }

    // MARK: - The readings

    /// An index past the end, after the markers left: `snapshot()` throws, and
    /// nothing is recorded (the test would fail and stop otherwise).
    func testSnapshotOfAnIndexPastTheEndThrows() throws {
        let app = launch()
        let query = markers(app)
        let before = query.count
        XCTAssertEqual(before, probeLeavingCount + 1, "the target and every leaving marker")
        let last = query.element(boundBy: before - 1)
        app.buttons["shrink_remove_all"].tap()
        waitUntilAllLeft(app)
        XCTAssertEqual(query.count, 1, "only the target is left")

        let started = Date()
        XCTAssertThrowsError(try last.snapshot(), "an element the query no longer has has no snapshot")
        print("  snapshot of index \(before - 1) of 1: threw after \(String(format: "%.2f", Date().timeIntervalSince(started)))s")
    }

    /// `isHittable` of a marker that left, asked by its identifier and by an
    /// index past the end: false both ways, and nothing is recorded.
    func testIsHittableOfAMarkerThatLeftIsFalse() throws {
        let app = launch()
        let byId = app.descendants(matching: .any).matching(identifier: "__screen_leaving_0").firstMatch
        XCTAssertTrue(byId.isHittable, "precondition: hittable while it is there")
        let query = markers(app)
        let last = query.element(boundBy: query.count - 1)
        app.buttons["shrink_remove_all"].tap()
        waitUntilAllLeft(app)

        let started = Date()
        XCTAssertFalse(byId.isHittable, "by identifier")
        XCTAssertFalse(last.isHittable, "by an index past the end")
        print("  isHittable of two markers that left: false, false after \(String(format: "%.2f", Date().timeIntervalSince(started)))s")
    }

    // MARK: - The driver over a shrinking hierarchy

    // In the two tests that ask `isHittable` of the leaving screens, their
    // markers leave by losing their identifier (`-leavingRenamed`). Removed
    // with their views, a marker caught in the moment of its removal can make
    // `isHittable` record "Activation point invalid and no suggested hit
    // points based on element frame" — the shape of 2026-09-08, a question
    // this fix does not remove: hittableScreens failed on it 2 runs of 5 and
    // assert screen 1 of 5 with the markers removed on screen, and 1 of 5
    // each with them removed outside the window (Xcode 27.2, iOS 26.3). So
    // what these two tests can fail on is the read by index alone.

    /// The ticket's call: the markers other than the target, read while one
    /// leaves every 100 ms. 2.1.1 failed here at the first index past the
    /// shrunk end.
    func testHittableScreensWhileMarkersLeave() throws {
        let app = launch(leavingRenamed: true)
        app.buttons["shrink_start"].tap()
        var rounds = 0
        repeat {
            let covering = ScreenMarker.hittableScreens(in: app, excluding: "shrink_target")
            XCTAssertFalse(covering.contains("shrink_target"), "the excluded screen is never listed")
            rounds += 1
        } while app.staticTexts["shrink_left"].label != "left 0"
        print("  hittableScreens rounds while the markers left: \(rounds)")
        XCTAssertEqual(ScreenMarker.hittableScreens(in: app, excluding: "shrink_target"), [], "none left")
    }

    /// The failure message's reading over the same shrink. The screen asked
    /// for is not there, so this is presentMarkers alone.
    func testDiagnosisWhileMarkersLeave() throws {
        let app = launch()
        app.buttons["shrink_start"].tap()
        var last = ""
        repeat {
            last = ScreenMarker.diagnosis(screenId: "shrink_gone", in: app)
        } while app.staticTexts["shrink_left"].label != "left 0"
        print("  last diagnosis: \(last)")
        XCTAssertTrue(
            ScreenMarker.diagnosis(screenId: "shrink_gone", in: app).hasPrefix("previous-screen-only:"),
            "with only the target left, a screen that is not there reads as previous-screen-only"
        )
    }

    /// `assert: screen` itself, as a flow step runs it, on the screen that
    /// stays while the others leave.
    func testAssertScreenWhileMarkersLeave() throws {
        let app = launch(leavingRenamed: true)
        let executor = XCUITestAssertionExecutor(screenTransitionTimeout: 10)
        app.buttons["shrink_start"].tap()
        var rounds = 0
        repeat {
            try executor.execute(step: TestStep(assert: "screen", timeout: 10_000, name: "shrink_target"), in: app)
            rounds += 1
        } while app.staticTexts["shrink_left"].label != "left 0"
        print("  assert screen rounds while the markers left: \(rounds)")
    }

    /// `assert: text` of a text that left: the poll waits it out as "does not
    /// exist" and fails as an assertion at its timeout. 2.1.1 read its value
    /// without asking whether it was there, and that read was recorded as a
    /// test failure instead.
    func testAssertTextOfATextThatLeft() throws {
        let app = launch()
        let executor = XCUITestAssertionExecutor()
        try executor.execute(
            step: TestStep(assert: "text", id: "leaving_text_0", timeout: 2000, equals: AnyCodable("leaving 0")),
            in: app)
        app.buttons["shrink_remove_all"].tap()
        waitUntilAllLeft(app)
        XCTAssertThrowsError(try executor.execute(
            step: TestStep(assert: "text", id: "leaving_text_0", timeout: 1000, equals: AnyCodable("leaving 0")),
            in: app)) { error in
            XCTAssertTrue("\(error)".contains("does not exist"), "\(error)")
        }
    }
}

/// The probe view's count, spelled here: the view lives in the app target.
private let probeLeavingCount = 12
