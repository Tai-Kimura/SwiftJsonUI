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

    /// The app is ended here, inside the test, rather than left to XCTest's own teardown: on the iOS 27.2 simulator
    /// (Xcode 27.2) the runner process crashed in that teardown ("Critical process xctest crashed") after a long
    /// press the library's drag declined (the locked row), with every assertion already passed and the app well; an
    /// explicit terminate here does not (measured 2026-11-13; 18.6 and 26.5 never crashed).
    override func tearDownWithError() throws {
        XCUIApplication().terminate()
        try super.tearDownWithError()
    }

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
        // The rule reads the dragged row's centre, not the finger: held by its corner, the row's centre is
        // (row centre - badge centre) from the finger, so the finger lets go that far from where the row's centre
        // lands - D's lower quarter, short of E's top (a row is passed when the centre crosses its edge).
        let grip = row(app, 0).frame.midY - badge.frame.midY
        let end = center(row(app, 3), dy: 0.75).withOffset(CGVector(dx: 0, dy: -grip))
        XCTAssertEqual(drag(app, from: center(badge), to: end), "BCDAEF")
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

    /// The row just dropped is picked up again at once and taken back: C (2) down to 3, then straight back to 2, twelve
    /// times. Each return must land on 2 — never one row past it (KotlinJsonUI overcounted the finger here: 5 of 12
    /// came back to 1, 2026-11-13). `grab` is where the drag starts inside the row (the handle for "handle").
    private func pickUpTheJustDroppedRowAgain(_ variant: String) throws {
        let app = try launch(variant)
        let order = app.staticTexts["reorder_order"]
        XCTAssertTrue(row(app, 2).waitForExistence(timeout: 5))
        func grab(_ index: Int) -> XCUICoordinate {
            guard variant == "handle" else { return center(row(app, index)) }
            return center(row(app, index).descendants(matching: .any)["within_badge"].firstMatch)
        }
        var landings: [String] = []
        for _ in 0..<12 {
            // the finger travels one row and 10pt more from the same point of the row, so the carried row's centre
            // passes its neighbour's whether it is held at its centre or by a handle in its corner
            grab(2).press(forDuration: 1.0, thenDragTo: grab(3).withOffset(CGVector(dx: 0, dy: 10)), withVelocity: .slow,
                          thenHoldForDuration: 0.5)
            let down = NSPredicate(format: "label == %@", "ABDCEF")
            _ = XCTWaiter.wait(for: [expectation(for: down, evaluatedWith: order)], timeout: 2)
            let afterDown = order.label
            // at once: no settle between the drop and the next pick-up
            grab(3).press(forDuration: 1.0, thenDragTo: grab(2).withOffset(CGVector(dx: 0, dy: -10)), withVelocity: .slow,
                          thenHoldForDuration: 0.5)
            sleep(1)
            landings.append("\(afterDown)->\(order.label)")
            if order.label != "ABCDEF" { // start the next round from ABCDEF again
                app.terminate()
                app.launch()
                XCTAssertTrue(row(app, 2).waitForExistence(timeout: 15))
            }
        }
        print("REORDER_REPICK \(variant): \(landings.joined(separator: " "))")
        XCTAssertEqual(landings.filter { $0 != "ABDCEF->ABCDEF" }, [], "every return lands on 2")
        XCTAssertEqual(landings.count, 12)
    }

    func testTheJustDroppedRowPickedUpAgainReturnsToItsPlace() throws {
        try pickUpTheJustDroppedRowAgain("none")
    }

    func testTheJustDroppedRowPickedUpAgainByItsHandleReturnsToItsPlace() throws {
        try pickUpTheJustDroppedRowAgain("handle")
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
