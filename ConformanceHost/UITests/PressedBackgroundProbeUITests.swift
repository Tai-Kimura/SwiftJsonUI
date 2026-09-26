import XCTest

/// tapBackground is the background while pressed, on every node with a tap
/// (onClick) and on a Button (jsonui-cli 1.9.0) — PressedBackgroundProbeView,
/// both paths: DynamicView and what sjui build emits.
///
/// Each node is held down near its top-left corner (inside a View's padding)
/// for a second; the probe samples its own pixel there during the touch and
/// after it. Then each is tapped once — the handler is still called — and the
/// ScrollView is swiped across its tappable item — it still scrolls, and the
/// swipe calls nothing.
///
/// Opt-in, like the other probes: TEST_RUNNER_PRESSED_BACKGROUND_PROBE=1.
final class PressedBackgroundProbeUITests: XCTestCase {
    private let pressed = ["pbView", "pbLabel", "pbEmpty", "pbScrollItem"]
    private let handler = ["pbView": "onView", "pbLabel": "onLabel", "pbEmpty": "onEmpty", "pbScrollItem": "onScrollItem"]

    private func field(_ text: String, _ key: String) -> String {
        guard let start = text.range(of: "\(key)[")?.upperBound,
              let end = text[start...].firstIndex(of: "]") else { return "" }
        return String(text[start..<end])
    }

    private func counts(_ text: String) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: field(text, "counts").split(separator: ",").compactMap { part in
            let kv = part.split(separator: "=", maxSplits: 1)
            return kv.count == 2 ? (String(kv[0]), Int(kv[1]) ?? -1) : nil
        })
    }

    func testThePressedColourShowsWhilePressedAndTheTapStillCalls() throws {
        guard ProcessInfo.processInfo.environment["PRESSED_BACKGROUND_PROBE"] == "1" else {
            throw XCTSkip("pressed background probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        for path in (ProcessInfo.processInfo.environment["PRESSED_PATHS"] ?? "dynamic,codegen").split(separator: ",").map(String.init) {
            run(path)
        }
    }

    private func run(_ path: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-pressedBackgroundProbe", "-pbPath", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["pb_ready"].waitForExistence(timeout: 15), "\(path): probe did not start")
        XCTAssertFalse(app.staticTexts["pb_decode_failed"].exists, "\(path): the layout did not decode")
        func element(_ id: String) -> XCUIElement {
            let e = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(e.waitForExistence(timeout: 5), "\(path) \(id) exists")
            return e
        }
        // Near the top-left corner — inside a View's padding. The item in the
        // scroll view is touched lower: iOS 26 softens a scroll view's top
        // edge (its content read 255/167/167 there, pressed and at rest alike
        // paler), which is the edge effect, not the node's colour.
        func corner(_ id: String) -> XCUICoordinate {
            element(id).coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: id == "pbScrollItem" ? 0.6 : 0.1))
        }
        sleep(1)
        let readout = { app.staticTexts["pb_readout"].label }

        // Held down: pressed colour during, the background after. The node
        // without a tap is the control: never pressed.
        let held = pressed.prefix(3) + ["pbNoTap", "pbScrollItem"]
        for id in held {
            corner(id).press(forDuration: 1.0)
            sleep(1)
        }
        let samples = field(readout(), "samples").split(separator: ",").map(String.init)
        print("PRESSED \(path) samples=\(samples)")
        XCTAssertEqual(samples.count, held.count * 2, "\(path): two samples per touch")
        for (i, id) in held.enumerated() where samples.count >= 2 * i + 2 {
            let during = samples[2 * i], after = samples[2 * i + 1]
            print("PRESSED \(path) \(id) \(during) \(after)")
            XCTAssertEqual(during, id == "pbNoTap" ? "d=blue" : "d=red", "\(path) \(id): while held")
            XCTAssertEqual(after, "a=blue", "\(path) \(id): after release")
        }

        // Tapped: each handler is called once more than before.
        let before = counts(readout())
        for id in pressed { corner(id).tap(); usleep(400_000) }
        sleep(1)
        let after = counts(readout())
        for id in pressed {
            let name = handler[id]!
            print("PRESSED \(path) \(id) calls before=\(before[name] ?? 0) after=\(after[name] ?? 0)")
            XCTAssertEqual((after[name] ?? 0) - (before[name] ?? 0), 1, "\(path) \(id): the tap calls its handler once")
        }

        // Swiped across the scroll view's tappable item: it scrolls, and the
        // swipe calls nothing.
        let item = element("pbScrollItem")
        let top = item.frame.minY
        let calls = counts(readout())["onScrollItem"] ?? 0
        element("pbScroll").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: element("pbScroll").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0)))
        sleep(1)
        print("PRESSED \(path) scroll item top \(top) -> \(item.frame.minY)")
        XCTAssertLessThan(item.frame.minY, top - 10, "\(path): the scroll view scrolls over a tappable item")
        XCTAssertEqual(counts(readout())["onScrollItem"] ?? 0, calls, "\(path): the swipe calls nothing")
        app.terminate()
    }
}
