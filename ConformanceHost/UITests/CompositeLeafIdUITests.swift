//
//  CompositeLeafIdUITests.swift
//  ConformanceHostUITests
//
//  A composite leaf is found by its id exactly once, as the element a test
//  driver means (CompositeLeafIdView). NOT opt-in: the host's UI tests run in
//  jsonui-cli's conformance-mobile workflow (both iOS jobs), and this runs
//  with them. In the codegen host (CONFORMANCE_HOST_MODE=codegen) the
//  sjui-generated shapes (`cg_`) are asked the same and must be there; in the
//  dynamic host they must not be.
//
//  The checks are the three the ticket measured through the test driver
//  (sjui-a-composite-leaf-gives-its-id-to-every-element-inside), asked of the
//  element the id resolves to:
//    * a tap on a TextField with a clear button leaves its text,
//    * an IconLabel reads as its text, not its icon's name,
//    * an empty TextView with a hint reads as empty, not its hint,
//  and, for every shape, that the id names one element.
//

import XCTest

final class CompositeLeafIdUITests: XCTestCase {
    private func shapes(_ p: String) -> [String] {
        ["\(p)_tf_clear", "\(p)_tf_noclear", "\(p)_tf_styled", "\(p)_il_left", "\(p)_il_right",
         "\(p)_tv_hint", "\(p)_tv_nohint", "\(p)_radio_items", "\(p)_image_hl"]
    }

    func testACompositeLeafIsFoundOnceAsTheElementADriverMeans() throws {
        let codegenHost = ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
        let app = XCUIApplication()
        app.launchArguments = ["-compositeLeafId"]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["cl_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["cl_decode_failed"].exists, "a shape did not decode")

        func matches(_ id: String) -> XCUIElementQuery { app.descendants(matching: .any).matching(identifier: id) }
        func describe(_ id: String) -> String {
            let q = matches(id)
            return (0..<q.count).map { q.element(boundBy: $0) }
                .map { "\($0.elementType.rawValue):'\($0.label)':'\(($0.value as? String) ?? "")'" }
                .joined(separator: " ")
        }

        let prefixes = codegenHost ? ["cl", "cg"] : ["cl"]
        var report = prefixes.flatMap(shapes).map { "CLI id \($0): count=\(matches($0).count) [\(describe($0))]" }
        report.append("CLI tap gate (dynamic): count=\(matches("cl_tap_gate").count) [\(describe("cl_tap_gate"))]")
        report.append("CLI dup: count=\(matches("cl_dup").count) codegen marker=\(matches("cl_codegen").count)")
        report.forEach { print($0) }
        let attachment = XCTAttachment(string: report.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)

        // The instrument counts two where there are two.
        XCTAssertEqual(matches("cl_dup").count, 2)
        XCTAssertEqual(matches("cl_codegen").count, codegenHost ? 1 : 0,
                       "the generated shapes are there iff this is the codegen host")

        for p in prefixes {
            for id in shapes(p) {
                XCTAssertEqual(matches(id).count, 1, "\(id) names \(matches(id).count) elements: \(describe(id))")
            }

            // A tap on the field with a clear button reaches the field, and
            // its text stays (a tap that reached the button emptied it).
            let clearable = matches("\(p)_tf_clear").firstMatch
            XCTAssertEqual(clearable.elementType, .textField, "\(p)_tf_clear is not the field: \(describe("\(p)_tf_clear"))")
            clearable.tap()
            Thread.sleep(forTimeInterval: 0.8)
            XCTAssertEqual(clearable.value as? String, "Clear me", "\(p)_tf_clear lost its text to the tap")
            app.tap() // leave the field, so the keyboard does not cover what follows

            // The IconLabel reads as its text.
            for side in ["left", "right"] {
                let label = matches("\(p)_il_\(side)").firstMatch
                XCTAssertEqual(label.label, "Sample", "\(p)_il_\(side) reads as '\(label.label)'")
            }

            // The empty TextView reads as empty, not as its hint.
            let editor = matches("\(p)_tv_hint").firstMatch
            XCTAssertEqual(editor.elementType, .textView, "\(p)_tv_hint is not the editor: \(describe("\(p)_tv_hint"))")
            XCTAssertNotEqual(editor.value as? String, "Conformance Hint", "\(p)_tv_hint reads as its hint")
        }
    }
}
