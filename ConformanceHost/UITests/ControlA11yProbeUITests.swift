import XCTest

/// ControlA11yProbeView: what VoiceOver reads off Dynamic controls. A Button and
/// a TextField are read by their accessibilityLabel (a Dynamic Button and
/// TextField ran a chain without the controlAccessibility stage, so neither was:
/// jsonui-cli ticket sjui-dynamic-button-textfield-skip-control-accessibility),
/// and a Button, a tappable View and a tappable IconLabel bound to `isMust` are
/// selected while it is true and not once it is false (ticket
/// jui-view-accessibility-selected-state-missing).
final class ControlA11yProbeUITests: XCTestCase {
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func testControlsAreReadByTheirLabelAndSelectedState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-controlA11yProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ca_ready"].waitForExistence(timeout: 15), "probe did not start")
        let field = app.textFields["ca_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "the field is not drawn")

        XCTAssertEqual(element(app, "ca_named").label, "Open the second image")
        XCTAssertEqual(field.label, "Search the catalog")

        for id in ["ca_must", "ca_maybe", "ca_icon"] {
            XCTAssertTrue(element(app, id).isSelected, "\(id): selected while isMust is true")
        }
        app.buttons["ca_toggle"].tap()
        for id in ["ca_must", "ca_maybe", "ca_icon"] {
            let e = element(app, id)
            let gone = NSPredicate(format: "isSelected == false")
            let wait = XCTNSPredicateExpectation(predicate: gone, object: e)
            XCTAssertEqual(XCTWaiter.wait(for: [wait], timeout: 5), .completed, "\(id): not selected once isMust is false")
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "control-a11y"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
