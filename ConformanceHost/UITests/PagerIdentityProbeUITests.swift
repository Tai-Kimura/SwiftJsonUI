import XCTest

/// PagerIdentityProbeView: 24 swipes released mid-way (momentum finishes
/// them) across a five-page pager whose off-screen page changes on every page
/// change. Each must settle on a page: 2 s after the swipe exactly one page's
/// cell is inside the pager, at the place page 0's cell rested. Prints every
/// swipe, so a red names which stopped and where.
///
/// Measured 2026-10-04 (iOS 26.5, Xcode 26.6): the generated half stopped on
/// 12 of 24 swipes with jsonui-cli v1.9.8 and on none with the pager's loop
/// by index. The Dynamic half settled on 24 of 24 BEFORE its fix too — its
/// onPageChanged fired on every swipe and the off-screen page's content
/// changed, yet no swipe stopped — so it does not discriminate the Dynamic
/// change (pages known by their place); it stays as the Dynamic face's
/// reading of the same contract.
final class PagerIdentityProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["pid_ready"].waitForExistence(timeout: 15), "probe did not start")
        let pager = element(app, "\(p)_pid_pager")
        let first = element(app, "\(p)_pid_pager_item_0")
        XCTAssertTrue(first.waitForExistence(timeout: 10), "page 0 is not drawn")
        sleep(1)
        let restX = first.frame.minX
        let frame = pager.frame
        let directions: [Bool] = Array(repeating: [true, true, true, true, false, false, false, false], count: 3).flatMap { $0 }
        var stopped: [String] = []
        for (n, left) in directions.enumerated() {
            let from = pager.coordinate(withNormalizedOffset: CGVector(dx: left ? 0.7 : 0.3, dy: 0.5))
            let to = pager.coordinate(withNormalizedOffset: CGVector(dx: left ? 0.35 : 0.65, dy: 0.5))
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .fast, thenHoldForDuration: 0)
            sleep(2)
            var visible: [(Int, CGFloat)] = []
            for i in 0..<5 {
                let cell = element(app, "\(p)_pid_pager_item_\(i)")
                if cell.exists, cell.frame.intersects(frame), cell.frame.width > 0 { visible.append((i, cell.frame.minX)) }
            }
            let settled = visible.count == 1 && abs(visible[0].1 - restX) < 1.5
            let version = app.staticTexts["pid_version"].label
            print("[PagerIdentity] \(p) swipe \(n) \(left ? "left" : "right"): visible=\(visible) restX=\(restX) \(version) \(settled ? "settled" : "STOPPED")")
            if !settled { stopped.append("\(n)") }
        }
        XCTAssertEqual(stopped, [], "the pager stopped between pages after swipes \(stopped) of \(directions.count)")
    }

    func testDynamicPagerSettlesWhileAnOffscreenPageChanges() throws {
        try XCTSkipIf(codegenHost, "the Dynamic half runs in the Dynamic host")
        run(prefix: "dyn", argument: "-pagerIdentityProbe")
    }

    func testGeneratedPagerSettlesWhileAnOffscreenPageChanges() throws {
        try XCTSkipUnless(codegenHost, "the generated half runs in the codegen host")
        run(prefix: "cg", argument: "-pagerIdentityProbeCodegen")
    }
}
