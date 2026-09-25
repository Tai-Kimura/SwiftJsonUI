import XCTest

/// Which events reach an Image and a NetworkImage in the Dynamic runtime,
/// read the way a user and the driver meet them: the element type XCUITest
/// reports, and how many times a tap, a long press or an appearance called
/// the handler (ImageEventsProbeView shows each count as text the test reads).
///
/// Measured before the fix (SwiftJsonUI d330443, iOS 18.6 simulator, Xcode
/// 26.6): every NetworkImage row read an `image` that no event reached, and
/// Image reached only `onClick` — on the fitted picture, not its box — while
/// codegen emitted all of them. The table below is the fixed runtime, read
/// the same on iOS 18.6 and iOS 26.4.
///
/// Opt-in, like the other probes: TEST_RUNNER_IMAGE_EVENTS_PROBE=1.
final class ImageEventsProbeUITests: XCTestCase {
    private enum Act { case tap, edgeTap, longPress, none }

    private struct Row {
        let id: String
        let act: Act
        let type: XCUIElement.ElementType
        let count: Int
    }

    private let expected: [Row] = [
        Row(id: "ni_tap", act: .tap, type: .button, count: 1),
        Row(id: "ni_gated", act: .tap, type: .image, count: 0),
        Row(id: "ni_long", act: .longPress, type: .image, count: 1),
        Row(id: "ni_appear", act: .none, type: .image, count: 1),
        Row(id: "img_tap", act: .tap, type: .button, count: 1),
        Row(id: "img_selector", act: .tap, type: .button, count: 1),
        // The box is 160x40, the picture fitted in it 40x40 in the middle: a
        // tap near the box's leading edge lands outside the picture, inside
        // the box codegen's `.contentShape(Rectangle())` makes tappable.
        Row(id: "img_edge", act: .edgeTap, type: .button, count: 1),
        Row(id: "img_long", act: .longPress, type: .image, count: 1),
        Row(id: "img_appear", act: .none, type: .image, count: 1),
    ]

    func testWhichEventsReachEachImage() throws {
        guard ProcessInfo.processInfo.environment["IMAGE_EVENTS_PROBE"] == "1" else {
            throw XCTSkip("image events probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-imageEventsProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["image_events_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["image_events_decode_failed"].exists, "the dynamic layout did not decode")

        for row in expected {
            let element = app.descendants(matching: .any).matching(identifier: row.id).firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(row.id) not found")
            switch row.act {
            case .tap:
                element.tap()
            case .edgeTap:
                app.descendants(matching: .any).matching(identifier: "img_edge_box").firstMatch
                    .coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5)).tap()
            case .longPress:
                element.press(forDuration: 1.2)
            case .none:
                break
            }
            let counter = app.staticTexts["count_\(row.id)"]
            // An appearance may be reported more than once; one is what it
            // takes to say the handler is attached.
            let deadline = Date().addingTimeInterval(row.count > 0 ? 3 : 1)
            var count = Int(counter.label) ?? -1
            while count < row.count && Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                count = Int(counter.label) ?? -1
            }
            print("IMAGE_EVENTS id=\(row.id) act=\(row.act) type=\(element.elementType.rawValue) " +
                  "(button=\(XCUIElement.ElementType.button.rawValue), image=\(XCUIElement.ElementType.image.rawValue)) count=\(count)")
            XCTAssertEqual(element.elementType, row.type, "\(row.id) elementType")
            if row.act == .none {
                XCTAssertGreaterThanOrEqual(count, row.count, "\(row.id) calls")
            } else {
                XCTAssertEqual(count, row.count, "\(row.id) calls")
            }
        }
    }
}
