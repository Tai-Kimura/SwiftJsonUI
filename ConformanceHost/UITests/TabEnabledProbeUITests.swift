import XCTest

/// A TabView with `enabled: false` does not switch tabs when its tab bar is
/// tapped (the rule: `enabled: false` stops the control's own operation) —
/// with `enabled: true` beside it as the control. Both paths: DynamicView and
/// what sjui build emits (TabEnabledProbeView). Opt-in:
/// TEST_RUNNER_TAB_ENABLED_PROBE=1.
final class TabEnabledProbeUITests: XCTestCase {
    func testADisabledTabViewDoesNotSwitch() throws {
        guard ProcessInfo.processInfo.environment["TAB_ENABLED_PROBE"] == "1" else {
            throw XCTSkip("tab enabled probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        for path in ["dynamic", "codegen"] {
            for gate in ["E", "N"] {
                let app = XCUIApplication()
                app.launchArguments = ["-tabEnabledProbe", gate, "-ocPath", path]
                app.launch()
                XCTAssertTrue(app.staticTexts["te_ready"].waitForExistence(timeout: 15), "\(path) \(gate): probe did not start")
                XCTAssertFalse(app.staticTexts["te_decode_failed"].exists, "\(path) \(gate): the layout did not decode")
                let two = app.tabBars.buttons["Two"]
                XCTAssertTrue(two.waitForExistence(timeout: 5), "\(path) \(gate): the tab bar is there")
                let before = two.isSelected
                two.tap()
                sleep(1)
                let after = two.isSelected
                print("TABENABLED \(path) \(gate) two.selected \(before) -> \(after) enabled=\(two.isEnabled)")
                XCTAssertFalse(before, "\(path) \(gate): tab One starts selected")
                XCTAssertEqual(after, gate == "N", "\(path) \(gate): the tap \(gate == "N" ? "switches" : "does not switch") the tab")
                app.terminate()
            }
        }
    }
}
