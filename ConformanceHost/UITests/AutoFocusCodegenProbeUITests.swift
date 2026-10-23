import XCTest

/// `autoFocus` (jsonui-cli 2.3.22) on sjui_tools' TextField and TextView
/// (AutoFocusCodegenProbeView): opened, the field holds the keyboard focus —
/// with an id and without one. The TextField without autoFocus is the control:
/// nothing takes the focus there.
///
/// Opt-in, like the other probes: TEST_RUNNER_AUTOFOCUS_CODEGEN_PROBE=1.
final class AutoFocusCodegenProbeUITests: XCTestCase {
    private func focused(_ e: XCUIElement) -> Bool { (e.value(forKey: "hasKeyboardFocus") as? Bool) == true }

    private func open(_ variant: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-autoFocusProbe", variant]
        app.launch()
        XCTAssertTrue(app.staticTexts["af_probe_ready"].waitForExistence(timeout: 15), "\(variant): probe did not start")
        return app
    }

    private func field(_ app: XCUIApplication, _ variant: String) -> XCUIElement {
        let e = variant.hasPrefix("tf") ? app.textFields.firstMatch : app.textViews.firstMatch
        XCTAssertTrue(e.waitForExistence(timeout: 5), "\(variant): the field exists")
        return e
    }

    func testTheFieldIsFocusedWhenTheScreenAppears() throws {
        guard ProcessInfo.processInfo.environment["AUTOFOCUS_CODEGEN_PROBE"] == "1" else {
            throw XCTSkip("autoFocus codegen probe: run with the guard lifted, as the other probes are")
        }
        for variant in ["tfNoId", "tfId", "tvNoId", "tvId"] {
            let app = open(variant)
            let e = field(app, variant)
            let deadline = Date().addingTimeInterval(5)
            while !focused(e) && Date() < deadline { usleep(100_000) }
            print("AF_PROBE \(variant) hasKeyboardFocus=\(focused(e)) keyboards=\(app.keyboards.count)")
            XCTAssertTrue(focused(e), "\(variant): the field holds the keyboard focus on appear")
            XCTAssertGreaterThan(app.keyboards.count, 0, "\(variant): the keyboard is up")
            app.terminate()
        }
    }

    func testTheControlTakesNoFocus() throws {
        guard ProcessInfo.processInfo.environment["AUTOFOCUS_CODEGEN_PROBE"] == "1" else {
            throw XCTSkip("autoFocus codegen probe: run with the guard lifted, as the other probes are")
        }
        let app = open("tfNone")
        let e = field(app, "tfNone")
        sleep(3)
        print("AF_PROBE tfNone hasKeyboardFocus=\(focused(e)) keyboards=\(app.keyboards.count)")
        XCTAssertFalse(focused(e), "a field without autoFocus is not focused on appear")
    }
}
