import XCTest

/// What `userInteractionEnabled: false` stops on a Button, a TextField, a
/// TextView and a SelectBox (InteractionInputsProbeView), codegen and
/// dynamic: the action, the focus, the sheet. And what `enabled` false stops
/// besides a tap: an Image's tap, a long press, a pan. The rows with no gate are the
/// controls — they say the tap reaches — and are tapped last, since the
/// keyboard and the sheet they open cover the screen.
///
/// Opt-in, like the other probes: TEST_RUNNER_INTERACTION_INPUTS_PROBE=1.
final class InteractionInputsProbeUITests: XCTestCase {
    func testTheGateStopsTheInputs() throws {
        guard ProcessInfo.processInfo.environment["INTERACTION_INPUTS_PROBE"] == "1" else {
            throw XCTSkip("interaction inputs probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-interactionInputsProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["inputs_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["inputs_decode_failed"].exists, "the dynamic layout did not decode")
        let window = app.windows.firstMatch.frame
        func element(_ id: String) -> XCUIElement {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 5), "\(id) exists")
            XCTAssertTrue(window.contains(e.frame), "\(id) on screen: \(e.frame)")
            return e
        }
        func focused(_ id: String) -> Bool {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            if (e.value(forKey: "hasKeyboardFocus") as? Bool) == true { return true }
            // a TextView's text view sits inside the element the id names
            return e.descendants(matching: .textView).allElementsBoundByIndex
                .contains { ($0.value(forKey: "hasKeyboardFocus") as? Bool) == true }
        }
        var seen: [String: String] = [:]
        for p in ["cg", "dyn"] {
            element("\(p)BtnUieFalse").tap()
            element("\(p)BtnPlain").tap()
        }
        // `enabled`: an Image's tap, a long press, a pan — each under no gate,
        // `false` and a binding resolving false.
        for p in ["cg", "dyn"] {
            for g in ["Plain", "EnFalse", "EnBound"] {
                element("\(p)Img\(g)").tap()
                element("\(p)Hold\(g)").press(forDuration: 1.2)
                let drag = element("\(p)Drag\(g)")
                drag.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
                    .press(forDuration: 0.1, thenDragTo: drag.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
            }
        }
        // The fields: the gated ones first, then the controls.
        for suffix in ["UieFalse", "Plain"] {
            for p in ["cg", "dyn"] {
                for kind in ["Tf", "Tv"] {
                    element("\(p)\(kind)\(suffix)").tap()
                    sleep(1)
                    seen["\(p)\(kind)\(suffix)_focused"] = "\(focused("\(p)\(kind)\(suffix)"))"
                }
            }
        }
        // The select boxes last, one at a time: an open sheet covers the
        // screen, so each is closed again before the next.
        app.staticTexts["inputs_probe_ready"].tap()
        for (id, item) in [("cgSbUieFalse", "yUieFalse"), ("dynSbUieFalse", "dyUieFalse"), ("cgSbPlain", "yPlain")] {
            element(id).tap()
            sleep(1)
            let opened = app.staticTexts[item].exists || app.buttons[item].exists || app.pickerWheels.count > 0
            seen["\(id)_opened"] = "\(opened)"
            if opened {
                app.swipeDown(velocity: .fast)
                sleep(1)
            }
        }

        let text = app.staticTexts["inputs_readout"].label
        print("INPUTS_PROBE readout=\(text)")
        for (k, v) in seen.sorted(by: { $0.key < $1.key }) { print("INPUTS_PROBE \(k)=\(v)") }
        for p in ["cg", "dyn"] {
            XCTAssertTrue(text.contains("\(p)BtnPlain=1"), "\(p): the ungated button acts")
            XCTAssertFalse(text.contains("\(p)BtnUieFalse="), "\(p): the gated button does not")
            XCTAssertEqual(seen["\(p)SbUieFalse_opened"], "false", "\(p): the gated select box does not open")
            for kind in ["Tf", "Tv"] {
                XCTAssertEqual(seen["\(p)\(kind)Plain_focused"], "true", "\(p)\(kind): the ungated field takes focus")
                XCTAssertEqual(seen["\(p)\(kind)UieFalse_focused"], "false", "\(p)\(kind): the gated field does not")
            }
        }
        XCTAssertEqual(seen["cgSbPlain_opened"], "true", "the ungated select box opens")
        let counts: [String: Int] = Dictionary(uniqueKeysWithValues: text
            .replacingOccurrences(of: "counts[", with: "").replacingOccurrences(of: "]", with: "")
            .split(separator: ",").compactMap { part -> (String, Int)? in
                let kv = part.split(separator: "=", maxSplits: 1)
                guard kv.count == 2, let n = Int(kv[1]) else { return nil }
                return (String(kv[0]), n)
            })
        for p in ["cg", "dyn"] {
            for kind in ["Img", "Hold", "Drag"] {
                print("INPUTS_PROBE \(p)\(kind) plain=\(counts["\(p)\(kind)Plain"] ?? 0) false=\(counts["\(p)\(kind)EnFalse"] ?? 0) bound=\(counts["\(p)\(kind)EnBound"] ?? 0)")
                XCTAssertGreaterThan(counts["\(p)\(kind)Plain"] ?? 0, 0, "\(p)\(kind): the ungated gesture reaches")
                XCTAssertEqual(counts["\(p)\(kind)EnFalse"] ?? 0, 0, "\(p)\(kind) under enabled false")
                XCTAssertEqual(counts["\(p)\(kind)EnBound"] ?? 0, 0, "\(p)\(kind) under a bound enabled resolving false")
            }
        }
    }
}
