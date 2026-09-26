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
final class LinkTapProbeUITests: XCTestCase {
    private var app: XCUIApplication!

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
        app = XCUIApplication()
        app.launchArguments = ["-linkTapProbe", "-ltPath", path]
        app.launch()
        XCTAssertTrue(app.staticTexts["lt_ready"].waitForExistence(timeout: 15), "\(path): probe did not start")

        for (id, linkKey, labelKey) in [("lt_url", "url", "urlLabel"), ("lt_range", "terms", "rangeLabel")] {
            let element = label(id)
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(path) \(id): not found")
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
                let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
                if safari.wait(for: .runningForeground, timeout: 4) {
                    opened = 1
                    app.activate()
                    _ = app.staticTexts["lt_ready"].waitForExistence(timeout: 10)
                }
            }
            let onLink = counts()
            XCTAssertEqual((onLink[linkKey] ?? 0) - (before[linkKey] ?? 0) + opened, 1, "\(path) \(id): a tap on the link did not call it (link exposed: \(link.exists))")
            XCTAssertEqual((onLink[labelKey] ?? 0) - (before[labelKey] ?? 0), 0, "\(path) \(id): a tap on the link called the Label's onClick")

            // Past the link: the Label's onClick, not the link.
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            let offLink = counts()
            XCTAssertEqual((offLink[labelKey] ?? 0) - (onLink[labelKey] ?? 0), 1, "\(path) \(id): a tap past the link did not call the Label's onClick")
            XCTAssertEqual((offLink[linkKey] ?? 0) - (onLink[linkKey] ?? 0), 0, "\(path) \(id): a tap past the link called the link")
        }
        app.terminate()
    }
}
