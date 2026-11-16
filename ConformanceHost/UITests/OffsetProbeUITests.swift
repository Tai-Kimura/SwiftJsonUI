//
//  OffsetProbeUITests.swift
//  ConformanceHostUITests
//
//  offsetX moves every leaf type by its value, in Dynamic and in codegen
//  (OffsetProbeView). Each type is read twice, with offsetX 5 and without,
//  each relative to its own fixed parent; the difference must be 5. Image runs
//  the standard chain and is the control. NOT opt-in.
//

import XCTest

final class OffsetProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["of_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for type in ["label", "button", "textview", "selectbox", "image"] {
            // A parent's own frame is the union of its children and its 0.5pt
            // accessibility anchor at its top-left corner, so minX is its left.
            func x(_ v: String) -> CGFloat {
                let parent = element(app, "\(p)_of_p_\(type)_\(v)")
                let child = element(app, "\(p)_of_\(type)_\(v)")
                XCTAssertTrue(child.waitForExistence(timeout: 5), "\(p)_of_\(type)_\(v) is not there")
                return child.frame.minX - parent.frame.minX
            }
            let moved = x("off") - x("no")
            lines.append("\(p)_of_\(type): moved \(moved)")
            XCTAssertEqual(moved, 5, accuracy: 1, "\(p)_of_\(type): offsetX 5 moved it \(moved)")
        }
        lines.forEach { print("OFP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "offset_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testOffsetXMovesEveryLeafTypeDynamic() throws {
        run(prefix: "dyn", argument: "-offsetPlacementProbe")
    }

    func testOffsetXMovesEveryLeafTypeGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-offsetPlacementProbeCodegen")
    }
}
