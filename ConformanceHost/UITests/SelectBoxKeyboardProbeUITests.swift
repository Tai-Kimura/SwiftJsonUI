import XCTest

/// A SelectBox pressed while a field holds the keyboard: one press opens the
/// sheet. Opt-in, like the other measuring probes:
/// TEST_RUNNER_SELECTBOX_KEYBOARD_PROBE=1, with
/// TEST_RUNNER_SBK_PATH=dyn|cg, TEST_RUNNER_SBK_SOURCE=tf|tv,
/// TEST_RUNNER_SBK_TARGETS=<ids>, TEST_RUNNER_SBK_N=<rounds>.
final class SelectBoxKeyboardProbeUITests: XCTestCase {
    private var env: [String: String] { ProcessInfo.processInfo.environment }

    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Brings the target on screen with drags above the keyboard, as a finger
    /// would, so the field keeps the keyboard.
    private func scrollTo(_ target: XCUIElement, up: Bool, in app: XCUIApplication) {
        let window = app.windows.firstMatch
        let from = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.40 : 0.15))
        let to = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.15 : 0.40))
        var tries = 0
        while !(target.exists && target.isHittable) && tries < 30 {
            from.press(forDuration: 0.02, thenDragTo: to, withVelocity: .fast, thenHoldForDuration: 0.1)
            tries += 1
        }
    }

    private func enter(_ app: XCUIApplication) {
        if env["SBK_FULL"] == "1" {
            let go = el(app, "sbk_go")
            XCTAssertTrue(go.waitForExistence(timeout: 20), "no way in")
            go.tap()
        }
        XCTAssertTrue(el(app, "sbk_ready").waitForExistence(timeout: 20), "the probe did not start")
    }

    private func presented(_ app: XCUIApplication, _ target: String) -> XCUIElement {
        switch target {
        case "sbk_dialog": return app.buttons["sbk ok"].firstMatch
        case "sbk_alert": return app.alerts.firstMatch
        default: return el(app, "sjui_x7q_done")
        }
    }

    private func close(_ app: XCUIApplication, _ target: String, _ sheet: XCUIElement) {
        switch target {
        case "sbk_dialog", "sbk_alert":
            // A dialog can draw no cancel button on a phone: a tap outside it closes it.
            let cancel = app.buttons["sbk cancel"].firstMatch
            if cancel.exists {
                cancel.tap()
            } else {
                app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
            }
        default: sheet.tap()
        }
        let deadline = Date().addingTimeInterval(4)
        while sheet.exists && Date() < deadline { usleep(100_000) }
    }

    func testOnePressOpensTheSheet() throws {
        guard env["SELECTBOX_KEYBOARD_PROBE"] == "1" else {
            throw XCTSkip("selectbox keyboard probe: run with the guard lifted, as the other probes are")
        }
        let path = env["SBK_PATH"] ?? "dyn"
        let sourceId = env["SBK_SOURCE"] == "tv" ? "sbk_tv" : "sbk_tf"
        let targets = (env["SBK_TARGETS"] ?? "sbk_normal").split(separator: ",").map(String.init)
        let rounds = Int(env["SBK_N"] ?? "") ?? 8
        let wait = Double(env["SBK_WAIT"] ?? "") ?? 4
        let keyboardOpen = env["SBK_CLOSED"] != "1"

        let app = XCUIApplication()
        app.launchArguments = ["-selectBoxKeyboardProbe", path, "-sbkDismissMode", env["SBK_DISMISS"] ?? ""]
            + (env["SBK_WINDOWTAP"] == "1" ? ["-sbkWindowTap"] : [])
            + (env["SBK_FULL"] == "1" ? ["-sbkFull"] : [])
        if path == "cg" { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        enter(app)

        for target in targets {
            var missed = 0, noKeyboard = 0
            for round in 0..<rounds {
                if env["SBK_FRESH"] == "1" {
                    app.terminate()
                    app.launch()
                    enter(app)
                }
                if env["SBK_NOSOURCE"] != "1" {
                    let source = el(app, sourceId)
                    scrollTo(source, up: false, in: app)
                    source.tap()
                    let kb = Date().addingTimeInterval(5)
                    while app.keyboards.count == 0 && Date() < kb { usleep(50_000) }
                    source.typeText("Test Name")
                }
                let t = el(app, target)
                if env["SBK_DRIVER"] == "1" {
                    // scrollUntilVisible's shape: a swipe over the scroller until
                    // hittable, then the frame still for one 0.1 s poll.
                    let scroller = el(app, "sbk_scroll")
                    var swipes = 0
                    while !(t.exists && t.isHittable) && swipes < 20 { scroller.swipeUp(); swipes += 1 }
                    var previous: CGRect?
                    let settle = Date().addingTimeInterval(env["SBK_NOSETTLE"] == "1" ? 0 : 2)
                    while Date() < settle {
                        let f = t.frame
                        if let previous, previous == f { break }
                        previous = f
                        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                    }
                } else if env["SBK_NOSCROLL"] != "1" { scrollTo(t, up: true, in: app) }
                if !keyboardOpen {
                    app.windows.firstMatch.swipeDown(velocity: .slow)
                }
                let openBefore = app.keyboards.count > 0
                if !openBefore { noKeyboard += 1 }
                var moved = ""
                if env["SBK_NOSETTLE"] == "1" {
                    // The tap lands where the box is now, without waiting for the
                    // scroll to come to rest.
                    let f0 = t.frame
                    app.windows.firstMatch.coordinate(withNormalizedOffset: .zero)
                        .withOffset(CGVector(dx: f0.midX, dy: f0.midY)).tap()
                    moved = " y0=\(Int(f0.midY)) y1=\(Int(t.frame.midY))"
                } else {
                    t.tap()
                }
                let sheet = presented(app, target)
                let shown = sheet.waitForExistence(timeout: wait)
                print("SBK path=\(path) source=\(sourceId) target=\(target) round=\(round) keyboardBefore=\(openBefore) sheet=\(shown) keyboardAfter=\(app.keyboards.count > 0)\(moved)")
                if shown {
                    close(app, target, sheet)
                } else {
                    missed += 1
                    let shot = XCTAttachment(screenshot: app.screenshot())
                    shot.name = "miss-\(target)-\(round)"
                    shot.lifetime = .keepAlways
                    add(shot)
                }
            }
            print("SBK_TOTAL path=\(path) source=\(sourceId) target=\(target) missed=\(missed)/\(rounds) noKeyboardBefore=\(noKeyboard)")
        }
    }
}
