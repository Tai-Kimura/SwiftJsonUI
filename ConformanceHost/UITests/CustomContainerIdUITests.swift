//
//  CustomContainerIdUITests.swift
//  ConformanceHostUITests
//
//  Every identifier inside a custom container is found exactly once, and so is
//  the container's (CustomContainerIdView). NOT opt-in: the host's UI tests
//  run in jsonui-cli's conformance-mobile workflow (both iOS jobs), and this
//  runs with them. In the codegen host (CONFORMANCE_HOST_MODE=codegen) the
//  sjui-generated shapes (`cg_`) are asked the same and must be there; in the
//  dynamic host they must not be.
//

import XCTest

final class CustomContainerIdUITests: XCTestCase {
    private func ids(_ p: String) -> [String] {
        ["\(p)_one", "\(p)_one_kid", "\(p)_two", "\(p)_two_a", "\(p)_two_b",
         "\(p)_nest", "\(p)_nest_view", "\(p)_nest_kid", "\(p)_noid_kid",
         "\(p)_shelf", "\(p)_shelf_kid", "\(p)_tap", "\(p)_tap_kid", "\(p)_tapnoid_kid",
         // the built-in control
         "\(p)_view", "\(p)_view_kid"]
    }

    func testEveryIdentifierInACustomContainerIsFoundOnce() throws {
        let codegenHost = ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
        let app = XCUIApplication()
        app.launchArguments = ["-customContainerId"]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["cc_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["cc_decode_failed"].exists, "a shape did not decode")

        func count(_ id: String) -> Int { app.descendants(matching: .any).matching(identifier: id).count }
        func elements(in wrapper: String) -> String {
            let all = app.descendants(matching: .any).matching(identifier: wrapper).firstMatch.descendants(matching: .any)
            return (0..<all.count).map { all.element(boundBy: $0) }.map { "\($0.elementType.rawValue):\($0.identifier):'\($0.label)'" }.joined(separator: " ")
        }
        let asked = ids("cc") + (codegenHost ? ids("cg") : [])
        var report = asked.map { "CCI id \($0): count=\(count($0))" }
        report += ["one", "two", "nest", "noid", "shelf", "tap", "tapnoid", "view"].flatMap { shape in
            (codegenHost ? ["cc", "cg"] : ["cc"]).map { "CCI wrap_\($0)_\(shape): [\(elements(in: "wrap_\($0)_\(shape)"))]" }
        }
        report.append("CCI dup: count=\(count("cc_dup")) codegen marker=\(count("cc_codegen"))")
        report.forEach { print($0) }
        let attachment = XCTAttachment(string: report.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)

        // The instrument counts two where there are two.
        XCTAssertEqual(count("cc_dup"), 2)
        XCTAssertEqual(count("cc_codegen"), codegenHost ? 1 : 0, "the generated shapes are there iff this is the codegen host")
        for id in asked {
            XCTAssertEqual(count(id), 1, "\(id) must be found once")
        }
    }
}
