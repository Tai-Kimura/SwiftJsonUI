//
//  IconLabelIconSizeUITests.swift
//  ConformanceHostUITests
//
//  An IconLabel with no `iconSize` draws its icon at the image's own size
//  (2026-10-05 ruling 7, as KotlinJsonUI 6e7bcb2 does); a declared size is
//  kept. Both routes drew an undeclared icon at a fixed 24: the library's
//  IconLabelView defaulted `iconSize` to 24, and the sjui codegen emits no
//  `iconSize:` when none is declared, so it took the same default.
//
//  The shapes live in the composite leaf probe (CompositeLeafIdView, and its
//  generated twins `cg_` in the codegen host). Host assets:
//  conformance_sample 64pt, conformance_sample_alt 96pt (1x). The IconLabel
//  is one combined element, and its frame is the TALLER of its icon and its
//  text, not the stack of the two (measured, iOS 26.5: 64 / 96 / 19.33 for
//  sample / alt / a declared 8 with the icon on top). So an icon taller than
//  the text shows as the element's height: fixed at 24 both read 24; at the
//  image's own size they read 64 and 96. A declared 8 is shorter than the
//  text, so it can only be told from a 24 floor, not measured as 8.
//

import XCTest

final class IconLabelIconSizeUITests: XCTestCase {
    func testAnUndeclaredIconSizeIsTheImagesOwnSize() throws {
        let codegenHost = ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen"
        let app = XCUIApplication()
        app.launchArguments = ["-compositeLeafId"]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        app.launch()
        XCTAssertTrue(app.staticTexts["cl_ready"].waitForExistence(timeout: 15), "probe did not start")

        func height(_ id: String) -> CGFloat {
            let element = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(element.exists, "\(id) is not there")
            return element.frame.height
        }

        for p in codegenHost ? ["cl", "cg"] : ["cl"] {
            let sample = height("\(p)_ils_sample"), alt = height("\(p)_ils_alt"), eight = height("\(p)_ils_8")
            print("ILS \(p): sample=\(sample) alt=\(alt) 8=\(eight)")
            XCTAssertEqual(sample, 64, accuracy: 0.5, "\(p): the undeclared sample icon is not its 64")
            XCTAssertEqual(alt, 96, accuracy: 0.5, "\(p): the undeclared alt icon is not its 96")
            XCTAssertLessThan(eight, 24, "\(p): the declared 8 grew to \(eight)")
        }
    }
}
