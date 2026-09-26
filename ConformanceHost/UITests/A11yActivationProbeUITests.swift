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
/// The candidate fixes (`cand…`) are printed, not judged: what the
/// activation moved, what a screen reader reads (traits, the toggle trait,
/// respondsToUserInteraction, the value), and whether each draws as the
/// Switch or the Button emitted today.
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
        /// What a screen reader reads: the traits (hex), the toggle trait,
        /// respondsToUserInteraction, the value.
        let traits: String
        let toggle: Bool
        let responds: Bool
        let value: String
    }

    private func want(_ name: String, open: Bool) -> Int? {
        if name.hasPrefix("fix") || name.hasPrefix("cand") { return nil }
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

    /// name=via/element/button/notEnabled/returned/moved/x,y/traits/toggle/responds/value
    private func entries(_ text: String) -> [Entry] {
        (section(text, "act")?.split(separator: ";") ?? []).compactMap { part in
            let kv = part.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { return nil }
            let f = kv[1].split(separator: "/").map(String.init)
            guard f.count >= 7 else { return nil }
            let xy = f[6].split(separator: ",").compactMap { Double($0) }
            let point = xy.count == 2 && xy[0] >= 0 ? CGPoint(x: xy[0], y: xy[1]) : nil
            return Entry(name: String(kv[0]), via: f[0], element: f[1] == "1", button: f[2] == "1",
                         notEnabled: f[3] == "1", returned: f[4] == "1", moved: Int(f[5]) ?? -1, point: point,
                         traits: f.count > 7 ? f[7] : "-", toggle: f.count > 8 && f[8] == "1",
                         responds: f.count > 9 && f[9] == "1", value: f.count > 10 ? f[10] : "")
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
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            guard e.waitForExistence(timeout: 5) else { return nil }
            let s = e.screenshot()
            let a = XCTAttachment(screenshot: s)
            a.name = id
            a.lifetime = .keepAlways
            add(a)
            return s.pngRepresentation
        }
        let plain = png("cgSwPlain")
        let inStop = png("cgSwInFalse")
        print("A11Y_PROBE visual cgSwInFalse drawn as cgSwPlain: \(plain != nil && inStop == plain) (the comparison's control)")


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
                      + "point=\(e.point.map { "\(Int($0.x)),\(Int($0.y))" } ?? "-") traits=\(e.traits) toggle=\(e.toggle) "
                      + "responds=\(e.responds) value=\(e.value)")
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

    /// The candidate fixes on a screen of their own (`-candidates`): for each,
    /// what VoiceOver's activation moved (or the touch it sends when the
    /// activation returns false), what a screen reader reads, and whether it
    /// draws as the Switch / Button emitted today. Printed, not judged.
    static let candidateIds = ["candSwEmitted", "candSwGate", "candSwGateTraitsResp", "candSwGateButtonResp", "candSwGateResp",
                               "candSwActionTraitsResp", "candSwDisabled", "candBtnEmitted", "candBtnTraitsResp", "candBtnDisabled",
                               "candCondOpenSw", "candCondOpenBtn", "candHiddenSw", "candHiddenBtn", "candHiddenLbl", "candSwMod", "candSwModOpen", "candBtnMod", "candBtnModOpen"]

    func testTheCandidateFixes() throws {
        guard ProcessInfo.processInfo.environment["A11Y_ACTIVATION_PROBE"] == "1" else {
            throw XCTSkip("a11y activation probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-a11yActivationProbe", "-candidates"]
        app.launch()
        XCTAssertTrue(app.staticTexts["a11y_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        let readout = app.staticTexts["a11y_readout"]
        let origin = app.coordinate(withNormalizedOffset: .zero)
        func image(_ id: String) -> UIImage? {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            guard e.waitForExistence(timeout: 5) else { return nil }
            let s = e.screenshot()
            let a = XCTAttachment(screenshot: s)
            a.name = id
            a.lifetime = .keepAlways
            add(a)
            return s.image
        }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "candidates"
        shot.lifetime = .keepAlways
        add(shot)
        // `…Emitted2` is the same view as `…Emitted` in another place: the
        // comparison's own control (the same pixels are expected).
        for (reference, ids) in [("candSwEmitted", ["candSwEmitted2", "candSwGate", "candSwGateTraitsResp", "candSwGateButtonResp",
                                                    "candSwGateResp", "candSwActionTraitsResp", "candSwDisabled", "candCondOpenSw",
                                                    "candSwMod", "candSwModOpen"]),
                                 ("candBtnEmitted", ["candBtnEmitted2", "candBtnTraitsResp", "candBtnDisabled", "candCondOpenBtn",
                                                     "candBtnMod", "candBtnModOpen"])] {
            let ref = image(reference)
            for id in ids {
                print("A11Y_PROBE visual \(id) against \(reference): \(Self.pixelDifference(ref, image(id)))")
            }
        }
        // In the accessibility tree the test runner reads (an assistive
        // technology's view): a hidden element is not there.
        for id in A11yActivationProbeUITests.candidateIds {
            print("A11Y_PROBE tree \(id) exists=\(app.descendants(matching: .any).matching(identifier: id).firstMatch.exists)")
        }
        app.buttons["a11y_run"].tap()
        let done = expectation(for: NSPredicate(format: "label BEGINSWITH %@", "ran=1 "), evaluatedWith: readout)
        wait(for: [done], timeout: 90)
        for e in entries(readout.label) where e.name.hasPrefix("cand") {
            var touched: Int? = nil
            if !e.returned, let p = e.point {
                let before = counts(readout.label)[e.name] ?? 0
                origin.withOffset(CGVector(dx: p.x, dy: p.y)).tap()
                usleep(400_000)
                touched = (counts(readout.label)[e.name] ?? 0) - before
            }
            print("A11Y_PROBE cand \(e.name) via=\(e.via) activate=\(e.returned) activateMoved=\(e.moved) "
                  + "touchMoved=\(touched.map(String.init) ?? "-") button=\(e.button) toggle=\(e.toggle) "
                  + "notEnabled=\(e.notEnabled) responds=\(e.responds) traits=\(e.traits) value=\(e.value)")
        }
    }

    /// Two element screenshots, pixel by pixel: the pixels whose largest
    /// channel differs by more than 24 (of 255), and the largest difference.
    /// Not the PNG bytes: the same view drawn at another place antialiases
    /// differently, and its frame rounds to a size a pixel or two apart
    /// (measured: two identical Buttons, 32x60 against 32x61). So the smaller
    /// image is laid on the larger at each offset those pixels allow, and the
    /// best alignment is reported — a threshold absorbs the antialiasing; a
    /// dimmed control is thousands of pixels over it.
    static func pixelDifference(_ a: UIImage?, _ b: UIImage?) -> String {
        guard let a = a?.cgImage, let b = b?.cgImage else { return "missing" }
        guard abs(a.width - b.width) <= 3, abs(a.height - b.height) <= 3 else {
            return "size \(a.width)x\(a.height) vs \(b.width)x\(b.height)"
        }
        func rgba(_ image: CGImage) -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: image.width * image.height * 4)
            let context = CGContext(data: &buffer, width: image.width, height: image.height, bitsPerComponent: 8,
                                    bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return buffer
        }
        let pa = rgba(a), pb = rgba(b)
        let w = min(a.width, b.width), h = min(a.height, b.height)
        var best = (over: Int.max, largest: 0)
        for ax in 0...(a.width - w) { for ay in 0...(a.height - h) { for bx in 0...(b.width - w) { for by in 0...(b.height - h) {
            var over = 0, largest = 0
            for y in 0..<h {
                for x in 0..<w {
                    let i = ((y + ay) * a.width + (x + ax)) * 4, j = ((y + by) * b.width + (x + bx)) * 4
                    var d = 0
                    for c in 0..<3 { d = max(d, abs(Int(pa[i + c]) - Int(pb[j + c]))) }
                    largest = max(largest, d)
                    if d > 24 { over += 1 }
                }
            }
            if over < best.over { best = (over, largest) }
        } } } }
        return "\(a.width)x\(a.height) vs \(b.width)x\(b.height), best alignment: pixels over 24: \(best.over) largest \(best.largest)"
    }
}
