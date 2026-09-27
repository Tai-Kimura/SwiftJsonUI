//
//  EagerRowFillProbeUITests.swift
//  ConformanceHostUITests
//
//  A horizontal eager Collection fills a declared height as a lazy one does
//  (EagerRowFillProbeView): its ScrollView is the declared 40pt, and a drag
//  in the 12pt below its 28pt cells scrolls it; a lazy row is 40 as before;
//  an eager row of wrapContent height stays its cells' 28. The Dynamic half
//  always; the generated half in the codegen host only. NOT opt-in.
//

import XCTest

final class EagerRowFillProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["er_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for (name, height) in [("eager_40", 40.0), ("eager_fill", 40.0), ("lazy_40", 40.0), ("eager_wrap", 28.0)] {
            let list = element(app, "\(p)_er_\(name)")
            XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p)_er_\(name) is not drawn")
            let row = element(app, "\(p)_er_\(name)_row")
            let first = list.staticTexts.matching(NSPredicate(format: "label == %@", "e0")).firstMatch
            let before = first.frame.minX
            // a drag 34pt down the row: below the 28pt cells, inside a 40pt row
            let start = row.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 250, dy: 34))
            start.press(forDuration: 0.1, thenDragTo: row.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 60, dy: 34)))
            let moved = before - first.frame.minX
            lines.append("\(p)_er_\(name): list \(Int(list.frame.width))x\(Int(list.frame.height)) in a \(Int(row.frame.height))pt row; a drag at 34pt moved e0 by \(Int(moved))")
            XCTAssertEqual(list.frame.height, height, accuracy: 1, "\(p)_er_\(name): the row's ScrollView is not \(Int(height))pt tall")
            if height == 40 {
                XCTAssertGreaterThan(moved, 20, "\(p)_er_\(name): a drag below the cells does not scroll the row")
            }
        }
        lines.forEach { print("ERP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "eager_row_fill_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAHorizontalEagerRowFillsItsDeclaredHeightDynamic() throws {
        run(prefix: "dyn", argument: "-eagerRowFillProbe")
    }

    func testAHorizontalEagerRowFillsItsDeclaredHeightGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-eagerRowFillProbeCodegen")
    }
}
