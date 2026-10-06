//
//  IdBoxProbeUITests.swift
//  ConformanceHostUITests
//
//  Every type's id box is its layout box, in Dynamic and in codegen
//  (IdBoxProbeView). Two reads per type, both what a UI test can see:
//    - id: the XCUIElement `<p>_ib_<t>`, the box a driver taps and reads;
//    - layout: `frame:<p>_ib_<t>`, the box the frame-parity gate reads.
//  The id must equal the layout box (±0.5), and the layout box, relative to
//  the parent's layout box, must be (25, 10, 100, 40). The parent is read
//  from its `frame:` element: a container's own id box is the thing under
//  test. NOT opt-in.
//

import XCTest

final class IdBoxProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private static let types = ["label", "button", "image", "textfield", "textview", "view", "emptyview", "scrollview"]

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func text(_ r: CGRect) -> String {
        String(format: "(%.1f,%.1f,%.1f,%.1f)", r.minX, r.minY, r.width, r.height)
    }

    private func run(prefix p: String, argument: String) {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["ib_ready"].waitForExistence(timeout: 15), "probe did not start")
        var lines: [String] = []
        for type in Self.types {
            let id = element(app, "\(p)_ib_\(type)")
            let layout = element(app, "frame:\(p)_ib_\(type)")
            let parent = element(app, "frame:\(p)_ib_p_\(type)")
            guard id.waitForExistence(timeout: 5), layout.exists, parent.exists else {
                XCTFail("\(p)_ib_\(type): id \(id.exists) layout \(layout.exists) parent \(parent.exists)")
                continue
            }
            let origin = parent.frame.origin
            let i = id.frame.offsetBy(dx: -origin.x, dy: -origin.y)
            let l = layout.frame.offsetBy(dx: -origin.x, dy: -origin.y)
            lines.append("\(p)_ib_\(type): id \(text(i)) layout \(text(l))")
            for (name, a, b) in [("minX", i.minX, l.minX), ("minY", i.minY, l.minY),
                                 ("width", i.width, l.width), ("height", i.height, l.height)] {
                XCTAssertEqual(a, b, accuracy: 0.5, "\(p)_ib_\(type): id \(name) \(a), layout \(b)")
            }
            for (name, a, b) in [("minX", l.minX, 25), ("minY", l.minY, 10),
                                 ("width", l.width, 100), ("height", l.height, 40)] as [(String, CGFloat, CGFloat)] {
                XCTAssertEqual(a, b, accuracy: 0.5, "\(p)_ib_\(type): layout \(name) \(a), expected \(b)")
            }
        }
        lines.forEach { print("IBP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "id_box_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testEveryIdBoxIsItsLayoutBoxDynamic() throws {
        run(prefix: "dyn", argument: "-idBoxProbe")
    }

    func testEveryIdBoxIsItsLayoutBoxGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-idBoxProbeCodegen")
    }
}
