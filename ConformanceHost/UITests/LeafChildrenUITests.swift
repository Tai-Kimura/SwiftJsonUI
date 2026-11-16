//
//  LeafChildrenUITests.swift
//  ConformanceHostUITests
//
//  A leaf custom component given children draws an error naming the component
//  and the children, in its own place (LeafChildrenProbeView). NOT opt-in: the
//  host's UI tests run in jsonui-cli's conformance-mobile workflow (both iOS
//  jobs), and this runs with them.
//
//  Measured before the fix (SwiftJsonUI 15ff2e2, iOS 26.5, 2026-09-25 23:11):
//  the leaf was drawn ("leaf drawn"), its child was not (count 0), and no
//  error — the children vanished without a word. After (23:16): the error in
//  the leaf's place, naming it and `child[0] (id=lp_leaf_kid)`. The
//  containers' children were drawn both times.
//

import XCTest

final class LeafChildrenUITests: XCTestCase {
    func testALeafGivenChildrenIsRefusedInItsPlace() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-leafChildren"]
        app.launch()
        XCTAssertTrue(app.staticTexts["lp_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["lp_decode_failed"].exists, "a shape did not decode")

        func count(_ id: String) -> Int { app.descendants(matching: .any).matching(identifier: id).count }
        func texts(in wrapper: String) -> [String] {
            let all = app.descendants(matching: .any).matching(identifier: wrapper).firstMatch.staticTexts
            return (0..<all.count).map { all.element(boundBy: $0).label }
        }
        /// Every element inside a wrapper as `identifier:'label'`, for the record.
        func elements(in wrapper: String) -> String {
            let all = app.descendants(matching: .any).matching(identifier: wrapper).firstMatch.descendants(matching: .any)
            return (0..<all.count).map { all.element(boundBy: $0) }.map { "\($0.identifier):'\($0.label)'" }.joined(separator: " ")
        }
        let report = ["lp_control", "lp_leaf_kid", "lp_auto_kid", "lp_shelf_kid"].map { "LCP id \($0): count=\(count($0))" }
            + ["wrap_leaf", "wrap_leaf_alone", "wrap_auto", "wrap_shelf"].map { "LCP \($0): \(texts(in: $0)) [\(elements(in: $0))]" }
        report.forEach { print($0) }
        let attachment = XCTAttachment(string: report.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)

        // The instrument answers 1 where there is one.
        XCTAssertEqual(count("lp_control"), 1)

        // The leaf: its child is not drawn, and it says so instead of drawing
        // itself without it.
        XCTAssertEqual(count("lp_leaf_kid"), 0)
        let refused = texts(in: "wrap_leaf")
        XCTAssertEqual(refused.count, 1, "\(refused)")
        XCTAssertTrue(refused.first?.contains("'LeafProbeLeaf' (id=lp_leaf) takes no children") == true, "\(refused)")
        XCTAssertTrue(refused.first?.contains("child[0] (id=lp_leaf_kid) is not drawn") == true, "\(refused)")
        XCTAssertFalse(refused.contains("leaf drawn"), "the leaf was drawn without its children")

        // A leaf with no children: drawn, nothing said.
        XCTAssertEqual(texts(in: "wrap_leaf_alone"), ["alone drawn"])

        // The containers (the default and --container) draw their children,
        // each found by its own id — until 10.29.0 a custom container's id was
        // pushed down onto them (0 before; CustomContainerIdUITests).
        XCTAssertEqual(count("lp_auto_kid"), 1)
        XCTAssertEqual(count("lp_shelf_kid"), 1)
    }
}
