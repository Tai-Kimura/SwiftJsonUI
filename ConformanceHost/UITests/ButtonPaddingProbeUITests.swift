import XCTest

/// ButtonPaddingProbeView: each wrapContent Button, titled "Go" as the
/// control is, is wider / taller than the control by exactly the padding it
/// declares (paddings [1, 2, 3, 4] is [top, right, bottom, left]). Prints
/// every reading, so a red names the Button and the axis.
///
/// Measured 2026-10-04 (iOS 26.5, Xcode 26.6). The generated half with
/// jsonui-cli v1.9.13: +0 for paddingLeft / Right, padding and paddingStart /
/// End; +4 of 7 for topPadding 3 with paddingBottom 4. With the Button's
/// padding read in every spelling (jsonui-cli ticket
/// sjui-button-drops-padding-left-right): every Button grows by its padding.
/// The Dynamic half: every Button grows by its padding. paddings [1, 2, 3, 4]
/// widens by 6 either way round: its width cannot tell which side the values
/// land on.
final class ButtonPaddingProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["bp_ready"].waitForExistence(timeout: 15), "probe did not start")
        func frame(_ name: String) -> CGRect {
            let e = app.descendants(matching: .any).matching(identifier: "\(p)_bp_\(name)").firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 10), "\(name) is not drawn")
            return e.frame
        }
        let control = frame("ctl")
        // name: (extra width, extra height) the declaration asks for
        let expected: [(String, CGFloat, CGFloat)] = [("lr", 44, 0), ("uni", 20, 20), ("se", 11, 0), ("tb", 0, 7), ("p4", 6, 4)]
        var wrong: [String] = []
        for (name, dw, dh) in expected {
            let f = frame(name)
            let gotW = f.width - control.width, gotH = f.height - control.height
            let ok = abs(gotW - dw) < 1.0 && abs(gotH - dh) < 1.0
            print("[ButtonPadding] \(p) \(name): +\(gotW) x +\(gotH) (want +\(dw) x +\(dh)) control \(control.size) \(ok ? "ok" : "WRONG")")
            if !ok { wrong.append("\(name) +\(gotW)x+\(gotH) want +\(dw)x+\(dh)") }
        }
        XCTAssertEqual(wrong, [], "Buttons not grown by their padding: \(wrong)")
    }

    func testDynamicButtonsGrowByTheirPadding() throws {
        try XCTSkipIf(codegenHost, "the Dynamic half runs in the Dynamic host")
        run(prefix: "dyn", argument: "-buttonPaddingProbe")
    }

    func testGeneratedButtonsGrowByTheirPadding() throws {
        try XCTSkipUnless(codegenHost, "the generated half runs in the codegen host")
        run(prefix: "cg", argument: "-buttonPaddingProbeCodegen")
    }
}
