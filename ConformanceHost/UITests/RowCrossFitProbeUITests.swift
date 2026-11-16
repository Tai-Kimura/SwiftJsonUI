//
//  RowCrossFitProbeUITests.swift
//  ConformanceHostUITests
//
//  A horizontal Collection of wrapContent height is its cells' height
//  (RowCrossFitProbeView): a lazy row 28 in a 120pt View, the label after it
//  right under it; wrapContent both ways, 120 × 28; an eager row 28 and a
//  row of height 40 40, as before. The Dynamic half always; the generated
//  half in the codegen host only. NOT opt-in.
//

import XCTest

final class RowCrossFitProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["rc_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for (row, height, width) in [
            ("lazy_wrap", 28, nil),
            ("lazy_wrap_both", 28, 120),
            ("eager_wrap", 28, nil),
            ("lazy_40", 40, nil)
        ] as [(String, CGFloat, CGFloat?)] {
            let list = element(app, "\(p)_rc_\(row)")
            XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p)_rc_\(row) is not drawn")
            let box = element(app, "\(p)_rc_\(row)_box").frame
            let after = element(app, "\(p)_rc_\(row)_after").frame
            let f = list.frame
            lines.append("\(p)_rc_\(row): list \(Int(f.width))x\(Int(f.height)) in a \(Int(box.height))pt View, the label at y=\(Int(after.minY - box.minY))")
            XCTAssertEqual(f.height, height, accuracy: 1, "\(p)_rc_\(row): the row is not \(Int(height))pt tall")
            if let width = width {
                XCTAssertEqual(f.width, width, accuracy: 1, "\(p)_rc_\(row): the row is not \(Int(width))pt wide")
            }
            XCTAssertEqual(after.minY, f.maxY, accuracy: 2, "\(p)_rc_\(row): the label is not right under the row")
        }
        lines.forEach { print("RCP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "row_cross_fit_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAWrapContentRowIsItsCellsHeightDynamic() throws {
        run(prefix: "dyn", argument: "-rowCrossFitProbe")
    }

    func testAWrapContentRowIsItsCellsHeightGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-rowCrossFitProbeCodegen")
    }
}
