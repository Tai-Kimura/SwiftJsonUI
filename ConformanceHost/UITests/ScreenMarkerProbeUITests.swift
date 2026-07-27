//
//  ScreenMarkerProbeUITests.swift
//  ConformanceHostUITests
//
//  Screen-marker measurement (screen-identity track, Phase 0) — NOT part of
//  the conformance suite. Compiled in only when built with
//  OTHER_SWIFT_FLAGS='$(inherited) -DSCREEN_MARKER_PROBE'.
//
//  These tests measure two things the canon cannot assume:
//
//  * whether a marker SHAPE damages the screen it marks (a container
//    marker can absorb a single-child subtree and drop its identifier)
//  * which PREDICATE distinguishes "displayed" from "still in the
//    hierarchy but covered", for push / sheet / fullScreenCover / tab /
//    split pane
//
//  Only the clobber checks assert. The predicate work RECORDS
//  exists / isHittable / frame for both the covered and the covering
//  screen and prints a table: the canonical predicate is then chosen from
//  measurement rather than from a guess about SwiftUI's internals.
//

import XCTest

final class ScreenMarkerProbeUITests: XCTestCase {

    private func marker(_ app: XCUIApplication, _ screenId: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "__screen_\(screenId)").firstMatch
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func count(_ app: XCUIApplication, _ identifier: String) -> Int {
        app.descendants(matching: .any).matching(identifier: identifier).count
    }

    /// exists / isHittable / frame for one element, as one printable row.
    private func snapshot(_ app: XCUIApplication, _ label: String, _ identifier: String) -> String {
        let element = self.element(app, identifier)
        let exists = element.exists
        guard exists else { return "\(label): exists=false" }
        let frame = element.frame
        let inWindow = app.windows.firstMatch.frame.intersects(frame)
        return String(
            format: "%@: exists=true hittable=%@ frame=(%.1f,%.1f,%.1fx%.1f) empty=%@ inWindow=%@",
            label,
            element.isHittable ? "true" : "false",
            frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
            frame.isEmpty ? "true" : "false",
            inWindow ? "true" : "false"
        )
    }

    private func launchProbe(_ argument: String = "-screenMarkerProbe") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        app.launch()
        return app
    }

    /// Compile-time gate, deliberately not an environment variable:
    /// `TEST_RUNNER_*` forwarding was measured NOT to reach the runner
    /// process with this toolchain (only SIMULATOR_* arrives), so an env
    /// gate would silently skip forever. A command-line build setting always
    /// reaches the compiler, so this one cannot rot unnoticed — and with the
    /// flag absent the probe compiles out of the nightly full-scheme run.
    private func skipUnlessEnabled() throws {
        #if !SCREEN_MARKER_PROBE
        throw XCTSkip("screen marker probe: build with OTHER_SWIFT_FLAGS='$(inherited) -DSCREEN_MARKER_PROBE' to run")
        #endif
    }

    // MARK: - Shape: does the marker damage the screen it marks?

    func testLeafMarkerKeepsRootAndChildIdentifiers() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(marker(app, "leafhost").waitForExistence(timeout: 15), "leaf marker missing")

        // The whole point of the leaf shape: nothing about the marked
        // subtree changes.
        XCTAssertTrue(element(app, "leafhost_root_view").exists, "leaf marker clobbered the root id")
        XCTAssertTrue(element(app, "leafhost_child_0").exists, "leaf marker clobbered a child id")
        XCTAssertTrue(element(app, "leafhost_child_1").exists, "leaf marker clobbered a child id")
    }

    func testContainerMarkerIsMeasuredAgainstTheSameContent(  ) throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(marker(app, "leafhost").waitForExistence(timeout: 15))

        // Recorded, not asserted: this is the shape we expect to damage the
        // subtree, and the measurement is the evidence for rejecting it.
        let rootVisible = element(app, "containerhost_root_view").exists
        let childVisible = element(app, "containerhost_child_0").exists
        print("[screen-marker] container shape: root_id_visible=\(rootVisible) child_id_visible=\(childVisible)")
        print("[screen-marker] leaf shape: root_id_visible=\(element(app, "leafhost_root_view").exists) child_id_visible=\(element(app, "leafhost_child_0").exists)")
    }

    /// The library modifier's runtime spelling: exactly one element whose
    /// identifier is `__screen_<id>` — not a doubled prefix, and not zero.
    func testLibraryModifierSpellsTheIdentifierOnce() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(marker(app, "lib_probe").waitForExistence(timeout: 15),
                      "library modifier produced no marker")

        XCTAssertEqual(count(app, "__screen_lib_probe"), 1)
        XCTAssertEqual(count(app, "__screen___screen_lib_probe"), 0,
                       "prefix applied twice")
        // And it must not have cost the marked screen its own ids.
        XCTAssertTrue(element(app, "libhost_root_view").exists)
        XCTAssertTrue(element(app, "libhost_child_0").exists)
        print("  " + snapshot(app, "library jsonUIScreenMarker", "__screen_lib_probe"))
    }

    /// The marker must satisfy the DRIVER'S predicate, not merely exist.
    ///
    /// This assertion is the one the probe was missing. Every check above
    /// is an existence or count check, so the suite stayed green while the
    /// shipped marker carried `.allowsHitTesting(false)` — which makes
    /// hit-testing resolve past it and `isHittable` structurally false, so
    /// `assert: "screen"` could never pass on a real app. Existence checks
    /// cannot catch a predicate bug; only the predicate can.
    ///
    /// Keep this spelled the same as
    /// `AssertionExecutor.assertScreen` (`exists && isHittable`). If that
    /// predicate changes, change it here in the same commit.
    func testMarkerSatisfiesTheDriverPredicate() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        let element = marker(app, "lib_probe")
        XCTAssertTrue(element.waitForExistence(timeout: 15), "library modifier produced no marker")

        XCTAssertTrue(
            element.exists && element.isHittable,
            "marker fails the driver predicate 'exists && isHittable' — "
                + "assert: \"screen\" cannot pass against this build. "
                + snapshot(app, "marker", "__screen_lib_probe")
        )
    }

    /// The same predicate, on a screen shaped the way code generation really
    /// emits one: a root that FILLS the screen inside a NavigationStack.
    ///
    /// This is the case a real app hits and the probe above does not. The
    /// marker's topLeading overlay lands in the screen's top-left corner,
    /// under the navigation and status bars, rather than in clear space
    /// mid-VStack.
    func testFullScreenRootMarkerSatisfiesTheDriverPredicate() throws {
        try skipUnlessEnabled()
        let app = launchProbe("-screenMarkerFullScreenProbe")
        let element = marker(app, "fullbleed_probe")
        XCTAssertTrue(element.waitForExistence(timeout: 15), "library modifier produced no marker")

        print("  " + snapshot(app, "library marker (centered)", "__screen_fullbleed_probe"))
        print("  " + snapshot(app, "control (topLeading, rejected)", "__probe_v_topleading"))
        XCTAssertTrue(
            element.exists && element.isHittable,
            "marker on a full-screen root fails 'exists && isHittable' — "
                + "assert: \"screen\" cannot pass on a real generated screen. "
                + snapshot(app, "marker", "__screen_fullbleed_probe")
        )
    }

    // MARK: - Predicate: displayed vs. covered by another SCREEN

    /// Screen ids other than `screenId` whose markers are currently hittable.
    private func otherHittableScreens(_ app: XCUIApplication, excluding screenId: String) -> [String] {
        let prefix = "__screen_"
        let query = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
        return (0..<query.count).compactMap { index -> String? in
            let element = query.element(boundBy: index)
            let identifier = element.identifier
            guard identifier.hasPrefix(prefix) else { return nil }
            let id = String(identifier.dropFirst(prefix.count))
            guard id != screenId, element.isHittable else { return nil }
            return id
        }
    }

    /// The CANDIDATE predicate, mirroring what the driver is to implement:
    /// the screen is displayed when its marker is present and either
    /// reachable, or nothing else claims to be the displayed screen.
    ///
    /// Keep this spelled the same as `AssertionExecutor.assertScreen`.
    private func isDisplayed(_ app: XCUIApplication, _ screenId: String) -> Bool {
        let element = marker(app, screenId)
        guard element.exists else { return false }
        if element.isHittable { return true }
        return otherHittableScreens(app, excluding: screenId).isEmpty
    }

    /// A full-screen app overlay layered OUTSIDE the generated view covers the
    /// marker, but the screen is still the one on display.
    ///
    /// `exists && isHittable` cannot tell this apart from a sheet, because
    /// the marker is inside the generated view and the overlay is outside it
    /// — so it necessarily loses. The screen has not been replaced, and
    /// nothing else claims to be displayed.
    func testAppLevelOverlayDoesNotHideTheScreen() throws {
        try skipUnlessEnabled()
        let app = launchProbe("-screenMarkerOverlayProbe")
        let element = marker(app, "overlaid_probe")
        XCTAssertTrue(element.waitForExistence(timeout: 15), "marker missing under the overlay")

        print("  " + snapshot(app, "overlaid marker", "__screen_overlaid_probe"))
        // Recorded, not required: this is the reading that made the old
        // predicate fail in the field.
        print("  overlay covers the marker: isHittable=\(element.isHittable)")

        XCTAssertTrue(
            otherHittableScreens(app, excluding: "overlaid_probe").isEmpty,
            "no other SCREEN is present — only an app overlay"
        )
        XCTAssertTrue(
            isDisplayed(app, "overlaid_probe"),
            "a screen covered by its own app's overlay must still count as displayed. "
                + snapshot(app, "marker", "__screen_overlaid_probe")
        )
    }

    /// The discriminating case the predicate exists for: another SCREEN on
    /// top must still read as not-displayed under the new rule, otherwise
    /// the change trades one false negative for a false positive.
    func testSheetStillHidesThePresenterUnderTheNewPredicate() throws {
        try skipUnlessEnabled()
        let app = launchProbe("-screenMarkerFullScreenProbe")
        XCTAssertTrue(marker(app, "fullbleed_probe").waitForExistence(timeout: 15))
        XCTAssertTrue(isDisplayed(app, "fullbleed_probe"), "precondition: displayed before covering")

        app.buttons["fullbleed_open_sheet"].tap()
        XCTAssertTrue(marker(app, "fullbleed_sheet").waitForExistence(timeout: 15), "sheet did not present")

        print("  covering screens: \(otherHittableScreens(app, excluding: "fullbleed_probe"))")
        XCTAssertFalse(
            isDisplayed(app, "fullbleed_probe"),
            "a sheet is another SCREEN and must still hide the presenter. "
                + snapshot(app, "covered", "__screen_fullbleed_probe")
        )
        XCTAssertTrue(isDisplayed(app, "fullbleed_sheet"), "the sheet itself is displayed")
    }

    /// The other direction: the predicate must still say NO when the screen
    /// is covered. A marker that is always hittable would make every screen
    /// assertion pass, which is a worse failure than the one being fixed.
    func testFullScreenRootMarkerIsNotHittableWhenCovered() throws {
        try skipUnlessEnabled()
        let app = launchProbe("-screenMarkerFullScreenProbe")
        let element = marker(app, "fullbleed_probe")
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        XCTAssertTrue(element.isHittable, "precondition: marker hittable before covering")

        app.buttons["fullbleed_open_sheet"].tap()
        XCTAssertTrue(marker(app, "fullbleed_sheet").waitForExistence(timeout: 15), "sheet did not present")

        print("  " + snapshot(app, "covered(fullbleed_probe)", "__screen_fullbleed_probe"))
        XCTAssertFalse(
            element.isHittable,
            "a covered screen's marker is still hittable — the predicate no "
                + "longer distinguishes displayed from covered. "
                + snapshot(app, "covered", "__screen_fullbleed_probe")
        )
    }

    func testMarkerIsUnique() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(marker(app, "probe_home").waitForExistence(timeout: 15))
        XCTAssertEqual(count(app, "__screen_probe_home"), 1, "a screen must expose exactly one marker")
    }

    // MARK: - Predicate: what does a covered screen look like?

    func testPushedScreenCoversTheParent() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(element(app, "go_pushed").waitForExistence(timeout: 15))
        element(app, "go_pushed").tap()
        XCTAssertTrue(marker(app, "pushed_screen").waitForExistence(timeout: 10))

        print("[screen-marker] PUSH")
        print("  " + snapshot(app, "covering(pushed_screen)", "__screen_pushed_screen"))
        print("  " + snapshot(app, "covered(probe_home)", "__screen_probe_home"))
        print("  " + snapshot(app, "covered_child(leafhost_child_0)", "leafhost_child_0"))
    }

    func testSheetCoversThePresenter() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(element(app, "open_sheet").waitForExistence(timeout: 15))
        element(app, "open_sheet").tap()
        XCTAssertTrue(marker(app, "sheet_screen").waitForExistence(timeout: 10))

        print("[screen-marker] SHEET")
        print("  " + snapshot(app, "covering(sheet_screen)", "__screen_sheet_screen"))
        print("  " + snapshot(app, "covered(probe_home)", "__screen_probe_home"))
    }

    func testFullScreenCoverCoversThePresenter() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(element(app, "open_cover").waitForExistence(timeout: 15))
        element(app, "open_cover").tap()
        XCTAssertTrue(marker(app, "cover_screen").waitForExistence(timeout: 10))

        print("[screen-marker] FULLSCREEN COVER")
        print("  " + snapshot(app, "covering(cover_screen)", "__screen_cover_screen"))
        print("  " + snapshot(app, "covered(probe_home)", "__screen_probe_home"))
    }

    func testInactiveTabScreen() throws {
        try skipUnlessEnabled()
        let app = launchProbe()
        XCTAssertTrue(marker(app, "probe_home").waitForExistence(timeout: 15))

        print("[screen-marker] TAB (before switch)")
        print("  " + snapshot(app, "active(probe_home)", "__screen_probe_home"))
        print("  " + snapshot(app, "inactive(second_tab)", "__screen_second_tab"))

        let secondTab = app.buttons["second"].exists ? app.buttons["second"] : app.staticTexts["second"]
        if secondTab.exists {
            secondTab.tap()
            _ = marker(app, "second_tab").waitForExistence(timeout: 10)
            print("[screen-marker] TAB (after switch)")
            print("  " + snapshot(app, "active(second_tab)", "__screen_second_tab"))
            print("  " + snapshot(app, "inactive(probe_home)", "__screen_probe_home"))
        } else {
            print("[screen-marker] TAB: tab control not addressable; switch skipped")
        }
    }

    func testSplitPaneShowsBothMarkers() throws {
        try skipUnlessEnabled()
        let app = launchProbe("-screenMarkerSplitProbe")
        XCTAssertTrue(marker(app, "left_pane").waitForExistence(timeout: 15))

        // Both panes are genuinely displayed: this is why the assertion
        // means "displayed", never "displayed exclusively".
        XCTAssertTrue(marker(app, "right_pane").exists)
        print("[screen-marker] SPLIT PANE")
        print("  " + snapshot(app, "left_pane", "__screen_left_pane"))
        print("  " + snapshot(app, "right_pane", "__screen_right_pane"))
    }
}
