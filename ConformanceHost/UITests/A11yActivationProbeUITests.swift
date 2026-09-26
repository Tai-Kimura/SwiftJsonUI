import XCTest

/// Whether a screen reader can operate what `userInteractionEnabled` stops
/// (A11yActivationProbeView). Per attribute_definitions.json the flag stops
/// the view and everything in it; a touch is stopped by hit testing, and this
/// asks the other way in: VoiceOver's double tap, which calls the element's
/// `accessibilityActivate()` and sends a touch to its activation point only
/// when that returns false.
///
/// Three runs: the bound stop open, closed, open again. In each, the app
/// activates every element and reports what that moved; for each element
/// whose activation returned false the test sends the touch VoiceOver would.
/// What an element moved is the activation's count, or the touch's when the
/// activation returned false. Expected:
/// - the rows with no stop (`…Plain`): 1 in every run (the controls — they
///   say the walk reaches the element and the activation operates it);
/// - inside `userInteractionEnabled: false`, or with it of their own: 0;
/// - inside the bound stop, and the cells under it: 1 open, 0 closed.
/// The cell drawn `.equatable()` must also carry the button trait exactly
/// while the stop is open — the environment reaching it after the binding
/// flipped; the cell drawn without `.equatable()` is the contrast.
/// The candidate fixes (`fix…`) are printed, not judged, with whether each
/// draws as the Switch emitted today.
///
/// Opt-in, like the other probes: TEST_RUNNER_A11Y_ACTIVATION_PROBE=1.
final class A11yActivationProbeUITests: XCTestCase {
    private struct Entry {
        let name: String
        let via: String
        let element: Bool
        let button: Bool
        let notEnabled: Bool
        let returned: Bool
        let moved: Int
        let point: CGPoint?
    }

    private func want(_ name: String, open: Bool) -> Int? {
        if name.hasPrefix("fix") { return nil }
        if name.hasSuffix("Plain") { return 1 }
        if name.contains("InFalse") || name.contains("SelfFalse") { return 0 }
        if name.contains("InBound") || name.hasPrefix("cgCell") { return open ? 1 : 0 }
        return nil
    }

    private func section(_ text: String, _ key: String) -> Substring? {
        guard let start = text.range(of: "\(key)[")?.upperBound,
              let end = text[start...].firstIndex(of: "]") else { return nil }
        return text[start..<end]
    }

    private func counts(_ text: String) -> [String: Int] {
        var out: [String: Int] = [:]
        for part in section(text, "counts")?.split(separator: ",") ?? [] {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { out[String(kv[0])] = Int(kv[1]) }
        }
        return out
    }

    /// name=via/element/button/notEnabled/returned/moved/x,y
    private func entries(_ text: String) -> [Entry] {
        (section(text, "act")?.split(separator: ";") ?? []).compactMap { part in
            let kv = part.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { return nil }
            let f = kv[1].split(separator: "/").map(String.init)
            guard f.count == 7 else { return nil }
            let xy = f[6].split(separator: ",").compactMap { Double($0) }
            let point = xy.count == 2 && xy[0] >= 0 ? CGPoint(x: xy[0], y: xy[1]) : nil
            return Entry(name: String(kv[0]), via: f[0], element: f[1] == "1", button: f[2] == "1",
                         notEnabled: f[3] == "1", returned: f[4] == "1", moved: Int(f[5]) ?? -1, point: point)
        }
    }

    func testAScreenReaderCannotOperateWhatAStopHolds() throws {
        guard ProcessInfo.processInfo.environment["A11Y_ACTIVATION_PROBE"] == "1" else {
            throw XCTSkip("a11y activation probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-a11yActivationProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["a11y_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["a11y_decode_failed"].exists, "the dynamic layout did not decode")
        let readout = app.staticTexts["a11y_readout"]
        let origin = app.coordinate(withNormalizedOffset: .zero)

        // How each candidate fix draws, against the Switch as emitted outside
        // a stop — and, as the comparison's own control, the same Switch
        // inside the stop as emitted (the same pixels are expected there).
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "a11y activation probe"
        shot.lifetime = .keepAlways
        add(shot)
        func png(_ id: String) -> Data? {
            let e = app.switches[id].firstMatch
            guard e.waitForExistence(timeout: 5) else { return nil }
            let s = e.screenshot()
            let a = XCTAttachment(screenshot: s)
            a.name = id
            a.lifetime = .keepAlways
            add(a)
            return s.pngRepresentation
        }
        let plain = png("cgSwPlain")
        for id in ["cgSwInFalse", "fixDisabledSw", "fixRespondsSw"] {
            let other = png(id)
            print("A11Y_PROBE visual \(id) drawn as cgSwPlain: \(plain != nil && other == plain) (found \(other != nil))")
        }

        var mismatches: [String] = []
        for (phase, open) in [(1, true), (2, false), (3, true)] {
            if phase > 1 {
                app.buttons["a11y_flip"].tap()
                sleep(1)
            }
            app.buttons["a11y_run"].tap()
            let ran = NSPredicate(format: "label BEGINSWITH %@", "ran=\(phase) ")
            let done = expectation(for: ran, evaluatedWith: readout)
            wait(for: [done], timeout: 90)
            let text = readout.label
            XCTAssertTrue(text.contains("gate=\(open ? "open" : "closed")"), "run \(phase): the gate is \(open ? "open" : "closed")")
            let walk = text.range(of: #"walk=(\d+)/(\d+)"#, options: .regularExpression).map { String(text[$0]) } ?? "walk=?"
            print("A11Y_PROBE run=\(phase) \(walk) (nodes the in-app walk reached / with an identifier)")
            let list = entries(text)
            XCTAssertFalse(list.isEmpty, "run \(phase): no entries in the readout: \(text)")
            for e in list {
                // VoiceOver's touch when the activation returned false
                var touched: Int? = nil
                if !e.returned, let p = e.point {
                    let before = counts(readout.label)[e.name] ?? 0
                    origin.withOffset(CGVector(dx: p.x, dy: p.y)).tap()
                    usleep(400_000)
                    touched = (counts(readout.label)[e.name] ?? 0) - before
                }
                let moved = e.returned ? e.moved : (touched ?? 0)
                let expected = want(e.name, open: open)
                print("A11Y_PROBE run=\(phase) gate=\(open ? "open" : "closed") \(e.name) via=\(e.via) element=\(e.element) "
                      + "button=\(e.button) notEnabled=\(e.notEnabled) activate=\(e.returned) activateMoved=\(e.moved) "
                      + "touchMoved=\(touched.map(String.init) ?? "-") moved=\(moved) want=\(expected.map(String.init) ?? "-") "
                      + "point=\(e.point.map { "\(Int($0.x)),\(Int($0.y))" } ?? "-")")
                if let expected, moved != expected {
                    mismatches.append("run \(phase) \(e.name): moved \(moved) (activate=\(e.returned) \(e.moved), touch \(touched.map(String.init) ?? "-")), want \(expected)")
                }
                if e.name.hasPrefix("cgCell") && e.button != open {
                    mismatches.append("run \(phase) \(e.name): button trait \(e.button) with the stop \(open ? "open" : "closed") — the environment did not reach the cell")
                }
            }
            let names = Set(list.map(\.name))
            for required in ["cgCellEq", "cgCellNoEq", "cgSwInFalse", "dynSwInFalse"] where !names.contains(required) {
                mismatches.append("run \(phase): no entry for \(required)")
            }
        }
        let end = XCTAttachment(screenshot: app.screenshot())
        end.name = "after the three runs"
        end.lifetime = .keepAlways
        add(end)
        for m in mismatches { print("A11Y_PROBE MISMATCH \(m)") }
        XCTAssertEqual(mismatches, [], "what a screen reader operated against what the stop allows")
    }
}
