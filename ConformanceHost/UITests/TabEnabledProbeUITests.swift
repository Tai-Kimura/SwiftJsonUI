import XCTest

/// What a TabView's `enabled: false` stops (TabEnabledProbeView): the tab
/// items, not the tab shown (4f's ruling, jsonui-cli 1.9.0). For each gate —
/// E `enabled: false`, N `enabled: true` (the control), U
/// `userInteractionEnabled: false` (the tab view and what it shows) — on both
/// paths (DynamicView and what sjui build emits): a tap on the Button in the
/// first tab, and a tap on the tab "Two". Expected: the Button calls under E
/// and N and not under U; the tab switches under N only. Opt-in:
/// TEST_RUNNER_TAB_ENABLED_PROBE=1.
final class TabEnabledProbeUITests: XCTestCase {
    func testADisabledTabViewDoesNotSwitch() throws {
        guard ProcessInfo.processInfo.environment["TAB_ENABLED_PROBE"] == "1" else {
            throw XCTSkip("tab enabled probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        for path in ["dynamic", "codegen"] {
            for gate in ["E", "N", "U"] {
                let app = XCUIApplication()
                app.launchArguments = ["-tabEnabledProbe", gate, "-ocPath", path]
                app.launch()
                XCTAssertTrue(app.staticTexts["te_ready"].waitForExistence(timeout: 15), "\(path) \(gate): probe did not start")
                XCTAssertFalse(app.staticTexts["te_decode_failed"].exists, "\(path) \(gate): the layout did not decode")
                let two = app.tabBars.buttons["Two"]
                XCTAssertTrue(two.waitForExistence(timeout: 5), "\(path) \(gate): the tab bar is there")
                let button = app.buttons["te_btn_one"]
                XCTAssertTrue(button.waitForExistence(timeout: 5), "\(path) \(gate): the first tab's Button is there")
                sleep(1)
                let buttonEnabled = button.isEnabled
                button.tap()
                sleep(1)
                let taps = app.staticTexts["te_taps"].label
                let before = two.isSelected
                two.tap()
                sleep(1)
                let after = two.isSelected
                print("TABENABLED \(path) \(gate) button.enabled=\(buttonEnabled) \(taps) two.selected \(before) -> \(after) two.enabled=\(two.isEnabled)")
                XCTAssertEqual(taps, gate == "U" ? "taps=0" : "taps=1", "\(path) \(gate): the first tab's Button \(gate == "U" ? "is stopped" : "calls")")
                XCTAssertFalse(before, "\(path) \(gate): tab One starts selected")
                XCTAssertEqual(after, gate == "N", "\(path) \(gate): the tap \(gate == "N" ? "switches" : "does not switch") the tab")
                app.terminate()
            }
        }
    }

    /// The candidates for stopping only the tab items (TabEnabledCandidates):
    /// a tap on tab Two, whether it reads enabled, and whether tab One's
    /// Button still works.
    func testTheCandidates() throws {
        guard ProcessInfo.processInfo.environment["TAB_ENABLED_PROBE"] == "1" else {
            throw XCTSkip("tab enabled probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        for kind in ["C0", "C1", "C2", "C3", "C4", "C5", "N"] {
            let app = XCUIApplication()
            app.launchArguments = ["-tabEnabledProbe", kind, "-ocPath", "candidate"]
            app.launch()
            XCTAssertTrue(app.staticTexts["te_ready"].waitForExistence(timeout: 15), "\(kind): probe did not start")
            let two = app.tabBars.buttons["Two"]
            let one = app.tabBars.buttons["One"]
            XCTAssertTrue(two.waitForExistence(timeout: 5), "\(kind): the tab bar is there")
            sleep(1)
            let btn = app.buttons["te_btn_one"]
            let btnEnabled = btn.exists ? btn.isEnabled : false
            if btn.exists { btn.tap() }
            sleep(1)
            let enabledBefore = "one=\(one.isEnabled) two=\(two.isEnabled)"
            app.buttons["te_walk"].tap()
            sleep(2)
            print("TABWALK \(kind) \(app.staticTexts["te_walk_out"].label) | two.selected after activation=\(two.isSelected) contentTwo=\(app.staticTexts["te_content_two"].exists)")
            if two.isSelected {
                one.tap()
                sleep(1)
            }
            if btn.exists { btn.tap(); sleep(1); btn.tap(); sleep(1) }
            two.tap()
            sleep(1)
            let contentTwo = app.staticTexts["te_content_two"].exists
            let contentOne = app.staticTexts["te_content_one"].exists
            let counts = app.staticTexts["te_counts"].label
            print("TABCAND \(kind) btnOne.enabled=\(btnEnabled) items[\(enabledBefore)] after-tap-Two: two.selected=\(two.isSelected) one.selected=\(one.isSelected) contentOne=\(contentOne) contentTwo=\(contentTwo) | \(counts)")
            app.terminate()
        }
    }
}
