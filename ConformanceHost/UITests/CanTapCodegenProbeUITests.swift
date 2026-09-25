import XCTest

/// What `canTap` stops on the codegen types that call the onClick handler
/// from their own operation, and on an Image (CanTapCodegenProbeView): the
/// handler's call, and not the operation — the radio still selects, the
/// checkbox still checks.
///
/// A shut gate (`false`, or a binding resolving false) makes no call. An open
/// binding makes the calls no gate makes: how many that is — a Radio calls
/// from its selection and from the tap on its text — is recorded, and the
/// open row is held to it.
///
/// Opt-in, like the other probes: TEST_RUNNER_CANTAP_CODEGEN_PROBE=1.
final class CanTapCodegenProbeUITests: XCTestCase {
    private let kinds = ["Icl", "Radio", "Check", "Img"]
    private let gates = ["None", "False", "BClosed", "BOpen"]

    private func pairs(_ text: String, _ key: String) -> [String: String] {
        guard let start = text.range(of: "\(key)[")?.upperBound,
              let end = text[start...].firstIndex(of: "]") else { return [:] }
        return Dictionary(uniqueKeysWithValues: text[start..<end].split(separator: ",").compactMap { part in
            let kv = part.split(separator: "=", maxSplits: 1)
            return kv.count == 2 ? (String(kv[0]), String(kv[1])) : nil
        })
    }

    func testCanTapStopsTheCallNotTheOperation() throws {
        guard ProcessInfo.processInfo.environment["CANTAP_CODEGEN_PROBE"] == "1" else {
            throw XCTSkip("canTap codegen probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-canTapCodegenProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["cg_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        let window = app.windows.firstMatch.frame
        let origin = app.coordinate(withNormalizedOffset: .zero)
        func frame(_ id: String) -> CGRect {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 5), "\(id) exists")
            XCTAssertTrue(window.contains(e.frame), "\(id) on screen: \(e.frame)")
            print("CG_PROBE enabled \(id) isEnabled=\(e.isEnabled) type=\(e.elementType.rawValue)")
            // `canTap` is not `enabled` (CanTapGateProbeUITests).
            XCTAssertTrue(e.isEnabled, "\(id) reads as enabled")
            return e.frame
        }
        func tap(_ x: CGFloat, _ y: CGFloat) { origin.withOffset(CGVector(dx: x, dy: y)).tap() }

        for g in gates {
            let icl = frame("cgIcl\(g)"); tap(icl.midX, icl.midY)
            let img = frame("cgImg\(g)"); tap(img.midX, img.midY)
            let check = frame("cgCheck\(g)"); tap(check.midX, check.midY)
            // A Radio row: its glyph (its selection) at the left, its text at the right.
            let radio = frame("cgRadio\(g)")
            tap(radio.minX + 8, radio.midY)
            tap(radio.maxX - 4, radio.midY)
        }
        sleep(1)
        let text = app.staticTexts["cg_readout"].label
        print("CG_PROBE readout=\(text)")
        let counts = pairs(text, "counts"), radios = pairs(text, "radios"), checks = pairs(text, "checks")
        func calls(_ name: String) -> Int { Int(counts[name] ?? "0") ?? -1 }
        for kind in kinds {
            for g in gates { print("CG_PROBE \(kind)\(g) calls=\(calls("\(kind)\(g)"))") }
            XCTAssertGreaterThan(calls("\(kind)None"), 0, "\(kind): the ungated tap calls the handler")
            XCTAssertEqual(calls("\(kind)False"), 0, "\(kind) under canTap false")
            XCTAssertEqual(calls("\(kind)BClosed"), 0, "\(kind) under a shut binding")
            XCTAssertEqual(calls("\(kind)BOpen"), calls("\(kind)None"), "\(kind) under an open binding calls as no gate does")
        }
        for g in gates {
            XCTAssertEqual(radios["selectedGcgradio\(g.lowercased())"], "cgRadio\(g)", "radio \(g) is selected")
            XCTAssertEqual(checks["cgCheck\(g)IsOn"], "true", "checkbox \(g) is checked")
        }
    }
}
