//
//  ScreenMarkerProbeUITests.swift
//  ConformanceHostUITests
//
//  Screen-marker measurement (screen-identity track, Phase 0) — NOT part of
//  the conformance suite. Runs only with SCREEN_MARKER_PROBE=1
//  (pass TEST_RUNNER_SCREEN_MARKER_PROBE=1 to xcodebuild).
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

    private func skipUnlessEnabled() throws {
        guard ProcessInfo.processInfo.environment["SCREEN_MARKER_PROBE"] == "1" else {
            throw XCTSkip("screen marker probe: set TEST_RUNNER_SCREEN_MARKER_PROBE=1 to run")
        }
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
