import XCTest

/// What `userInteractionEnabled: false` and a bound `enabled` stop on a view
/// with a tap of its own (InteractionGateProbeView): per
/// attribute_definitions.json, `userInteractionEnabled` enables user
/// interaction and `enabled` enables the component, so under either gate
/// neither the view's own handler nor its child's is called. The rows with
/// no gate are the controls: they say the tap and the press reach.
///
/// Opt-in, like the other probes: TEST_RUNNER_INTERACTION_GATE_PROBE=1.
final class InteractionGateProbeUITests: XCTestCase {
    /// Handler calls expected after one tap (or press) on each element.
    private let calls: [String: Int] = [
        "parPlain": 1, "kidPlain": 1,
        "parUieFalse": 0, "kidUieFalse": 0,
        // the parent as emitted before, `.allowsHitTesting` inside its own
        // tap: its handler ran for the padding tap and the one in the child's
        // frame, and the child's did not
        "parUieOld": 2, "kidUieOld": 0,
        "parUieBound": 0, "kidUieBound": 0,
        "parEnBoundNoId": 0, "kidEnBoundNoId": 0,
        "lblUieFalse": 0, "lblEnBoundNoId": 0,
        "lpPlain": 1, "lpUieFalse": 0,
        "dynViewPlain": 1, "dynViewUieFalse": 0, "dynViewUieBound": 0, "dynViewEnBound": 0,
        "dynLblUieFalse": 0,
        "dynLpPlain": 1, "dynLpUieFalse": 0,
        "dynParUieFalse": 0, "dynKidUieFalse": 0,
    ]
    /// Whether each Switch switched after one tap.
    private let switched: [String: Bool] = [
        "swUiePlain": true, "swUieFalse": false, "dynSwPlain": true, "dynSwUieFalse": false,
    ]

    func testTheGatesStopTheViewsOwnHandler() throws {
        guard ProcessInfo.processInfo.environment["INTERACTION_GATE_PROBE"] == "1" else {
            throw XCTSkip("interaction gate probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-interactionGateProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["gate_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["gate_decode_failed"].exists, "the dynamic layout did not decode")
        let window = app.windows.firstMatch.frame
        let origin = app.coordinate(withNormalizedOffset: .zero)

        func frame(_ query: XCUIElementQuery, _ name: String) -> CGRect {
            let e = query.firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 5), "\(name) exists")
            XCTAssertTrue(window.contains(e.frame), "\(name) on screen: \(e.frame)")
            return e.frame
        }
        func byId(_ id: String) -> CGRect {
            frame(app.descendants(matching: .any).matching(identifier: id), id)
        }
        func byLabel(_ label: String) -> CGRect {
            frame(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)), label)
        }
        func tap(_ r: CGRect) { origin.withOffset(CGVector(dx: r.midX, dy: r.midY)).tap() }
        func press(_ r: CGRect) {
            origin.withOffset(CGVector(dx: r.midX, dy: r.midY)).press(forDuration: 1.2)
        }

        // A parent is tapped in its padding, 8 pt right of its child (the
        // parent without an id is found through its child).
        for name in ["Plain", "UieFalse", "UieBound", "EnBoundNoId", "UieOld"] {
            let kid = byId("kid\(name)")
            origin.withOffset(CGVector(dx: kid.maxX + 8, dy: kid.midY)).tap()
            tap(kid)
        }
        tap(byLabel("lblUieFalse"))
        tap(byLabel("lblEnBoundNoId"))
        press(byId("lpPlain"))
        press(byId("lpUieFalse"))
        for id in ["dynViewPlain", "dynViewUieFalse", "dynViewUieBound", "dynViewEnBound"] {
            tap(byId(id))
        }
        tap(byLabel("dynLblUieFalse"))
        press(byId("dynLpPlain"))
        press(byId("dynLpUieFalse"))
        let dynKid = byId("dynKidUieFalse")
        origin.withOffset(CGVector(dx: dynKid.maxX + 8, dy: dynKid.midY)).tap()
        tap(dynKid)
        for id in ["swUiePlain", "swUieFalse", "dynSwPlain", "dynSwUieFalse"] { tap(byId(id)) }
        sleep(1)

        let text = app.staticTexts["gate_readout"].label
        print("GATE_PROBE readout=\(text)")
        guard let start = text.range(of: "counts[")?.upperBound,
              let end = text[start...].firstIndex(of: "]") else {
            return XCTFail("no counts in the readout: \(text)")
        }
        var counts: [String: Int] = [:]
        for part in text[start..<end].split(separator: ",") {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { counts[String(kv[0])] = Int(kv[1]) }
        }
        let unknown = Set(counts.keys).subtracting(calls.keys)
        XCTAssertTrue(unknown.isEmpty, "counted but not expected: \(unknown.sorted())")
        for (name, want) in calls.sorted(by: { $0.key < $1.key }) {
            let got = counts[name] ?? 0
            print("GATE_PROBE \(name) calls=\(got) want=\(want)")
            XCTAssertEqual(got, want, "\(name) handler calls")
        }
        guard let swStart = text.range(of: "sw[")?.upperBound,
              let swEnd = text[swStart...].firstIndex(of: "]") else { return XCTFail("no sw in the readout") }
        var sw: [String: String] = [:]
        for part in text[swStart..<swEnd].split(separator: ",") {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { sw[String(kv[0])] = String(kv[1]) }
        }
        for (name, want) in switched.sorted(by: { $0.key < $1.key }) {
            print("GATE_PROBE \(name) switched=\(sw[name] ?? "nil") want=\(want)")
            XCTAssertEqual(sw[name], "\(want)", "\(name) switched")
        }
    }
}
