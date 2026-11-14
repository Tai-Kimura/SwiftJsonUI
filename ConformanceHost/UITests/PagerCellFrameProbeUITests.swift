//
//  PagerCellFrameProbeUITests.swift
//  ConformanceHostUITests
//
//  A pager's cellWidth / cellHeight frame its cell, and the page lays the
//  frame in its middle (PagerCellFrameProbeView): in a 200 × 60 page the
//  60 × 28 cell sits at the frame's top leading corner — 25, 10 framed
//  150 × 40; 25, 16 with cellWidth only; 70, 10 with cellHeight only; 70, 16
//  with neither (the control). NOT opt-in.
//

import XCTest

final class PagerCellFrameProbeUITests: XCTestCase {
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func testThePagerLaysTheDeclaredCellFrameInTheMiddleOfItsPage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-pagerCellFrameProbe"]
        app.launch()
        XCTAssertTrue(app.staticTexts["cp_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertFalse(app.staticTexts["cp_decode_failed"].exists, "a Collection did not decode")

        var report: [String] = []
        let expected: [(route: String, x: CGFloat, y: CGFloat)] = [
            ("cp_both", 25, 10), ("cp_w", 25, 16), ("cp_h", 70, 10), ("cp_none", 70, 16)
        ]
        for (route, x, y) in expected {
            let pager = element(app, "\(route)_frame")
            let cell = element(app, "\(route)_item_0")
            XCTAssertTrue(cell.waitForExistence(timeout: 5), "\(route)_item_0 is not drawn")
            let dx = cell.frame.minX - pager.frame.minX
            let dy = cell.frame.minY - pager.frame.minY
            report.append("CPF \(route) item_0 - pager = \(Int(dx.rounded())), \(Int(dy.rounded())) (expected \(Int(x)), \(Int(y)))")
            XCTAssertEqual(dx, x, accuracy: 1, "\(route): item_0.x - pager.x")
            XCTAssertEqual(dy, y, accuracy: 1, "\(route): item_0.y - pager.y")
        }
        report.forEach { print($0) }
        let attachment = XCTAttachment(string: report.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "pager_cell_frame"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
