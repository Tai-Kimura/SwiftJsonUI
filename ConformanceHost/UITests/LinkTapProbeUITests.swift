import XCTest

/// An outer onClick and a Label's links on iOS (LinkTapProbeView; 4f ruling on
/// kjui-linkable-label-drops-onclick-and-user-interaction, jsonui-cli 1.9.0):
/// a tap on a link calls the link only, and a tap elsewhere on the Label calls
/// the Label's onClick — on both paths, for a detected URL and for a range
/// with its own onClick. Measured on Compose (they coexist); this asks the
/// same of the `.onTapGesture` over PartialAttributedText.
///
/// The link is tapped where XCUITest reports it (the Label's link element),
/// and "elsewhere" is the Label's trailing end, past the link. A detected URL
/// is taken as opened when Safari comes to the front (the Label's own
/// OpenURLAction hands http to the system) or the probe's OpenURLAction
/// counts it.
///
/// Opt-in, like the other probes: LINK_TAP_PROBE=1.
///
/// Safari is waited for up to a BUDGET, not a guess (15 s): on the CI runner
/// (Xcode 26.3, iOS 26.2) it came to the front 2.3 s after the tap on one
/// path and more than 4 s after it on the other — the probe gave up at 4 s,
/// read "the link did not open", and its next tap landed on Safari, which
/// had come up meanwhile, so the Label's onClick read 0 too (run 38322592393,
/// the first time this probe ran in CI). A tap is now made only with the app
/// in front, asserted, and each one prints which app was in front. Each path
/// starts with Safari not running (it is stopped if the path before left it).
final class LinkTapProbeUITests: XCTestCase {
    private var app: XCUIApplication!
    private let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    /// How long a link's URL may take to bring Safari to the front.
    private let safariBudget: TimeInterval = 15

    private func state(_ a: XCUIApplication) -> String {
        switch a.state {
        case .runningForeground: return "foreground"
        case .runningBackground, .runningBackgroundSuspended: return "background"
        case .notRunning: return "notRunning"
        default: return "unknown"
        }
    }

    /// The app must be in front for a tap to reach it; a tap with Safari in
    /// front lands on Safari.
    private func assertAppInFront(_ what: String) -> Bool {
        let inFront = app.wait(for: .runningForeground, timeout: 10)
        print("LINK_TAP \(what): app=\(state(app)) safari=\(state(safari))")
        XCTAssertTrue(inFront, "\(what): the app is not in front (safari=\(state(safari))) — a tap now would land elsewhere")
        return inFront
    }

    func testALinkTapCallsTheLinkAndTheRestCallsTheLabel() throws {
        guard ProcessInfo.processInfo.environment["LINK_TAP_PROBE"] == "1" else {
            throw XCTSkip("link tap probe: run with the guard lifted, as the other probes are")
        }
        continueAfterFailure = true
        let paths = (ProcessInfo.processInfo.environment["LINK_TAP_PATHS"] ?? "dynamic,codegen").split(separator: ",").map(String.init)
        for path in paths { run(path) }
    }

    private func counts() -> [String: Int] {
        let readout = app.staticTexts["lt_readout"].label
        guard let start = readout.range(of: "counts[")?.upperBound,
              let end = readout.range(of: "]", options: .backwards)?.lowerBound, start <= end else { return [:] }
        var out: [String: Int] = [:]
        for pair in readout[start..<end].split(separator: ",") {
            let kv = pair.split(separator: "=")
            if kv.count == 2, let n = Int(kv[1]) { out[String(kv[0])] = n }
        }
        return out
    }

    private func label(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(_ path: String) {
        // Each path from a Safari not running, as the first one is: brought
        // up from the background (the path before left it there) it came to
        // the front 3.8 s after the tap on a green run and past the 15 s
        // budget on run 40094279447 (both attempts; it came up a moment
        // later), while from not running it took 1.1–1.4 s on every run.
        if safari.state != .notRunning {
            safari.terminate()
            let gone = safari.wait(for: .notRunning, timeout: 10)
            print("LINK_TAP \(path): safari stopped before the path=\(gone ? 1 : 0)")
        }
        app = XCUIApplication()
        app.launchArguments = ["-linkTapProbe", "-ltPath", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["lt_ready"].waitForExistence(timeout: 15), "\(path): probe did not start")

        for (id, linkKey, labelKey) in [("lt_url", "url", "urlLabel"), ("lt_range", "terms", "rangeLabel")] {
            let element = label(id)
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(path) \(id): not found")
            guard assertAppInFront("\(path) \(id) before the link tap") else { continue }
            let before = counts()

            // On the link: the link's element if XCUITest reports one, else
            // the Label's leading edge, where both links start.
            let link = element.links.firstMatch
            if link.exists {
                link.tap()
            } else {
                element.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
            }
            // A detected URL goes to PartialAttributedText's own OpenURLAction,
            // which hands an http URL to the system: Safari coming to the
            // front is the URL opening. The app is brought back to read on.
            var opened = 0
            if linkKey == "url" {
                // Safari in front, or the probe's own count moving, within the
                // budget — polled, so a fast open is read at once.
                let start = Date()
                while Date().timeIntervalSince(start) < safariBudget {
                    if safari.state == .runningForeground { opened = 1; break }
                    if (counts()[linkKey] ?? 0) != (before[linkKey] ?? 0) { break }
                    usleep(250_000)
                }
                print(String(format: "LINK_TAP %@ %@: safari in front=%d after %.2f s (budget %.0f s)",
                             path, id, opened, Date().timeIntervalSince(start), safariBudget))
                if safari.state == .runningForeground {
                    app.activate()
                    _ = app.staticTexts["lt_ready"].waitForExistence(timeout: 10)
                }
            }
            let onLink = counts()
            XCTAssertEqual((onLink[linkKey] ?? 0) - (before[linkKey] ?? 0) + opened, 1, "\(path) \(id): a tap on the link did not call it (link exposed: \(link.exists))")
            XCTAssertEqual((onLink[labelKey] ?? 0) - (before[labelKey] ?? 0), 0, "\(path) \(id): a tap on the link called the Label's onClick")

            // Past the link: the Label's onClick, not the link — with the app
            // in front, or the tap is not the Label's to receive.
            guard assertAppInFront("\(path) \(id) before the tap past the link") else { continue }
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            let offLink = counts()
            XCTAssertEqual((offLink[labelKey] ?? 0) - (onLink[labelKey] ?? 0), 1, "\(path) \(id): a tap past the link did not call the Label's onClick")
            XCTAssertEqual((offLink[linkKey] ?? 0) - (onLink[linkKey] ?? 0), 0, "\(path) \(id): a tap past the link called the link")
        }
        app.terminate()
    }
}
