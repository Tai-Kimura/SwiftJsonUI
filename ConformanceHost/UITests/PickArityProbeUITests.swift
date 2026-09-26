import XCTest

/// What a SelectBox's onValueChange is handed, by the parameters the data
/// declares for it (PickArityProbeView; 4f's ruling on
/// control-onclick-is-called-differently-on-every-path, 1.9.0), on both paths:
/// `(String)` the picked item, even with selectedIndex bound; `(String, Int)`
/// the viewId and the index; `(String, String)` the viewId and the item — each
/// over an item binding, an index binding and nothing bound. A date picker's
/// `(String)` and `(String, String)` take the date; one declared
/// `(String, Int)` is not called (a date has no index). A box without an id is
/// `selectBox_<its position>`.
///
/// Every box is picked once — its second item, a date's 3rd day — and the
/// calls it made are read from the log: exactly the one expected.
///
/// Opt-in, like the other probes: TEST_RUNNER_PICK_ARITY_PROBE=1.
final class PickArityProbeUITests: XCTestCase {
    private var app: XCUIApplication!

    private let boxes: [(box: String, pick: String, call: String)] = [
        ("sbSi", "Si2", "pSi(Si2)"), ("sbSx", "Sx2", "pSx(Sx2)"), ("sbSn", "Sn2", "pSn(Sn2)"),
        ("sbIi", "Ii2", "pIi(sbIi,1)"), ("sbIx", "Ix2", "pIx(sbIx,1)"), ("sbIn", "In2", "pIn(sbIn,1)"),
        ("sbNi", "Ni2", "pNi(sbNi,Ni2)"), ("sbNx", "Nx2", "pNx(sbNx,Nx2)"), ("sbNn", "Nn2", "pNn(sbNn,Nn2)"),
        ("sbDS", "3", "dS(2026-01-03)"), ("sbDN", "3", "dN(sbDN,2026-01-03)"),
        ("anonI", "aI2", "aI(selectBox_0_11,1)"), ("anonN", "aN2", "aN(selectBox_0_12,aN2)"),
        // A date has no index: a handler that takes one is not called.
        ("sbDI", "3", ""),
    ]

    func testEachDeclarationIsHandedWhatItAsksFor() throws {
        guard ProcessInfo.processInfo.environment["PICK_ARITY_PROBE"] == "1" else {
            throw XCTSkip("pick arity probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let paths = (ProcessInfo.processInfo.environment["PICK_ARITY_PATHS"] ?? "dynamic,codegen").split(separator: ",").map(String.init)
        for path in paths { run(path) }
    }

    /// A box by its id, or — without one — by the item it shows (`anonI` →
    /// `aI1`, its literal selectedIndex 0).
    private func box(_ name: String) -> XCUIElement {
        guard name.hasPrefix("anon") else {
            return app.descendants(matching: .any).matching(identifier: name).firstMatch
        }
        let shown = "a" + name.dropFirst(4) + "1"
        return app.buttons.matching(NSPredicate(format: "label CONTAINS %@", shown)).firstMatch
    }

    private func calls() -> [String] {
        let readout = app.staticTexts["pa_readout"].label
        guard let start = readout.range(of: "calls[")?.upperBound,
              let end = readout.range(of: "]", options: .backwards)?.lowerBound, start <= end else { return [] }
        return readout[start..<end].split(separator: "|").map(String.init)
    }

    private func run(_ path: String) {
        app = XCUIApplication()
        app.launchArguments = ["-pickArityProbe", "-paPath", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["pa_ready"].waitForExistence(timeout: 15), "\(path): probe did not start")
        XCTAssertFalse(app.staticTexts["pa_decode_failed"].exists, "\(path): the layout did not decode")
        XCTAssertTrue(box("sbSi").waitForExistence(timeout: 5), "\(path): the boxes are there")
        sleep(1)

        for (name, pick, call) in boxes {
            let before = calls().count
            box(name).tap()
            let isDate = name.hasPrefix("sbD")
            let wheel = isDate ? app.pickerWheels.element(boundBy: 1) : app.pickerWheels.firstMatch
            if wheel.waitForExistence(timeout: 5) {
                wheel.adjust(toPickerWheelValue: pick)
                app.buttons["Done"].tap()
            } else {
                XCTFail("\(path) \(name): the picker did not open")
            }
            sleep(1)
            let made = Array(calls().dropFirst(before))
            print("PICKARITY \(path) \(name) calls=\(made.joined(separator: "|"))")
            XCTAssertEqual(made, call.isEmpty ? [] : [call], "\(path) \(name): onValueChange is handed")
        }
        print("PICKARITY \(path) readout=\(app.staticTexts["pa_readout"].label)")
        app.terminate()
    }
}
