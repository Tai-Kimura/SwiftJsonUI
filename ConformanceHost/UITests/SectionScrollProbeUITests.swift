//
//  SectionScrollProbeUITests.swift
//  ConformanceHostUITests
//
//  A two-section Collection as sjui generates it (SectionScrollProbeView):
//  - scrollTo 13 lands on B3 — the later section's cell 3 — at the top of
//    the list, and A0 leaves it;
//  - scrollTo "b3" (cellIdProperty) lands on the later section's b3;
//  - two sections whose cells share keys draw all ten cells.
//  NOT opt-in. The codegen host only: in the dynamic host the generated half
//  must be absent, and nothing else is asked.
//

import XCTest

final class SectionScrollProbeUITests: XCTestCase {
    func testAScrollReachesTheCellItNamesAndSharedKeysDrawEveryCell() throws {
        let codegenHost = ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
        let app = XCUIApplication()
        app.launchArguments = ["-sectionScrollProbe"]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["ss_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertEqual(app.staticTexts["ss_codegen"].exists, codegenHost, "the generated shapes are there iff this is the codegen host")
        guard codegenHost else { return }

        func text(_ label: String) -> XCUIElement { app.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch }
        var report: [String] = []
        func note(_ label: String) {
            let e = text(label)
            report.append("\(label): exists=\(e.exists) hittable=\(e.exists && e.isHittable) y=\(e.exists ? Int(e.frame.minY) : -1)")
        }

        // Before any scroll: each list shows its first section's first rows.
        XCTAssertTrue(text("A0").waitForExistence(timeout: 5))
        XCTAssertTrue(text("a0").exists && text("a0").isHittable)
        ["A0", "B3", "a0", "b3"].forEach(note)

        // scrollTo an index: 13 is B3.
        app.buttons["go index"].tap()
        let b3 = text("B3")
        XCTAssertTrue(b3.waitForExistence(timeout: 5), "scrollTo 13 did not bring B3 into the list")
        XCTAssertTrue(b3.exists && b3.isHittable, "B3 is not on screen after scrollTo 13")
        XCTAssertFalse(text("A0").exists && text("A0").isHittable, "A0 is still on screen: the list did not scroll")
        if b3.exists {
            let goIndex = app.buttons["go index"].frame
            XCTAssertLessThan(abs(b3.frame.minY - goIndex.maxY - 12), 30, "B3 is not at the top of the list (anchor top)")
        }

        // scrollTo a key: "b3", a later section's cell.
        app.buttons["go key"].tap()
        let keyed = text("b3")
        XCTAssertTrue(keyed.waitForExistence(timeout: 5), "scrollTo \"b3\" did not bring b3 into the list")
        XCTAssertTrue(keyed.exists && keyed.isHittable, "b3 is not on screen after scrollTo \"b3\"")
        XCTAssertFalse(text("a0").exists && text("a0").isHittable, "a0 is still on screen: the list did not scroll")
        ["A0", "B3", "a0", "b3"].forEach(note)

        // Shared keys: every cell of both sections.
        let titles = (0..<5).map { "x\($0)" } + (0..<5).map { "y\($0)" }
        for title in titles {
            XCTAssertTrue(text(title).exists, "\(title) is not drawn (two sections share its key)")
        }
        report.append("SHARED: " + titles.map { "\($0)=\(text($0).exists)" }.joined(separator: " "))

        report.forEach { print("SSP \($0)") }
        let attachment = XCTAttachment(string: report.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
