import XCTest

/// `bind` folded on the node drawn (BindFoldProbeView; jsonui-cli 1.9.0,
/// bind (B)), on both paths — DynamicView and what sjui build emits:
/// - a Date SelectBox's lone `bind` is its selectedDate: it shows the bound day;
/// - a CheckBox's `bind` beside a literal `isOn: false` is dropped: tapping it
///   writes nothing to the bound `on`;
/// - a CheckBox's lone `bind` is its isOn: tapping it writes `on`.
///
/// Opt-in, like the other probes: TEST_RUNNER_BIND_FOLD_PROBE=1.
final class BindFoldProbeUITests: XCTestCase {
    func testBindIsFoldedIntoTheValueItStandsFor() throws {
        guard ProcessInfo.processInfo.environment["BIND_FOLD_PROBE"] == "1" else {
            throw XCTSkip("bind fold probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        for path in (ProcessInfo.processInfo.environment["BIND_FOLD_PATHS"] ?? "dynamic,codegen").split(separator: ",").map(String.init) {
            run(path)
        }
    }

    private func run(_ path: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-bindFoldProbe", "-bfPath", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["bf_ready"].waitForExistence(timeout: 15), "\(path): probe did not start")
        XCTAssertFalse(app.staticTexts["bf_decode_failed"].exists, "\(path): the layout did not decode")
        func element(_ id: String) -> XCUIElement {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 5), "\(path) \(id) exists")
            return e
        }
        let readout = { app.staticTexts["bf_readout"].label }
        sleep(1)
        let date = element("bfDate")
        let shown = "\(date.label) \(date.value ?? "")"
        print("BINDFOLD \(path) date shows [\(shown)] readout=\(readout())")
        XCTAssertTrue(shown.contains("2026-01-02"), "\(path): the Date SelectBox shows its bound day: [\(shown)]")

        XCTAssertEqual(readout(), "day=2026-01-02,on=true", "\(path): at rest")
        element("bfCheck").tap()
        sleep(1)
        print("BINDFOLD \(path) after the literal CheckBox: \(readout())")
        XCTAssertEqual(readout(), "day=2026-01-02,on=true", "\(path): bind beside the literal isOn is dropped — nothing written")
        element("bfCheckLone").tap()
        sleep(1)
        print("BINDFOLD \(path) after the lone CheckBox: \(readout())")
        XCTAssertEqual(readout(), "day=2026-01-02,on=false", "\(path): a lone bind is the isOn — written")
        app.terminate()
    }
}
