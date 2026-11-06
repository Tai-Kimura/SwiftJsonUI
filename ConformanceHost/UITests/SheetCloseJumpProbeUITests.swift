import XCTest

/// Where the scroll ends up after a sheet closes while a field far away holds
/// the keyboard. Opt-in: TEST_RUNNER_SHEET_JUMP_PROBE=1, TEST_RUNNER_SJ_ARMS,
/// TEST_RUNNER_SJ_N, TEST_RUNNER_SJ_AIMS (the box's centre y before the press).
final class SheetCloseJumpProbeUITests: XCTestCase {
    private var env: [String: String] { ProcessInfo.processInfo.environment }
    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func testWhereTheScrollEndsUp() throws {
        guard env["SHEET_JUMP_PROBE"] == "1" else {
            throw XCTSkip("sheet jump probe: run with the guard lifted, as the other probes are")
        }
        let arms = (env["SJ_ARMS"] ?? "pp,ap,ps,as").split(separator: ",").map(String.init)
        let aims = (env["SJ_AIMS"] ?? "300,440").split(separator: ",").compactMap { Double($0) }
        let rounds = Int(env["SJ_N"] ?? "") ?? 4
        for arm in arms {
            for aim in aims {
                var jumps = 0
                for round in 0..<rounds {
                    let app = XCUIApplication()
                    app.launchArguments = ["-sheetJumpProbe", arm]
                    app.launch()
                    let go = el(app, "sj_go")
                    XCTAssertTrue(go.waitForExistence(timeout: 20))
                    go.tap()
                    let field = el(app, "sj_field")
                    XCTAssertTrue(field.waitForExistence(timeout: 10))
                    field.tap()
                    let until = Date().addingTimeInterval(5)
                    while app.keyboards.count == 0 && Date() < until { usleep(100_000) }
                    field.typeText("abc")
                    let box = el(app, "sj_box")
                    let window = app.windows.firstMatch.coordinate(withNormalizedOffset: .zero)
                    var tries = 0
                    while tries < 40 && abs(box.frame.midY - aim) > 6 {
                        let step = min(max(box.frame.midY - aim, -260), 260)
                        let from = window.withOffset(CGVector(dx: 200, dy: step > 0 ? 400 : 140))
                        from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: 0, dy: -step)),
                                   withVelocity: .slow, thenHoldForDuration: 0.2)
                        tries += 1
                    }
                    let before = box.frame.midY
                    let keyboardBefore = app.keyboards.count
                    box.tap()
                    let done = el(app, "sjui_x7q_done")
                    let opened = done.waitForExistence(timeout: 4)
                    if opened { done.tap() }
                    let gone = Date().addingTimeInterval(4)
                    while done.exists && Date() < gone { usleep(100_000) }
                    sleep(2)
                    let after = box.frame.midY
                    let keyboardAfter = app.keyboards.count
                    let focused = (field.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
                    let jumped = abs(after - before) > 200
                    if jumped { jumps += 1 }
                    print("SJ arm=\(arm) aim=\(Int(aim)) round=\(round) opened=\(opened) before=\(Int(before)) after=\(Int(after)) keyboards=\(keyboardBefore)->\(keyboardAfter) fieldFocused=\(focused) fieldY=\(Int(field.frame.midY)) jumped=\(jumped)")
                    app.terminate()
                }
                print("SJ_TOTAL arm=\(arm) aim=\(Int(aim)) jumped=\(jumps)/\(rounds)")
            }
        }
    }
}
