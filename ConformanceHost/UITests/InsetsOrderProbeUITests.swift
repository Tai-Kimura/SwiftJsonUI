//
//  InsetsOrderProbeUITests.swift
//  ConformanceHostUITests
//
//  A Collection's insets read as paddings are (InsetsOrderProbeView): four
//  values [top, right, bottom, left] — `[0, 0, 0, 30]` puts the first cell
//  30pt in, `[0, 30, 0, 0]` at the start, vertical and horizontal alike; the
//  string form; two values [vertical, horizontal]; one value every side; an
//  unreadable value and three values pad nothing. The Dynamic half always;
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
            ("h_end30", 0, 0)
        ] as [(String, CGFloat, CGFloat)] {
            let box = element(app, "\(p)_io_\(row)_box")
            XCTAssertTrue(box.waitForExistence(timeout: 5), "\(p)_io_\(row) is not drawn")
            let list = element(app, "\(p)_io_\(row)").frame
            let cell = element(app, "\(p)_io_\(row)_item_0").frame
            let at = (x: cell.minX - box.frame.minX, y: cell.minY - box.frame.minY)
            lines.append("\(p)_io_\(row): box \(Int(box.frame.width))x\(Int(box.frame.height)), scroll element \(Int(list.width))x\(Int(list.height)) at x=\(Int(list.minX - box.frame.minX)), first cell at x=\(Int(at.x)) y=\(Int(at.y))")
            XCTAssertEqual(at.x, x, accuracy: 1, "\(p)_io_\(row): the first cell is not \(Int(x))pt in")
            XCTAssertEqual(at.y, y, accuracy: 1, "\(p)_io_\(row): the first cell is not \(Int(y))pt down")
        }
        lines.forEach { print("IOP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "insets_order_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testACollectionReadsInsetsAsPaddingsDynamic() throws {
        run(prefix: "dyn", argument: "-insetsOrderProbe")
    }

    func testACollectionReadsInsetsAsPaddingsGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-insetsOrderProbeCodegen")
    }
}
