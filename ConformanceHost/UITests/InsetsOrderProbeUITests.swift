//
//  InsetsOrderProbeUITests.swift
//  ConformanceHostUITests
//
//  A Collection's insets read as paddings are (InsetsOrderProbeView): four
//  values [top, right, bottom, left] — `[0, 0, 0, 30]` puts the first cell
//  30pt in, `[0, 30, 0, 0]` at the start, vertical and horizontal alike; the
//  string form; two values [vertical, horizontal]; one value every side; an
//  unreadable value and three values pad nothing; the insets pad inside the
//  scroll, which stays the Collection's width — on the List routes and the
//  pager too (runRoutes; from jsonui-cli 1.9.0 / SwiftJsonUI 10.29.0 — sjui's
//  Lists read no insets, Dynamic padded its Lists from outside, and both
//  pagers turned their pages in a scroll the insets narrowed). The Dynamic half always;
//  the generated half in the codegen host only. NOT opt-in.
//

import XCTest

final class InsetsOrderProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["io_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for (row, x, y) in [
            ("v_start30", 30, 0),
            ("v_end30", 0, 0),
            ("v_string", 30, 0),
            ("v_two", 20, 4),
            ("v_one", 10, 10),
            ("v_unreadable", 0, 0),
            ("v_three", 0, 0),
            ("h_start30", 30, 0),
            ("h_end30", 0, 0),
            ("v_eager_start30", 30, 0),
            ("flow_start30", 30, 0)
        ] as [(String, CGFloat, CGFloat)] {
            let box = element(app, "\(p)_io_\(row)_box")
            XCTAssertTrue(box.waitForExistence(timeout: 5), "\(p)_io_\(row) is not drawn")
            let list = element(app, "\(p)_io_\(row)").frame
            let cell = element(app, "\(p)_io_\(row)_item_0").frame
            let at = (x: cell.minX - box.frame.minX, y: cell.minY - box.frame.minY)
            lines.append("\(p)_io_\(row): box \(Int(box.frame.width))x\(Int(box.frame.height)), scroll element \(Int(list.width))x\(Int(list.height)) at x=\(Int(list.minX - box.frame.minX)), first cell at x=\(Int(at.x)) y=\(Int(at.y))")
            XCTAssertEqual(at.x, x, accuracy: 1, "\(p)_io_\(row): the first cell is not \(Int(x))pt in")
            XCTAssertEqual(list.width, box.frame.width, accuracy: 1, "\(p)_io_\(row): the scroll is not the Collection's width (the insets are outside it)")
            XCTAssertEqual(at.y, y, accuracy: 1, "\(p)_io_\(row): the first cell is not \(Int(y))pt down")
        }
        lines.forEach { print("IOP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "insets_order_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // The List routes and the pager: the scroll is the Collection's width,
    // and the insets move the first cell from where the same route puts it
    // without insets — a List's own row insets stay (list_none,
    // listclass_none); a pager's page centres its cell in the space the
    // insets leave.
    private func runRoutes(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["io_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for (row, control, dx, dy) in [
            ("list_start30", "list_none", 30, 0),
            ("list_top10", "list_none", 0, 10),
            ("listclass_start30", "listclass_none", 30, 0)
        ] as [(String, String, CGFloat, CGFloat)] {
            let box = element(app, "\(p)_io_\(row)_box")
            XCTAssertTrue(box.waitForExistence(timeout: 5), "\(p)_io_\(row) is not drawn")
            let list = element(app, "\(p)_io_\(row)").frame
            let cell = element(app, "\(p)_io_\(row)_item_0").frame
            let bare = element(app, "\(p)_io_\(control)_item_0").frame
            let bareBox = element(app, "\(p)_io_\(control)_box").frame
            let at = (x: cell.minX - box.frame.minX, y: cell.minY - box.frame.minY)
            let bareAt = (x: bare.minX - bareBox.minX, y: bare.minY - bareBox.minY)
            lines.append("\(p)_io_\(row): box \(Int(box.frame.width))x\(Int(box.frame.height)), scroll element \(Int(list.width))x\(Int(list.height)) at x=\(Int(list.minX - box.frame.minX)), first cell at x=\(Int(at.x)) y=\(Int(at.y)) (\(control): x=\(Int(bareAt.x)) y=\(Int(bareAt.y)))")
            XCTAssertEqual(list.width, box.frame.width, accuracy: 1, "\(p)_io_\(row): the scroll is not the Collection's width (the insets are outside it)")
            XCTAssertEqual(list.height, box.frame.height, accuracy: 1, "\(p)_io_\(row): the scroll is not the Collection's height (the insets are outside it)")
            XCTAssertEqual(at.x - bareAt.x, dx, accuracy: 1, "\(p)_io_\(row): the first cell is not \(Int(dx))pt further in than without insets")
            XCTAssertEqual(at.y - bareAt.y, dy, accuracy: 1, "\(p)_io_\(row): the first cell is not \(Int(dy))pt further down than without insets")
        }
        do {
            let row = "pager_start30"
            let box = element(app, "\(p)_io_\(row)_box")
            XCTAssertTrue(box.waitForExistence(timeout: 5), "\(p)_io_\(row) is not drawn")
            let pager = element(app, "\(p)_io_\(row)").frame
            let cell = element(app, "\(p)_io_\(row)_item_0").frame
            let leading = cell.minX - box.frame.minX, trailing = box.frame.maxX - cell.maxX
            lines.append("\(p)_io_\(row): box \(Int(box.frame.width))x\(Int(box.frame.height)), scroll element \(Int(pager.width))x\(Int(pager.height)) at x=\(Int(pager.minX - box.frame.minX)), first cell \(Int(leading)) from the leading edge, \(Int(trailing)) from the trailing")
            XCTAssertEqual(pager.width, box.frame.width, accuracy: 1, "\(p)_io_\(row): the pager's scroll is not the Collection's width (the insets are outside it)")
            XCTAssertEqual(leading - 30, trailing, accuracy: 1, "\(p)_io_\(row): the cell is not centred in what the insets leave of its page")
        }
        lines.forEach { print("IOP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "insets_routes_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testTheListRoutesAndThePagerPadInsideTheirScrollDynamic() throws {
        runRoutes(prefix: "dyn", argument: "-insetsRoutesProbe")
    }

    func testTheListRoutesAndThePagerPadInsideTheirScrollGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runRoutes(prefix: "cg", argument: "-insetsRoutesProbeCodegen")
    }

    func testACollectionReadsInsetsAsPaddingsDynamic() throws {
        run(prefix: "dyn", argument: "-insetsOrderProbe")
    }

    func testACollectionReadsInsetsAsPaddingsGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-insetsOrderProbeCodegen")
    }
}
