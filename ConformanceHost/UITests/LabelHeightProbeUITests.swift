import XCTest

/// LabelHeightProbeView: a Label of height wrapContent keeps all its lines next
/// to its siblings in a stack with a finite height, and stays inside a node
/// that bounds the height; `lines` still limits it (jsonui-cli ticket
/// sjui-label-matchparent-wrapcontent-truncates-in-scroll). On the Dynamic
/// renderer and, in the codegen host, as sjui generates it.
final class LabelHeightProbeUITests: XCTestCase {
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
        XCTAssertTrue(app.staticTexts["lh_ready"].waitForExistence(timeout: 15), "probe did not start")
        let question = element(app, "\(p)_lh_question"), margined = element(app, "\(p)_lh_margined")
        let box = element(app, "\(p)_lh_box"), boxed = element(app, "\(p)_lh_boxed"), oneLine = element(app, "\(p)_lh_one_line")
        XCTAssertTrue(oneLine.waitForExistence(timeout: 10), "\(p): the probe is not drawn")
        Landing.wait("\(p) drawn") { "\(Int(question.frame.height.rounded()))|\(Int(oneLine.frame.minY.rounded()))" }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "\(p)-label-height"
        shot.lifetime = .keepAlways
        add(shot)
        print("[LabelHeight] \(p): question \(question.frame) margined \(margined.frame) box \(box.frame) boxed \(boxed.frame) oneLine \(oneLine.frame)")
        // 18pt bold is 21.5 a line: the sentence is wider than the 354 it gets.
        XCTAssertGreaterThan(question.frame.height, 40, "\(p): the question keeps its 2 lines: \(question.frame)")
        // 16pt is 19.1 a line, the sentence twice over needs at least 3 lines,
        // and topMargin is not the text's.
        XCTAssertGreaterThan(margined.frame.height, 55, "\(p): the Label with a top margin keeps its lines: \(margined.frame)")
        // Against the declared 44, not box.frame: an element's accessibility frame
        // grows with a child that spills, so the two would agree either way.
        XCTAssertLessThanOrEqual(box.frame.height, 44 + tolerance, "\(p): the declared height holds: \(box.frame)")
        XCTAssertLessThanOrEqual(boxed.frame.height, 44 + tolerance, "\(p): under a declared height the text stays inside: \(boxed.frame)")
        XCTAssertLessThan(oneLine.frame.height, 25, "\(p): `lines: 1` still limits it: \(oneLine.frame)")
    }

    func testDynamicLabelKeepsItsLines() {
        run(prefix: "dyn", argument: "-labelHeightProbe")
    }

    func testGeneratedLabelKeepsItsLines() {
        guard codegenHost else {
            let app = XCUIApplication()
            app.launchArguments = ["-labelHeightProbeCodegen"]
            app.launch()
            XCTAssertTrue(app.staticTexts["lh_codegen_absent"].waitForExistence(timeout: 15), "the dynamic-only host has no generated half")
            return
        }
        run(prefix: "cg", argument: "-labelHeightProbeCodegen")
    }
}
