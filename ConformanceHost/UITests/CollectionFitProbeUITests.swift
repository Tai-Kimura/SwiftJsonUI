//
//  CollectionFitProbeUITests.swift
//  ConformanceHostUITests
//
//  A wrapContent Collection sizes to its content (CollectionFitProbeView; 4f
//  ruling 2026-09-27): in a bounded View it is its cells' height and the view
//  after it comes right under them; past the bound it is the bound and
//  scrolls; in a ScrollView it is its cells; a horizontal one is its cells'
//  width. Eager and none Collections start their cells at the leading edge,
//  as the lazy one does. The Dynamic half always; the generated half in the
//  codegen host only. NOT opt-in.
//

import XCTest

final class CollectionFitProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func launch(_ argument: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["cf_ready"].waitForExistence(timeout: 15), "probe did not start")
        return app
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func run(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        let box = element(app, "\(p)_fit_box").frame
        let list = element(app, "\(p)_fit_list").frame
        let after = element(app, "\(p)_fit_after").frame
        lines.append("\(p) box: list h=\(Int(list.height)) in \(Int(box.height)); after at \(Int(after.minY - box.minY)), list ends \(Int(list.maxY - box.minY))")
        XCTAssertEqual(list.height, 84, accuracy: 2, "\(p): the Collection is not its three cells' height")
        XCTAssertEqual(after.minY, list.maxY, accuracy: 2, "\(p): the label is not right under the cells")

        let longBox = element(app, "\(p)_fit_long_box").frame
        let long = element(app, "\(p)_fit_long").frame
        let longAfter = element(app, "\(p)_fit_long_after").frame
        lines.append("\(p) long: list h=\(Int(long.height)) in \(Int(longBox.height)); after ends \(Int(longAfter.maxY - longBox.minY))")
        XCTAssertLessThan(long.height, 280, "\(p): ten cells were not bounded by the box")
        XCTAssertEqual(long.height + longAfter.height, longBox.height, accuracy: 2, "\(p): the bounded Collection is not the box less the label")

        let scroll = element(app, "\(p)_fit_scroll").frame
        let inner = element(app, "\(p)_fit_inner").frame
        let innerAfter = element(app, "\(p)_fit_inner_after").frame
        lines.append("\(p) scroll: list h=\(Int(inner.height)) in \(Int(scroll.height)); after at \(Int(innerAfter.minY - scroll.minY))")
        XCTAssertEqual(inner.height, 84, accuracy: 2, "\(p): in a ScrollView the Collection is not its cells' height")
        XCTAssertEqual(innerAfter.minY, inner.maxY, accuracy: 2, "\(p): in a ScrollView the label is not right under the cells")

        let row = element(app, "\(p)_fit_row").frame
        let h = element(app, "\(p)_fit_h").frame
        let hAfter = element(app, "\(p)_fit_h_after").frame
        lines.append("\(p) row: list w=\(Int(h.width)) in \(Int(row.width)); after at \(Int(hAfter.minX - row.minX))")
        XCTAssertEqual(h.width, 120, accuracy: 2, "\(p): the horizontal Collection is not its two cells' width")
        XCTAssertEqual(hAfter.minX, h.maxX, accuracy: 2, "\(p): the label is not right after the cells")

        // Measured from the probe's leading edge (the box's): the element the
        // identifier lands on can be the scroll content rather than the
        // Collection's 200pt frame.
        for mode in ["eager", "none"] {
            let frame = element(app, "\(p)_fit_\(mode)")
            let f0 = frame.staticTexts.matching(NSPredicate(format: "label == %@", "f0")).firstMatch
            let x = f0.exists ? f0.frame.minX - box.minX : -1
            lines.append("\(p) \(mode): f0 at x=\(Int(x)) of the 200pt column")
            XCTAssertEqual(x, 4, accuracy: 2, "\(p) \(mode): the cells do not start at the leading edge")
        }
        lines.forEach { print("CFP \($0)") }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "collection_fit_\(p)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testAWrapContentCollectionSizesToItsContentDynamic() throws {
        run(prefix: "dyn", argument: "-collectionFitProbe")
    }

    func testAWrapContentCollectionSizesToItsContentGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-collectionFitProbeCodegen")
    }
}
