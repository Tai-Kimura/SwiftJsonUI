import XCTest

/// The driver's own steps on a screen a keyboard has made narrow: input,
/// scrollUntilVisible, then selectOption / tap. Opt-in:
/// TEST_RUNNER_SCROLL_THEN_TAP_PROBE=1, TEST_RUNNER_STT_FILLERS=<heights>,
/// TEST_RUNNER_STT_N=<rounds>, TEST_RUNNER_STT_ACTION=selectOption|tap.
final class ScrollThenTapProbeUITests: XCTestCase {
    private var env: [String: String] { ProcessInfo.processInfo.environment }

    private func step(_ json: String) throws -> TestStep {
        try JSONDecoder().decode(TestStep.self, from: Data(json.utf8))
    }

    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func testSteps() throws {
        guard env["SCROLL_THEN_TAP_PROBE"] == "1" else {
            throw XCTSkip("scroll then tap probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let fillers = (env["STT_FILLERS"] ?? "700").split(separator: ",").map(String.init)
        let rounds = Int(env["STT_N"] ?? "") ?? 4
        let target = env["STT_TARGET"] ?? "sbk_normal"
        let action = env["STT_ACTION"] ?? "selectOption"
        let tail = env["STT_TAIL"] ?? "1500"
        let source = env["STT_SOURCE"] == "tv" ? "sbk_tv" : "sbk_tf"
        for filler in fillers {
            var missed = 0
            for round in 0..<rounds {
                let app = XCUIApplication()
                app.launchArguments = ["-selectBoxKeyboardProbe", env["STT_PATH"] ?? "dyn"] + (env["STT_NOBAR"] == "1" || env["STT_TABS"] == "1" ? [] : ["-sbkFull"]) + [
                                       "-sbkFiller", String(filler.split(separator: ":").first ?? "700"), "-sbkTail", tail]
                    + (env["STT_WINDOWTAP"] == "1" ? ["-sbkWindowTap"] : [])
                    + (env["STT_TABS"] == "1" ? ["-sbkTabs"] : [])
                if env["STT_PATH"] == "cg" { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
                app.launch()
                if env["STT_NOBAR"] != "1" && env["STT_TABS"] != "1" {
                    let go = el(app, "sbk_go")
                    XCTAssertTrue(go.waitForExistence(timeout: 20))
                    go.tap()
                }
                XCTAssertTrue(el(app, "sbk_ready").waitForExistence(timeout: 20))
                let executor = XCUITestActionExecutor(platform: "ios")
                var outcome = "ok"
                var at = ""
                do {
                    if env["STT_CLEAR"] == "1" {
                        try executor.execute(step: step(#"{"action":"clear","id":"\#(source)"}"#), in: app)
                    }
                    if env["STT_NOSOURCE"] != "1" {
                        try executor.execute(step: step(#"{"action":"input","id":"\#(source)","value":"Test Name"}"#), in: app)
                    }
                    if env["STT_PLACE"] == "1" {
                        // Slow drags with no momentum until the target's centre rests
                        // under the navigation bar.
                        let window = app.windows.firstMatch
                        let t = el(app, target)
                        let barElement = env["STT_TABS"] == "1" ? app.tabBars.firstMatch : app.navigationBars.firstMatch
                        let bar = barElement.exists ? barElement.frame : CGRect(x: 0, y: 62, width: 402, height: 54)
                        var tries = 0
                        let aim = CGFloat(Double(filler.split(separator: ":").last ?? "") ?? Double(bar.midY))
                        while tries < 40 && abs(t.frame.midY - aim) > 3 {
                            let delta = t.frame.midY - aim
                            let step = min(max(delta, -300), 300)
                            let from = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 200, dy: 450))
                            let to = from.withOffset(CGVector(dx: 0, dy: -step))
                            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.3)
                            tries += 1
                        }
                    }
                    if env["STT_PLACE"] != "1" || action == "scrollOnly" {
                        try executor.execute(step: step(#"{"action":"scrollUntilVisible","id":"\#(target)","container":"sbk_scroll"}"#), in: app)
                    }
                    let t = el(app, target)
                    let v = el(app, "sbk_scroll").frame
                    let nb = env["STT_TABS"] == "1" ? app.tabBars.firstMatch : app.navigationBars.firstMatch
                    at = " y=\(Int(t.frame.minY))..\(Int(t.frame.maxY)) hittable=\(t.isHittable) scroller=\(Int(v.minY))..\(Int(v.maxY)) keyboards=\(app.keyboards.count) bar=\(nb.exists ? "\(Int(nb.frame.minY))..\(Int(nb.frame.maxY))" : "none")"
                    if action == "scrollOnly" {
                        // scrollUntilVisible alone: where it leaves the target.
                        let m = t.frame.midY
                        if m < nb.frame.maxY || m > v.maxY { outcome = "notInBand" }
                    } else if action == "clear" {
                        try executor.execute(step: step(#"{"action":"clear","id":"\#(target)"}"#), in: app)
                        if !((t.value(forKey: "hasKeyboardFocus") as? Bool) ?? false) { outcome = "noFocus" }
                    } else if action == "barItem" {
                        // A button of the bar itself: it sits in the band and is what to press.
                        try executor.execute(step: step(#"{"action":"tap","id":"sbk_bar_item"}"#), in: app)
                        if !app.alerts.firstMatch.waitForExistence(timeout: 3) { outcome = "barItemNotPressed" }
                    } else if action == "input" {
                        try executor.execute(step: step(#"{"action":"input","id":"\#(target)","value":"XY"}"#), in: app)
                        if !"\(t.value ?? "")".contains("XY") { outcome = "notTyped" }
                    } else if action == "tap" || action == "doubleTap" {
                        try executor.execute(step: step(#"{"action":"\#(action)","id":"\#(target)"}"#), in: app)
                        let done = el(app, "sjui_x7q_done")
                        if !done.waitForExistence(timeout: 3) { outcome = "noSheet" }
                    } else {
                        try executor.execute(step: step(#"{"action":"selectOption","id":"\#(target)","index":1,"timeout":1500}"#), in: app)
                    }
                } catch {
                    outcome = "\(error)".prefix(90).description
                }
                if outcome != "ok" {
                    missed += 1
                    let shot = XCTAttachment(screenshot: app.screenshot())
                    shot.name = "miss-\(filler)-\(round)"
                    shot.lifetime = .keepAlways
                    add(shot)
                }
                let after = el(app, target).frame
                print("STT filler=\(filler) round=\(round)\(at) yAfter=\(Int(after.minY)) outcome=\(outcome)")
                app.terminate()
            }
            print("STT_TOTAL action=\(action) source=\(source) filler=\(filler) missed=\(missed)/\(rounds)")
        }
    }
}
