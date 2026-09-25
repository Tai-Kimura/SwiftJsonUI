import XCTest

/// What XCUITest reads as `isEnabled` on a disabled container with an id, as
/// `jui build` emits it with and without `responsive`
/// (ResponsiveDisabledProbeView). The driver's `disabled` assertion is
/// `!element.isEnabled` (jsonui-test-runner-ios AssertionExecutor), so a
/// container read as enabled while it is disabled fails that assertion.
///
/// A responsive container emitted `.disabled` only inside its `responsiveN`
/// wrapper, outside the accessibility element the identifier forms, and XCUITest
/// read it as enabled (resp_old). The fix emits `.disabled` again after the
/// identifier, as the plain path does (resp_new, plain_new).
///
/// Opt-in, like the other probes: TEST_RUNNER_RESPONSIVE_DISABLED_PROBE=1.
final class ResponsiveDisabledProbeUITests: XCTestCase {
    private let expected: [(id: String, isEnabled: Bool)] = [
        ("plain_new", false),
        ("resp_old", true),      // the defect: disabled, read as enabled
        ("resp_new", false),
        ("plain_enabled", true), // control: an enabled container reads as enabled
        ("tap_plain", false),
        ("tap_resp_old", false),
        ("tap_resp_new", false),
    ]

    func testWhatXCUITestReadsAsEnabled() throws {
        guard ProcessInfo.processInfo.environment["RESPONSIVE_DISABLED_PROBE"] == "1" else {
            throw XCTSkip("responsive disabled probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-responsiveDisabledProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["resp_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        let window = app.windows.firstMatch.frame
        for row in expected {
            let element = app.descendants(matching: .any).matching(identifier: row.id).firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(row.id) exists")
            print("RESP_PROBE id=\(row.id) isEnabled=\(element.isEnabled) type=\(element.elementType.rawValue) " +
                  "onScreen=\(window.contains(element.frame)) frame=\(element.frame)")
            XCTAssertTrue(window.contains(element.frame), "\(row.id) on screen")
            XCTAssertEqual(element.isEnabled, row.isEnabled, "\(row.id) isEnabled")
        }
    }
}
