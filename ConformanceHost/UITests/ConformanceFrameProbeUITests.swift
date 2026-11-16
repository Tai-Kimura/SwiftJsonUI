//
//  ConformanceFrameProbeUITests.swift
//  ConformanceHostUITests
//
//  The frames gate's measuring elements exist only where a host asks for
//  them. While `jsonuiConformanceFrameProbe` is set, SwiftJsonUI's
//  jsonUIConformanceFrame hands each id's layout box up and the host's
//  jsonUIConformanceFrames draws a clear `frame:<id>` element there.
//  Otherwise the modifier returns its content unchanged, which is every app.
//  `-noConformanceFrameProbe` launches the host as an app runs.
//
//  Runs in every suite (no guard): it is the arm for "an app gets none".
//  One query per id, as the frames reader does, not a hierarchy snapshot.
//

import XCTest

final class ConformanceFrameProbeUITests: XCTestCase {

    private let fixture = "common/alignTopView__static"
    /// The ids common/alignTopView__static declares.
    private let ids = ["root", "anchor", "target", "box_a", "box_b", "box_c", "box_d", "box_e", "box_f"]

    private func launch(probe: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixtureId", fixture] + (probe ? [] : ["-noConformanceFrameProbe"])
        app.launch()
        let marker = "conformance_current_" + fixture.replacingOccurrences(of: "/", with: "_")
        XCTAssertTrue(app.descendants(matching: .any)[marker].waitForExistence(timeout: 15),
                      "the fixture did not come up")
        return app
    }

    private func measured(_ app: XCUIApplication) -> [String] {
        ids.filter { app.descendants(matching: .any)["frame:" + $0].exists }
    }

    /// As an app runs: no measuring element at all, and the ids are there.
    func testAnAppGetsNoMeasuringElement() {
        let app = launch(probe: false)
        XCTAssertEqual(measured(app), [], "jsonUIConformanceFrame made elements without the environment value")
        XCTAssertTrue(app.descendants(matching: .any)["anchor"].exists, "control: the ids are drawn")
    }

    /// The host asks: one per declared id, and the anchor's is its layout box.
    func testTheHostGetsOnePerId() {
        let app = launch(probe: true)
        XCTAssertEqual(measured(app), ids, "a declared id has no measuring element with the environment value set")
        let anchor = app.descendants(matching: .any)["frame:anchor"]
        XCTAssertEqual(anchor.frame.width, 50, accuracy: 0.5)
        XCTAssertEqual(anchor.frame.height, 50, accuracy: 0.5)
    }
}
