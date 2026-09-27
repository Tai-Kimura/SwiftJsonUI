//
//  BoundsAlignmentProbeUITests.swift
//  ConformanceHostUITests
//
//  A container's min / max bounds frame puts smaller content at top | start
//  (BoundsAlignmentProbeView): minHeight, minWidth and maxWidth with gravity
//  omitted, and the unnamed axis of centerVertical; a gravity center still
//  centres. The Dynamic half always; the generated half in the codegen host
//  only. NOT opt-in.
//

import XCTest

final class BoundsAlignmentProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["ba_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        // (box, label x centred — else at the start, label y centred — else at the top)
        for (name, centreX, centreY) in [("min_h", false, false), ("min_w", false, false), ("max_w", false, false),
                                         ("min_h_gcv", false, true), ("min_h_gc", true, true)] {
            let box = element(app, "\(p)_ba_\(name)").frame
            let label = element(app, "\(p)_ba_\(name)_label").frame
            let at = (x: label.minX - box.minX, y: label.minY - box.minY)
            let want = (x: centreX ? (box.width - label.width) / 2 : 0, y: centreY ? (box.height - label.height) / 2 : 0)
            lines.append("\(p)_ba_\(name): box \(Int(box.width))x\(Int(box.height)), label at x=\(Int(at.x)) y=\(Int(at.y))")
            XCTAssertGreaterThan(box.width - label.width, 40, "\(p)_ba_\(name): the box is not wider than its label")
            XCTAssertEqual(at.x, want.x, accuracy: 2, "\(p)_ba_\(name): the label is not at x \(Int(want.x))")
            XCTAssertEqual(at.y, want.y, accuracy: 2, "\(p)_ba_\(name): the label is not at y \(Int(want.y))")
        }
        lines.forEach { print("BAP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "bounds_alignment_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testABoundsFrameAlignsAContainersContentTopStartDynamic() throws {
        run(prefix: "dyn", argument: "-boundsAlignmentProbe")
    }

    func testABoundsFrameAlignsAContainersContentTopStartGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-boundsAlignmentProbeCodegen")
    }
}
