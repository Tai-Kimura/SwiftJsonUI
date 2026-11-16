//
//  WrapMaxProbeUITests.swift
//  ConformanceHostUITests
//
//  A wrapContent axis with a max sizes to its content, capped by the max
//  (WrapMaxProbeView): the chip its text's width, not 160; a long text 160
//  wide and wrapped; a wrapContent-height View with maxHeight 300 its
//  label's height; a matchParent label with maxWidth 160 160, as before.
//  The Dynamic half always; the generated half in the codegen host only.
//  NOT opt-in.
//

import XCTest

final class WrapMaxProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func frame(_ app: XCUIApplication, _ id: String) -> CGRect {
        let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
        XCTAssertTrue(e.waitForExistence(timeout: 5), "\(id) is not drawn")
        return e.frame
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["wm_ready"].waitForExistence(timeout: 15), "probe did not start")
        let chip = frame(app, "\(p)_wm_chip"), long = frame(app, "\(p)_wm_long")
        let box = frame(app, "\(p)_wm_box"), boxLabel = frame(app, "\(p)_wm_box_label"), fill = frame(app, "\(p)_wm_fill")
        print("WMP \(p) chip \(Int(chip.width))x\(Int(chip.height)); long \(Int(long.width))x\(Int(long.height)); box \(Int(box.width))x\(Int(box.height)) (label \(Int(boxLabel.height))); fill \(Int(fill.width))")
        XCTAssertLessThan(chip.width, 90, "\(p)_wm_chip: not its text's width")
        XCTAssertGreaterThan(chip.width, 40, "\(p)_wm_chip: narrower than its text and paddings")
        XCTAssertGreaterThanOrEqual(chip.height, 35.5, "\(p)_wm_chip: shorter than its minHeight")
        XCTAssertEqual(long.width, 160, accuracy: 1, "\(p)_wm_long: not capped at its max")
        XCTAssertGreaterThan(long.height, 40, "\(p)_wm_long: did not wrap")
        XCTAssertEqual(box.height, boxLabel.height, accuracy: 2, "\(p)_wm_box: not its label's height")
        XCTAssertEqual(fill.width, 160, accuracy: 1, "\(p)_wm_fill: a matchParent label is not its max")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "wrap_max_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAWrapContentAxisWithAMaxSizesToItsContentDynamic() throws {
        run(prefix: "dyn", argument: "-wrapMaxProbe")
    }

    func testAWrapContentAxisWithAMaxSizesToItsContentGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-wrapMaxProbeCodegen")
    }
}
