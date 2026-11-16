import XCTest

/// What the iOS driver finds for each spelling of a decorative image, with
/// the driver's own predicates (jsonui-test-runner-ios 9a191dd: `visible` =
/// some of the element, at least 1pt each way, inside the app's frame and
/// every scroll container above it; `notVisible` = exactly its negation; a
/// `when` / `while` condition's notVisible = the same negation; count over
/// descendants(matching: .any).matching(identifier:)).
///
/// THE SEMANTICS THIS PINS: an element hidden from VoiceOver —
/// `.accessibilityHidden(true)`, which is how an image with no alt that
/// operates nothing is emitted — stays in XCUITest's tree (count 1, exists)
/// and is never hittable, and the driver does not ask about hit-testing: on
/// screen, it is `visible` and its `notVisible` fails. That is Android's
/// answer, the baseline: a decorative image (contentDescription = null with
/// its testTag) is found by resource-id (KotlinJsonUI conformance-host
/// DecorativeImageProbeTest, API 35).
///
/// Until 9a191dd the driver's notVisible read "not hittable" as gone, so for
/// these elements both `visible` and `notVisible` held and a `notVisible` on
/// a decorative image could not fail. That was kept so that a view under a
/// sheet counted as not visible; the driver now answers that from the
/// accessibility snapshot (what is under a modal is not in it), so hit-
/// testing is no longer asked. (`hidden_attr` writes the `hidden` wrapper's
/// modifiers with the identifier OUTSIDE them, which neither the dynamic
/// runtime nor `jui build` emits — both keep a hidden view's identifier
/// inside, where XCUITest does not find it at all.)
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
        Row(id: "img_hidden", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "img_empty_label", count: 1, visible: true, notVisible: false, label: ""),
        Row(id: "img_labelled", count: 1, visible: true, notVisible: false, label: "Star"),
        Row(id: "hidden_attr", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_decorative", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_empty_alt", count: 1, visible: true, notVisible: false, label: nil),
        Row(id: "dyn_control", count: 1, visible: true, notVisible: false, label: "conformance_sample"),
        Row(id: "dyn_labelled", count: 1, visible: true, notVisible: false, label: "Sample"),
        Row(id: "img_absent", count: 0, visible: false, notVisible: true, label: nil),
        // An id on a container, as `jui build` emits it (cg_) and as the
        // dynamic runtime renders it (dyn_): around a decorative image, around
        // text and one, a Label, a tappable holding text, around one text,
        // two texts, an image with an alt. Every one is hittable where it is
        // on screen (iOS 18.6 and 26.4, 2026-09-26), and on screen each is
        // `visible` and its `notVisible` fails — as the decorative image
        // inside does now (it is not hittable, which the driver no longer
        // asks).
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
            // In the viewport: at least 1pt each way of the frame inside the
            // window (no row sits in a scroll container).
            let shown = exists ? frame.intersection(window) : .null
            let visible = !shown.isNull && shown.width >= 1 && shown.height >= 1
            let notVisible = !visible
            let conditionNotVisible = !visible
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
