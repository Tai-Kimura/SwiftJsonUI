import XCTest

/// PagerHeightProbeView: a paging Collection of height wrapContent in a
/// vertical ScrollView, between a label above and one below, pages of 28pt
/// (page 0) and 40pt (page 1). The pager is as tall as the page it shows
/// (KotlinJsonUI's HorizontalPager ...wrapContentHeight()): 28 at first, the
/// labels touching it above and below; swiped to page 1, 40, the label below
/// moved down with it. The same pager at a fixed height of 60 stays 60 (the
/// control). Before the fix the wrapContent pager took whatever height the
/// ScrollView had left (309 of 420 here, the cell floating in its middle; on
/// a consumer's screen with less left, its cards cut), and 0 when asked its
/// ideal height (jsonui-cli ticket
/// 2026-10-23-sjui-paging-collection-wrapcontent-height-collapses-in-scrollview).
/// On the Dynamic renderer and, in the codegen host, as sjui generates it.
final class PagerHeightProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }
    /// A frame read off the simulator (points; a few for the rounding of
    /// heights and the labels' line boxes).
    private let tolerance: CGFloat = 2

    /// The screen as it is, kept with the result (the before / after pictures are read from it).
    private func keep(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["ph_ready"].waitForExistence(timeout: 15), "probe did not start")
        let pager = element(app, "\(p)_ph_pager"), head = element(app, "\(p)_ph_head"), foot = element(app, "\(p)_ph_foot")
        let fixed = element(app, "\(p)_ph_fixed")
        XCTAssertTrue(element(app, "\(p)_ph_pager_item_0").waitForExistence(timeout: 10), "\(p): page 0 is not drawn")
        let read = { () -> String in "\(Int(pager.frame.height.rounded()))|\(Int(foot.frame.minY.rounded()))" }
        let first = Landing.wait("\(p) page 0 drawn", read: read)
        keep("\(p)-page0")
        print("[PagerHeight] \(p) page 0: pager \(pager.frame) head \(head.frame) foot \(foot.frame) fixed \(fixed.frame) \(first)")
        XCTAssertEqual(pager.frame.height, 28, accuracy: tolerance, "\(p): the pager is as tall as page 0 (28): \(pager.frame)")
        XCTAssertEqual(pager.frame.minY, head.frame.maxY, accuracy: tolerance, "\(p): the label above touches the pager: \(head.frame) \(pager.frame)")
        XCTAssertEqual(foot.frame.minY, pager.frame.maxY, accuracy: tolerance, "\(p): the label below starts where the pager ends: \(pager.frame) \(foot.frame)")
        XCTAssertEqual(fixed.frame.height, 60, accuracy: tolerance, "\(p): the fixed pager stays 60: \(fixed.frame)")

        // page 1: the pager grows to its 40pt, the label below with it
        let before = read()
        let from = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let to = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .fast, thenHoldForDuration: 0)
        let second = Landing.wait("\(p) page 1", from: before, read: read)
        keep("\(p)-page1")
        print("[PagerHeight] \(p) page 1: pager \(pager.frame) foot \(foot.frame) \(second)")
        XCTAssertEqual(pager.frame.height, 40, accuracy: tolerance, "\(p): swiped to page 1, the pager is as tall as it (40): \(pager.frame)")
        XCTAssertEqual(foot.frame.minY, pager.frame.maxY, accuracy: tolerance, "\(p): the label below moved with it: \(pager.frame) \(foot.frame)")
        XCTAssertEqual(fixed.frame.height, 60, accuracy: tolerance, "\(p): the fixed pager still 60: \(fixed.frame)")
    }

    func testDynamicPagerIsAsTallAsItsShownPage() {
        run(prefix: "dyn", argument: "-pagerHeightProbe")
    }

    func testGeneratedPagerIsAsTallAsItsShownPage() throws {
        guard codegenHost else {
            let app = XCUIApplication()
            app.launchArguments = ["-pagerHeightProbeCodegen"]
            app.launch()
            XCTAssertTrue(app.staticTexts["ph_codegen_absent"].waitForExistence(timeout: 15), "the dynamic-only host has no generated half")
            return
        }
        run(prefix: "cg", argument: "-pagerHeightProbeCodegen")
    }
}
