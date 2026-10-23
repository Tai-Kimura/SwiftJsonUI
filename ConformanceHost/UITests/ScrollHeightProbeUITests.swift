import XCTest

/// ScrollHeightProbeView: a horizontal ScrollView of height wrapContent (a row
/// of three 28pt boxes) in a vertical ScrollView, between a label above and
/// one below. It is as tall as its row (KotlinJsonUI's horizontalScroll row),
/// the labels touching it. Its view is a GeometryReader around the ScrollView,
/// which a vertical ScrollView offers no height (jsonui-cli ticket
/// 2026-10-23-sjui-geometryreader-in-vertical-scroll-collapses). On the
/// Dynamic renderer and, in the codegen host, as sjui generates it.
final class ScrollHeightProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }
    private let tolerance: CGFloat = 2

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["sh_ready"].waitForExistence(timeout: 15), "probe did not start")
        let row = element(app, "\(p)_sh_row"), head = element(app, "\(p)_sh_head"), foot = element(app, "\(p)_sh_foot")
        XCTAssertTrue(foot.waitForExistence(timeout: 10), "\(p): the probe is not drawn")
        Landing.wait("\(p) drawn") { "\(Int(row.frame.height.rounded()))|\(Int(foot.frame.minY.rounded()))" }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "\(p)-scroll"
        shot.lifetime = .keepAlways
        add(shot)
        print("[ScrollHeight] \(p): row \(row.frame) head \(head.frame) foot \(foot.frame)")
        XCTAssertEqual(row.frame.height, 28, accuracy: tolerance, "\(p): the row is as tall as its boxes (28): \(row.frame)")
        XCTAssertEqual(row.frame.minY, head.frame.maxY, accuracy: tolerance, "\(p): the label above touches the row: \(head.frame) \(row.frame)")
        XCTAssertEqual(foot.frame.minY, row.frame.maxY, accuracy: tolerance, "\(p): the label below starts where the row ends: \(row.frame) \(foot.frame)")
    }

    func testDynamicRowIsAsTallAsItsContent() {
        run(prefix: "dyn", argument: "-scrollHeightProbe")
    }

    func testGeneratedRowIsAsTallAsItsContent() {
        guard codegenHost else {
            let app = XCUIApplication()
            app.launchArguments = ["-scrollHeightProbeCodegen"]
            app.launch()
            XCTAssertTrue(app.staticTexts["sh_codegen_absent"].waitForExistence(timeout: 15), "the dynamic-only host has no generated half")
            return
        }
        run(prefix: "cg", argument: "-scrollHeightProbeCodegen")
    }
}
