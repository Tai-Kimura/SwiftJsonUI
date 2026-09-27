//
//  FrameAlignmentProbeUITests.swift
//  ConformanceHostUITests
//
//  A frame that sizes one axis of a container puts smaller content at top |
//  start (FrameAlignmentProbeView; the user's ruling of 2026-09-27): each
//  box's label at the box's top and start, a `lazy: none` Collection's cell
//  at its top; a box of both sizes as before; a declared centerVertical
//  still centred. The Dynamic half always; the generated half in the
//  codegen host only. NOT opt-in.
//

import XCTest

final class FrameAlignmentProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["fa_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        // (shape, whether the label is centred vertically — else at the top);
        // every label at the box's start
        let expected: [(String, Bool)] = [
            ("v_mw_h", false), ("z_mw_h", false), ("v_ww_h", false), ("v_w_wh", false), ("v_w_mh", false),
            ("v_w_h", false), ("v_mw_h_gcv", true)
        ]
        for (shape, centred) in expected {
            let box = element(app, "\(p)_fa_\(shape)").frame
            let label = element(app, "\(p)_fa_\(shape)_label").frame
            let at = (x: label.minX - box.minX, y: label.minY - box.minY)
            let x: CGFloat = 0
            let y: CGFloat = centred ? (box.height - label.height) / 2 : 0
            lines.append("\(p)_fa_\(shape): box \(Int(box.width))x\(Int(box.height)), label at x=\(Int(at.x)) y=\(Int(at.y))")
            XCTAssertGreaterThan(box.width, 0, "\(p)_fa_\(shape): no box")
            XCTAssertEqual(at.x, x, accuracy: 2, "\(p)_fa_\(shape): the label is not at the start")
            XCTAssertEqual(at.y, y, accuracy: 2, "\(p)_fa_\(shape): the label is not at y \(Int(y))")
        }
        let collection = element(app, "\(p)_fa_c_mw_h")
        let cell = collection.staticTexts.matching(NSPredicate(format: "label == %@", "c0")).firstMatch.frame
        let cy = cell.minY - collection.frame.minY
        lines.append("\(p)_fa_c_mw_h: box \(Int(collection.frame.width))x\(Int(collection.frame.height)), cell label at y=\(Int(cy))")
        // the cell's label is 4pt (its padding) into the 28pt cell
        XCTAssertEqual(cy, 4, accuracy: 2, "\(p)_fa_c_mw_h: the cell is not at the top")
        lines.forEach { print("FAP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "frame_alignment_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testASingleAxisFrameAlignsTopStartDynamic() throws {
        run(prefix: "dyn", argument: "-frameAlignmentProbe")
    }

    func testASingleAxisFrameAlignsTopStartGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-frameAlignmentProbeCodegen")
    }
}
