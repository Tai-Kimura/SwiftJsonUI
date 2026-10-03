import XCTest

/// AspectFillHitProbeView: a tap inside a TextField, in the 22pt an AspectFill
/// image beside it overflows (drawn 60 wide in a 16pt spine), reaches the
/// field — as it does in the AspectFit control row — and XCUITest calls the
/// field hittable. Prints each row's frames and readings, so a red names what
/// covered the field.
final class AspectFillHitProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func focused(_ e: XCUIElement) -> Bool {
        (e.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }

    /// (field took focus, field hittable) for one row, tapped 8pt inside the
    /// field's right edge — inside the fill image's overflow.
    private func probe(_ app: XCUIApplication, _ p: String, _ row: String) -> (Bool, Bool) {
        let field = element(app, "\(p)_afh_\(row)_field")
        XCTAssertTrue(field.waitForExistence(timeout: 10), "\(row): no field")
        let spine = element(app, "\(p)_afh_\(row)_spine")
        let hittable = field.isHittable
        let f = field.frame
        let point = CGPoint(x: f.maxX - 8, y: f.midY)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: point.x, dy: point.y)).tap()
        let took = field.waitForExistence(timeout: 1) && focused(field)
        let after = element(app, "\(p)_afh_\(row)_after").frame
        print("[AspectFillHit] \(p) \(row): field=\(f) spine=\(spine.frame) after.minX=\(after.minX) tap=\(point) hittable=\(hittable) focused=\(took)")
        // The spine is laid out 16 wide: the label after it starts at its edge.
        XCTAssertEqual(after.minX, f.maxX + 16, accuracy: 1, "\(row): the spine is not laid out 16 wide")
        // Leave no keyboard and no focus for the next row.
        if took { app.staticTexts["afh_ready"].tap() }
        return (took, hittable)
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["afh_ready"].waitForExistence(timeout: 15), "probe did not start")
        let fit = probe(app, p, "fit")
        let fill = probe(app, p, "fill")
        let narrowFit = probe(app, p, "narrowfit")
        let narrow = probe(app, p, "narrow")
        XCTAssertTrue(fit.0, "control: the AspectFit row's field did not take the tap")
        XCTAssertTrue(narrowFit.0, "control: the 30-wide AspectFit row's field did not take the tap")
        XCTAssertTrue(fill.0, "the tap 8pt inside the field, in the AspectFill image's overflow, did not reach the field")
        XCTAssertTrue(narrow.0, "the tap inside the 30-wide field, in the overflow, did not reach the field")
        // NOT asserted: isHittable. Measured 2026-10-03 without the fix, the
        // 30-wide field (its centre inside the overflow) still read hittable
        // here — XCUITest did not see what took its taps — while a consumer's
        // iPad layout read "covered". The tap is the discriminating reading;
        // hittable is printed above for the record.
        _ = (fill.1, narrow.1, narrowFit.1)
    }

    func testDynamicAspectFillTakesNoTouchOutsideItsFrame() throws {
        try XCTSkipIf(codegenHost, "the Dynamic half runs in the Dynamic host")
        run(prefix: "dyn", argument: "-aspectFillHitProbe")
    }

    func testGeneratedAspectFillTakesNoTouchOutsideItsFrame() throws {
        try XCTSkipUnless(codegenHost, "the generated half runs in the codegen host")
        run(prefix: "cg", argument: "-aspectFillHitProbeCodegen")
    }
}
