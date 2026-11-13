//
//  ReorderProbeUITests.swift
//  ConformanceHostUITests
//
//  A reorderable Collection, dragged as a person drags it (ticket jui-collection-drag-to-reorder): a long press,
//  a slow drag, a short hold, a release. The rows are A–F; the VM's order is read back from `reorder_order`.
//  Below iOS 27 (and with a handle on any iOS) this is the library's own drag; from iOS 27 a stack is SwiftUI's
//  reorderContainer and a List is onMove on every iOS — the same answers either way (shared/core/reorder_vectors.json;
//  the one place iOS 27 reads a row's exact centre the other way is avoided by releasing at a quarter of the row).
//
//  Opt-in (TEST_RUNNER_REORDER_PROBE=1), as the other probes: a drag synthesized on a loaded runner is timing-
//  sensitive.
//

import XCTest

final class ReorderProbeUITests: XCTestCase {

    private func launch(_ variant: String) throws -> XCUIApplication {
        guard ProcessInfo.processInfo.environment["REORDER_PROBE"] == "1" else {
            throw XCTSkip("reorder probe: set TEST_RUNNER_REORDER_PROBE=1 to run")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-reorderProbe", variant]
        app.launch()
        XCTAssertTrue(app.staticTexts["reorder_order"].waitForExistence(timeout: 15))
        return app
    }

    private func row(_ app: XCUIApplication, _ index: Int) -> XCUIElement {
        app.descendants(matching: .any)["reorder_list_item_\(index)"].firstMatch
    }

    /// Long-press `start`, drag slowly to `end`, hold, let go; the order the VM then holds.
    private func drag(_ app: XCUIApplication, from start: XCUICoordinate, to end: XCUICoordinate) -> String {
        start.press(forDuration: 1.0, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.5)
        sleep(1)
        return app.staticTexts["reorder_order"].label
    }

    private func center(_ element: XCUIElement, dy: CGFloat = 0.5) -> XCUICoordinate {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy))
    }

    private func moveRow(_ variant: String, from: Int, to: Int) throws -> String {
        let app = try launch(variant)
        XCTAssertTrue(row(app, from).waitForExistence(timeout: 5))
        return drag(app, from: center(row(app, from)), to: center(row(app, to), dy: to > from ? 0.75 : 0.25))
    }

    func testAStackRowMovesDown() throws {
        XCTAssertEqual(try moveRow("none", from: 0, to: 3), "BCDAEF")
    }

    func testAStackRowMovesUp() throws {
        XCTAssertEqual(try moveRow("none", from: 4, to: 1), "AEBCDF")
    }

    func testALazyStackRowMoves() throws {
        XCTAssertEqual(try moveRow("lazy", from: 0, to: 3), "BCDAEF")
    }

    func testAListRowMoves() throws {
        XCTAssertEqual(try moveRow("list", from: 0, to: 3), "BCDAEF")
    }

    func testALockedRowStopsTheDragAndIsNotPickedUp() throws {
        XCTAssertEqual(try moveRow("locked", from: 0, to: 4), "BACDEF", "stops in front of C")
        XCTAssertEqual(try moveRow("locked", from: 2, to: 0), "ABCDEF", "C is not picked up")
    }

    func testAHandleRowIsGrabbedByItsHandleOnly() throws {
        XCTAssertEqual(try moveRow("handle", from: 0, to: 3), "ABCDEF", "the row's body does not start the drag")
        let app = try launch("handle")
        let badge = row(app, 0).descendants(matching: .any)["within_badge"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 5))
        XCTAssertEqual(drag(app, from: center(badge), to: center(row(app, 3), dy: 0.75)), "BCDAEF")
    }

    func testReleasingOverTheFooterIsTheLastPlaceAndOutsideIsCancelled() throws {
        let app = try launch("none")
        let footer = app.staticTexts["foot"].firstMatch
        XCTAssertTrue(footer.waitForExistence(timeout: 5))
        XCTAssertEqual(drag(app, from: center(row(app, 0)), to: center(footer)), "BCDEFA")
        // 40pt below the Collection (its VStack is the container): over the label that follows it — outside
        let list = app.descendants(matching: .any)["reorder_list"].firstMatch
        let below = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.0)).withOffset(CGVector(dx: 0, dy: 40))
        XCTAssertEqual(drag(app, from: center(row(app, 0)), to: below), "BCDEFA", "below the container: cancelled")
    }

    func testAScrollThatStartsOnARowStillScrolls() throws {
        let app = try launch("none")
        let before = app.staticTexts["reorder_before"].firstMatch
        XCTAssertTrue(before.waitForExistence(timeout: 5))
        row(app, 2).swipeUp()
        sleep(1)
        XCTAssertFalse(before.isHittable, "the ScrollView scrolled under a finger that started on a row")
        XCTAssertEqual(app.staticTexts["reorder_order"].label, "ABCDEF", "and no row moved")
    }
}
