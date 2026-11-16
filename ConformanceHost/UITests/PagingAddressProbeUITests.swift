//
//  PagingAddressProbeUITests.swift
//  ConformanceHostUITests
//
//  Every page of a sectioned pager is found by `{collectionId}_item_{n}`,
//  once, holding its own cell — n its place among all the pages, across the
//  sections (PagingAddressProbeView). NOT opt-in: the host's UI tests run in
//  jsonui-cli's conformance-mobile workflow (both iOS jobs), and this runs
//  with them. In the codegen host (CONFORMANCE_HOST_MODE=codegen) the
//  sjui-generated pager (`cg_`) is asked the same; in the dynamic host it is
//  not there.
//
//  The test swipes the pager from page to page and asks each page for its
//  address and its title: A0 A1 are pages 0 1, B0 B1 B2 are 2 3 4, C0 is 5
//  (the header-only section adds none); and it asks the two-section list
//  for every title.
//

import XCTest

final class PagingAddressProbeUITests: XCTestCase {
    private let titles = ["A0", "A1", "B0", "B1", "B2", "C0"]

    func testEveryPageIsAddressedByItsPlaceAmongAllThePages() throws {
        let codegenHost = ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
        let app = XCUIApplication()
        app.launchArguments = ["-pagingAddressProbe"]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["pa_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["pa_decode_failed"].exists, "the pager did not decode")
        XCTAssertEqual(app.staticTexts["pa_codegen"].exists, codegenHost, "the generated pager is there iff this is the codegen host")

        var report: [String] = []
        // Every `_pager_item_` element on screen now, with its frame — what a
        // page that is not where the test expects it shows instead.
        func onScreen(_ prefix: String) -> String {
            let all = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "\(prefix)_pager_item_"))
            return (0..<all.count).map { all.element(boundBy: $0) }.map { "\($0.identifier)@\(Int($0.frame.minX)),\(Int($0.frame.minY))" }.joined(separator: " ")
        }
        for prefix in codegenHost ? ["pa", "cg"] : ["pa"] {
            let frame = app.descendants(matching: .any).matching(identifier: "\(prefix)_pager_frame").firstMatch
            XCTAssertTrue(frame.waitForExistence(timeout: 5), "\(prefix)_pager_frame")
            for (n, title) in titles.enumerated() {
                let id = "\(prefix)_pager_item_\(n)"
                let page = app.descendants(matching: .any).matching(identifier: id).firstMatch
                let found = page.waitForExistence(timeout: 5)
                let count = app.descendants(matching: .any).matching(identifier: id).count
                let labels = found ? page.descendants(matching: .staticText).allElementsBoundByIndex.map(\.label) : []
                report.append("PAGE \(id): exists=\(found) count=\(count) labels=\(labels) on screen: [\(onScreen(prefix))]")
                XCTAssertTrue(found, "\(id) must be found: page \(n) is \(title)")
                XCTAssertEqual(count, found ? 1 : 0, "\(id) is one page")
                if found { XCTAssertTrue(labels.contains(title), "\(id) holds \(title), found \(labels)") }
                if n < titles.count - 1 {
                    frame.swipeLeft()
                }
            }
        }
        // The two-section list: every section's cells, and the header between.
        for prefix in codegenHost ? ["pa", "cg"] : ["pa"] {
            let list = app.descendants(matching: .any).matching(identifier: "\(prefix)_list_frame").firstMatch
            XCTAssertTrue(list.waitForExistence(timeout: 5), "\(prefix)_list_frame")
            let drawn = list.descendants(matching: .staticText).allElementsBoundByIndex.map(\.label)
            report.append("LIST \(prefix)_list: \(drawn)")
            for title in ["A0", "A1", "H", "B0", "B1", "B2", "C0"] {
                XCTAssertTrue(drawn.contains(title), "\(prefix)_list draws \(title): \(drawn)")
            }
        }
        // Every identifier carrying `_pager_item_`, so an address that is
        // there under another number shows in the report.
        let all = app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS '_pager_item_'"))
        report.append("ALL: \((0..<all.count).map { all.element(boundBy: $0).identifier })")
        report.forEach { print($0) }
        let attachment = XCTAttachment(string: report.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
