import XCTest

/// What `canTap` stops (CanTapGateProbeView): the onClick / onclick
/// handler's call, and nothing else — not a child's tap, not a control's own
/// operation. The line comes from attribute_definitions.json common.canTap
/// ("false … turns onClick / onclick off"); a control's own operation is
/// `enabled`'s.
///
/// Opt-in, like the other probes: TEST_RUNNER_CANTAP_GATE_PROBE=1.
final class CanTapGateProbeUITests: XCTestCase {
    /// Handler calls expected after one tap on each element.
    private let calls: [String: Int] = [
        // codegen: the gate shut takes the parent's tap away, not the child's
        "par_closed": 0, "kid_closed": 1, "par_open": 1, "kid_open": 1,
        "sw_closed": 0,
        // the parent's shape (6ab928bf, `.allowsHitTesting(c)` inside the
        // gesture): under the shut gate the parent's tap still fired — for
        // the padding tap and for the one in the child's frame — and the
        // child's did not
        "par_old": 2, "kid_old": 0,
        // dynamic: none / false / bound false / bound true
        "dyn_btn_none": 1, "dyn_btn_false": 0, "dyn_btn_bclosed": 0, "dyn_btn_bopen": 1,
        "dyn_icl_none": 1, "dyn_icl_false": 0, "dyn_icl_bclosed": 0, "dyn_icl_bopen": 1,
        "dyn_radio_none": 1, "dyn_radio_false": 0, "dyn_radio_bclosed": 0, "dyn_radio_bopen": 1,
        "dyn_check_none": 1, "dyn_check_false": 0, "dyn_check_bclosed": 0, "dyn_check_bopen": 1,
    ]

    private func readout(_ app: XCUIApplication) -> String {
        app.staticTexts["cantap_readout"].label
    }

    /// `name=value` pairs of one bracket of the readout.
    private func pairs(_ text: String, _ key: String) -> [String: String] {
        guard let start = text.range(of: "\(key)[")?.upperBound,
              let end = text[start...].firstIndex(of: "]") else { return [:] }
        return Dictionary(uniqueKeysWithValues: text[start..<end].split(separator: ",").compactMap { part in
            let kv = part.split(separator: "=", maxSplits: 1)
            return kv.count == 2 ? (String(kv[0]), String(kv[1])) : nil
        })
    }

    func testCanTapStopsTheHandlerAndNothingElse() throws {
        guard ProcessInfo.processInfo.environment["CANTAP_GATE_PROBE"] == "1" else {
            throw XCTSkip("canTap gate probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-canTapGateProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["cantap_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["cantap_decode_failed"].exists, "the dynamic layout did not decode")
        let window = app.windows.firstMatch.frame

        func element(_ id: String) -> XCUIElement {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 5), "\(id) exists")
            XCTAssertTrue(window.contains(e.frame), "\(id) on screen: \(e.frame)")
            return e
        }
        // `canTap` is not `enabled`: under every gate XCUITest reads the
        // node as enabled, as TalkBack's tree does on Android (KotlinJsonUI
        // conformance-host CanTapGateProbeTest). iOS read them so before the
        // fix too; Compose read a gated clickable as disabled.
        var ids = ["par_closed", "par_open", "par_old", "sw_closed", "sw_open", "sw_plain"]
        for kind in ["btn", "icl", "radio", "check"] {
            for g in ["none", "false", "bclosed", "bopen"] { ids.append("dyn_\(kind)_\(g)") }
        }
        for id in ids {
            let e = element(id)
            print("CANTAP_PROBE enabled \(id) isEnabled=\(e.isEnabled) type=\(e.elementType.rawValue)")
            XCTAssertTrue(e.isEnabled, "\(id) reads as enabled")
        }
        // A parent is tapped in its padding, 8 pt right of its child: the
        // frame XCUITest reports for the parent's accessibility container is
        // its child's, so a tap inside that frame lands on the child.
        let origin = app.coordinate(withNormalizedOffset: .zero)
        for state in ["closed", "open", "old"] {
            let kid = element("kid_\(state)").frame
            _ = element("par_\(state)")
            origin.withOffset(CGVector(dx: kid.maxX + 8, dy: kid.midY)).tap()
        }
        for id in ["kid_closed", "kid_open", "kid_old", "sw_closed", "sw_open", "sw_plain"] {
            element(id).tap()
        }
        for kind in ["btn", "icl", "radio", "check"] {
            for g in ["none", "false", "bclosed", "bopen"] {
                element("dyn_\(kind)_\(g)").tap()
            }
        }
        sleep(1)
        let text = readout(app)
        print("CANTAP_PROBE readout=\(text)")
        let counts = pairs(text, "counts")
        for (name, want) in calls.sorted(by: { $0.key < $1.key }) {
            let got = Int(counts[name] ?? "0") ?? -1
            print("CANTAP_PROBE \(name) calls=\(got) want=\(want)")
            XCTAssertEqual(got, want, "\(name) handler calls")
        }
        for name in ["sw_open", "sw_plain"] {
            print("CANTAP_PROBE \(name) calls=\(counts[name] ?? "0") (recorded, not asserted)")
        }
        // The controls' own operation happens whatever the gate says.
        let sw = pairs(text, "sw"), groups = pairs(text, "groups"), checks = pairs(text, "checks")
        XCTAssertEqual(sw["closed"], "true", "a Switch under a shut gate still switches")
        XCTAssertEqual(sw["open"], "true", "a Switch under an open gate switches")
        XCTAssertEqual(sw["plain"], "true", "a Switch with no gate switches")
        for g in ["none", "false", "bclosed", "bopen"] {
            XCTAssertEqual(groups["grp_\(g)"], "dyn_radio_\(g)", "radio \(g) is selected")
            XCTAssertEqual(checks["chk_\(g)"], "true", "checkbox \(g) is checked")
        }
    }
}
