import XCTest

/// What the iOS driver finds for each spelling of a decorative image, with
/// the driver's own predicates (jsonui-test-runner-ios AssertionExecutor,
/// fc50701: the `visible` assertion = exists && (isHittable ||
/// !frame.isEmpty); the `notVisible` assertion = !(exists && isHittable);
/// a `when` / `while` condition's notVisible = !isInstantlyVisible, which is
/// the visible assertion's predicate again, not the notVisible assertion's;
/// count over descendants(matching: .any).matching(identifier:)).
///
/// THE SEMANTICS THIS PINS (measured, iOS 18 simulator, Xcode 26.6): an
/// element hidden from VoiceOver — `.accessibilityHidden(true)`, which is how
/// an image with no alt that operates nothing is emitted, and how the
/// `hidden` attribute's invisible wrapper hides a view — stays in XCUITest's
/// tree (count 1, exists) and is never hittable. So for the SAME element
/// both `visible` and `notVisible` hold. A `notVisible` on such an element
/// cannot fail however the screen looks; `jsonui-test validate` names it
/// for a decorative image (INFO). The driver is deliberately not changed
/// here: notVisible reads "not hittable" as gone so that a view covered by
/// a sheet counts as not visible.
///
/// Opt-in, like the other probes: TEST_RUNNER_DECORATIVE_IMAGE_PROBE=1.
final class DecorativeImageProbeUITests: XCTestCase {
    private struct Row {
        let id: String
        let count: Int
        let visible: Bool
        let notVisible: Bool
        let label: String?
        /// `when: {notVisible: id}` / `while: {notVisible: id}` holds.
        var conditionNotVisible: Bool { !visible }
    }

    /// The measured table. `label` is what VoiceOver would be handed where
    /// the element is one (nil: not asserted).
    private let expected: [Row] = [
        Row(id: "img_plain", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "img_hidden", count: 1, visible: true, notVisible: true, label: nil),
        Row(id: "img_empty_label", count: 1, visible: true, notVisible: false, label: ""),
        Row(id: "img_labelled", count: 1, visible: true, notVisible: false, label: "Star"),
        Row(id: "hidden_attr", count: 1, visible: true, notVisible: true, label: nil),
        Row(id: "dyn_decorative", count: 1, visible: true, notVisible: true, label: nil),
        Row(id: "dyn_empty_alt", count: 1, visible: true, notVisible: true, label: nil),
        Row(id: "dyn_control", count: 1, visible: true, notVisible: false, label: "conformance_sample"),
        Row(id: "dyn_labelled", count: 1, visible: true, notVisible: false, label: "Sample"),
        Row(id: "img_absent", count: 0, visible: false, notVisible: true, label: nil),
        // An id on a container, as `jui build` emits it (cg_) and as the
        // dynamic runtime renders it (dyn_): around a decorative image, around
        // text and one, a Label, a tappable holding text, around one text,
        // two texts, an image with an alt. Every one is hittable where it is
        // on screen (iOS 18.6 and 26.4, 2026-09-26), so a `notVisible` on it
        // fails while it shows — unlike on the decorative image inside. The
        // driver's note that a SwiftUI container reports isHittable == false
        // (AssertionExecutor, `visible`) is not what these shapes do.
        Row(id: "cg_wrap_deco", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_wrap_deco", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "cg_wrap_text", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_wrap_text", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "cg_text", count: 1, visible: true, notVisible: false, label: "caption"),
        Row(id: "dyn_text", count: 1, visible: true, notVisible: false, label: "caption"),
        Row(id: "cg_tap_wrap", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_tap_wrap", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "cg_wrap_one_text", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_wrap_one_text", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "cg_wrap_two_text", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_wrap_two_text", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "cg_wrap_labelled", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_wrap_labelled", count: 1, visible: true, notVisible: false, label: nil),
    ]

    func testWhatTheDriverSeesOfEachSpelling() throws {
        guard ProcessInfo.processInfo.environment["DECORATIVE_IMAGE_PROBE"] == "1" else {
            throw XCTSkip("decorative-image probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-decorativeImageProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["deco_probe_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["deco_probe_decode_failed"].exists, "the dynamic layout did not decode")

        let window = app.windows.firstMatch.frame
        // The driver itself (UITests/Vendor, jsonui-test-runner-ios
        // XCUITestAssertionExecutor, byte-identical to fc50701), beside the
        // transcription below: a transcription that agrees with itself is not
        // the driver's answer.
        let driver = XCUITestAssertionExecutor(defaultTimeout: 0.3)
        func driverAssertionHolds(_ assertion: String, _ id: String) -> Bool {
            let json = #"{"assert": "\#(assertion)", "id": "\#(id)", "timeout": 300}"#
            guard let step = try? JSONDecoder().decode(TestStep.self, from: Data(json.utf8)) else {
                XCTFail("step did not decode: \(json)"); return false
            }
            return (try? driver.execute(step: step, in: app)) != nil
        }
        func driverConditionHolds(_ id: String) throws -> Bool {
            let json = #"{"notVisible": "\#(id)"}"#
            let condition = try JSONDecoder().decode(WhenCondition.self, from: Data(json.utf8))
            return try driver.evaluate(condition: condition, platform: "ios", in: app)
        }
        for row in expected {
            let query = app.descendants(matching: .any).matching(identifier: row.id)
            let element = query.firstMatch
            let exists = element.exists
            let hittable = exists && element.isHittable
            let frame = exists ? element.frame : .zero
            let visible = exists && (hittable || !frame.isEmpty)
            let notVisible = !(exists && hittable)
            let conditionNotVisible = !(exists && (hittable || !frame.isEmpty))
            let onScreen = exists && !frame.isEmpty && window.contains(frame)
            let driverVisible = driverAssertionHolds("visible", row.id)
            let driverNotVisible = driverAssertionHolds("notVisible", row.id)
            let driverCondition = try driverConditionHolds(row.id)
            print("DECO_PROBE id=\(row.id) count=\(query.count) exists=\(exists) hittable=\(hittable) " +
                  "label='\(exists ? element.label : "-")' visible=\(visible) notVisible=\(notVisible) " +
                  "conditionNotVisible=\(conditionNotVisible) onScreen=\(onScreen) " +
                  "driver(visible=\(driverVisible) notVisible=\(driverNotVisible) " +
                  "when.notVisible=\(driverCondition)) frame=\(frame)")
            XCTAssertEqual(query.count, row.count, "\(row.id) count")
            // A row that is there must be inside the window: an element
            // scrolled or pushed off screen is not hittable for that reason.
            XCTAssertEqual(onScreen, row.count > 0, "\(row.id) on screen")
            XCTAssertEqual(visible, row.visible, "\(row.id) visible")
            XCTAssertEqual(notVisible, row.notVisible, "\(row.id) notVisible")
            XCTAssertEqual(conditionNotVisible, row.conditionNotVisible, "\(row.id) condition notVisible")
            XCTAssertEqual(driverVisible, row.visible, "\(row.id) driver: visible")
            XCTAssertEqual(driverNotVisible, row.notVisible, "\(row.id) driver: notVisible")
            XCTAssertEqual(driverCondition, row.conditionNotVisible, "\(row.id) driver: when.notVisible")
            if let label = row.label { XCTAssertEqual(element.label, label, "\(row.id) label") }
        }
    }
}
