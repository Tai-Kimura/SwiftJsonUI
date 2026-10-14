// Scratch probe (not committed).
import XCTest

final class HiddenToggleProbeUITests: XCTestCase {
    private let wrapped = ["htp_wrapper", "htp_reactive_vis", "htp_reactive_hidden"]

    private func state(_ app: XCUIApplication, _ phase: String) -> [String: (Bool, Bool)] {
        sleep(1)
        var out: [String: (Bool, Bool)] = [:]
        for id in wrapped + ["htp_opacity0"] {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            let v = ViewportVisibility.isVisible(id: id, in: app)
            let kids = e.exists ? e.descendants(matching: .any).allElementsBoundByIndex.map { "\($0.elementType.rawValue):\($0.label)" }.joined(separator: "|") : "-"
            print("HTP phase=\(phase) id=\(id) exists=\(e.exists) visible=\(v) label='\(e.exists ? e.label : "-")' kids=\(kids)")
            out[id] = (e.exists, v)
        }
        return out
    }

    func testToggle() {
        let app = XCUIApplication()
        app.launchArguments = ["-hiddenToggleProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["htp_ready"].waitForExistence(timeout: 15))
        let s1 = state(app, "hidden")
        for id in wrapped { XCTAssertEqual(s1[id]?.0, false, "\(id) hidden: not found") }
        XCTAssertEqual(s1["htp_opacity0"]?.1, true, "opacity 0 stays visible")
        app.buttons["htp_toggle"].tap()
        let s2 = state(app, "shown")
        for id in wrapped { XCTAssertEqual(s2[id]?.1, true, "\(id) shown: found and visible") }
        app.buttons["htp_toggle"].tap()
        let s3 = state(app, "hidden_again")
        for id in wrapped { XCTAssertEqual(s3[id]?.0, false, "\(id) hidden again: not found") }
    }
}
