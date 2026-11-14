//
//  CellFrameRoutesProbeUITests.swift
//  ConformanceHostUITests
//
//  cellWidth 150 / cellHeight 40 frame every cell, on every route
//  (CellFrameRoutesProbeView). The cells are 60 × 28 and sit at their
//  frame's top leading corner, so the frame is read off where the next cell
//  starts: the list's and the `lazy: none` vertical stack's cells 40 apart,
//  the horizontal stack's 150, the flow's two a line 160 apart (gap 10) and
//  the third 50 down; the pager's cell where a 150 × 40 frame centred in its
//  200 × 60 page puts it. NOT opt-in.
//

import XCTest

final class CellFrameRoutesProbeUITests: XCTestCase {
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func testEveryRouteFramesItsCellsByCellWidthAndCellHeight() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-cellFrameRoutesProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["cw_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["cw_decode_failed"].exists, "a Collection did not decode")

        var report: [String] = []
        func cell(_ route: String, _ n: Int) -> CGRect {
            let e = element(app, "\(route)_item_\(n)")
            XCTAssertTrue(e.waitForExistence(timeout: 5), "\(route)_item_\(n) is not drawn")
            return e.frame
        }
        func check(_ route: String, _ what: String, _ value: CGFloat, _ expected: CGFloat) {
            report.append("CWP \(route) \(what) = \(Int(value.rounded())) (expected \(Int(expected)))")
            XCTAssertEqual(value, expected, accuracy: 1, "\(route): \(what)")
        }

        // The list (the control) and the `lazy: none` stacks.
        for route in ["cw_list", "cw_none_v"] {
            let c0 = cell(route, 0), c1 = cell(route, 1)
            check(route, "item_1.y - item_0.y", c1.minY - c0.minY, 40)
            check(route, "item_1.x - item_0.x", c1.minX - c0.minX, 0)
        }
        do {
            let c0 = cell("cw_none_h", 0), c1 = cell("cw_none_h", 1)
            check("cw_none_h", "item_1.x - item_0.x", c1.minX - c0.minX, 150)
            check("cw_none_h", "item_1.y - item_0.y", c1.minY - c0.minY, 0)
        }
        // The flow, lazy and `lazy: none`: 150 + 10 a cell, 40 + 10 a line.
        for route in ["cw_flow", "cw_flow_none"] {
            let c0 = cell(route, 0), c1 = cell(route, 1), c2 = cell(route, 2)
            check(route, "item_1.x - item_0.x", c1.minX - c0.minX, 160)
            check(route, "item_1.y - item_0.y", c1.minY - c0.minY, 0)
            check(route, "item_2.x - item_0.x", c2.minX - c0.minX, 0)
            check(route, "item_2.y - item_0.y", c2.minY - c0.minY, 50)
        }
        // The pager: the page is 200 × 60, its cell's 150 × 40 frame centred
        // in it, the cell at the frame's top leading corner.
        do {
            let pager = element(app, "cw_pager_frame").frame
            let c0 = cell("cw_pager", 0)
            check("cw_pager", "item_0.x - pager.x", c0.minX - pager.minX, 25)
            check("cw_pager", "item_0.y - pager.y", c0.minY - pager.minY, 10)
        }
        report.forEach { print($0) }
        let attachment = XCTAttachment(string: report.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "cell_frame_routes"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
