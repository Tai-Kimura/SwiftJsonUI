import XCTest

/// A handler that takes no value, called as its declared closure type asks
/// (TapArityProbeView; 4f's ruling on
/// control-onclick-is-called-differently-on-every-path, 1.9.0), on both paths:
/// `()` with no argument, `(String)` with the viewId — every node id-less, so
/// the drawn type and the position. A View's, an Image's and a Label's tap, the
/// onclick selector, a Button, a Switch's onClick from its flip, a long press,
/// onAppear and onDisappear — these two also spelled `@{x}` and `x:`, the
/// one name `x`, each `(String)` and `()`. And a ProgressBar the app draws
/// itself, whose onAppear is handed its type as written.
///
/// Every operation's calls are read from the log: exactly the one expected.
///
/// Opt-in, like the other probes: TEST_RUNNER_TAP_ARITY_PROBE=1.
final class TapArityProbeUITests: XCTestCase {
    private var app: XCUIApplication!

    func testEachHandlerIsCalledAsItsDeclarationAsks() throws {
        guard ProcessInfo.processInfo.environment["TAP_ARITY_PROBE"] == "1" else {
            throw XCTSkip("tap arity probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let paths = (ProcessInfo.processInfo.environment["TAP_ARITY_PATHS"] ?? "dynamic,codegen").split(separator: ",").map(String.init)
        for path in paths { run(path) }
    }

    private func labelled(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func calls() -> [String] {
        let readout = app.staticTexts["ta_readout"].label
        guard let start = readout.range(of: "calls[")?.upperBound,
              let end = readout.range(of: "]", options: .backwards)?.lowerBound, start <= end else { return [] }
        return readout[start..<end].split(separator: "|").map(String.init)
    }

    private func check(_ path: String, _ what: String, _ want: [String], _ operate: () -> Void) {
        let before = calls().count
        operate()
        sleep(1)
        let made = Array(calls().dropFirst(before))
        print("TAPARITY \(path) \(what) calls=\(made.joined(separator: "|"))")
        XCTAssertEqual(made, want, "\(path) \(what)")
    }

    private func run(_ path: String) {
        app = XCUIApplication()
        app.launchArguments = ["-tapArityProbe", "-taPath", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["ta_ready"].waitForExistence(timeout: 15), "\(path): probe did not start")
        XCTAssertFalse(app.staticTexts["ta_decode_failed"].exists, "\(path): the layout did not decode")
        XCTAssertTrue(labelled("tap tS").waitForExistence(timeout: 5), "\(path): the rows are there")
        sleep(1)

        // onAppear, from the launch — `x`, `@{x}` and `x:` alike, each as
        // declared: every one called, with nothing else. The ProgressBar the
        // app draws itself is handed the type as written (progressBar_0_16),
        // not the built-in's (progress_0_16).
        let appeared = calls()
        print("TAPARITY \(path) onAppear calls=\(appeared.joined(separator: "|"))")
        XCTAssertEqual(Set(appeared), ["aS(view_0_8)", "aB(view_0_10)", "aC(view_0_11)", "a0()", "a0b()", "a0c()", "pbS(progressBar_0_16)"], "\(path) onAppear")

        check(path, "View tap (String)", ["tS(view_0_0)"]) { labelled("tap tS").tap() }
        check(path, "View tap ()", ["t0()"]) { labelled("tap t0").tap() }
        check(path, "Image tap", ["iS(image_0_2)"]) { labelled("img iS").tap() }
        check(path, "Label tap", ["lS(label_0_3)"]) { labelled("tap lS").tap() }
        check(path, "onclick selector", ["sS(view_0_4)"]) { labelled("tap sS").tap() }
        check(path, "Button", ["bS(button_0_5)"]) { app.buttons["tap bS"].tap() }
        check(path, "Switch flip", ["wS(switch_0_6)"]) { app.switches.firstMatch.tap() }
        check(path, "long press", ["pS(view_0_7)"]) { labelled("press pS").press(forDuration: 1.2) }
        // onDisappear — the rows hidden together, in no promised order.
        let before = calls().count
        app.buttons["ta_hide"].tap()
        sleep(1)
        let gone = Array(calls().dropFirst(before))
        print("TAPARITY \(path) onDisappear calls=\(gone.joined(separator: "|"))")
        XCTAssertEqual(gone.sorted(), ["d0()", "d0b()", "d0c()", "dB(view_0_15_0)", "dC(view_0_15_1)", "dS(view_0_9)"], "\(path) onDisappear")
        print("TAPARITY \(path) readout=\(app.staticTexts["ta_readout"].label)")
        app.terminate()
    }
}
