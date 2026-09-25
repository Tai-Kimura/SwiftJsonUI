import XCTest

/// What the iOS driver finds for each spelling of a decorative image, with
/// the driver's own predicates (jsonui-test-runner-ios AssertionExecutor:
/// visible = exists && (isHittable || !frame.isEmpty); notVisible =
/// !(exists && isHittable); count over
/// descendants(matching: .any).matching(identifier:)).
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

        for row in expected {
            let query = app.descendants(matching: .any).matching(identifier: row.id)
            let element = query.firstMatch
            let exists = element.exists
            let hittable = exists && element.isHittable
            let frame = exists ? element.frame : .zero
            let visible = exists && (hittable || !frame.isEmpty)
            let notVisible = !(exists && hittable)
            print("DECO_PROBE id=\(row.id) count=\(query.count) exists=\(exists) hittable=\(hittable) " +
                  "label='\(exists ? element.label : "-")' visible=\(visible) notVisible=\(notVisible)")
            XCTAssertEqual(query.count, row.count, "\(row.id) count")
            XCTAssertEqual(visible, row.visible, "\(row.id) visible")
            XCTAssertEqual(notVisible, row.notVisible, "\(row.id) notVisible")
            if let label = row.label { XCTAssertEqual(element.label, label, "\(row.id) label") }
        }
    }
}
