//
//  GravityAxesTests.swift
//  SwiftJsonUITests
//
//  The gravity policy, now in one place. Four private copies of the horizontal
//  extractor and three of the vertical one had drifted apart —
//  ScrollViewConverter's never learned `centerHorizontal` — which is the
//  stale-duplicate shape G measured on android and asked ios to check for.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class GravityAxesTests: XCTestCase {

    // The 2026-08-07 canon: the axis a single-value gravity does NOT name
    // takes the container default for that axis — never unset, never
    // inherited (attribute_semantics.json gravityDefaults.unspecifiedAxis).
    func testUnnamedAxisTakesTheContainerDefault() {
        XCTAssertEqual(GravityAxes.vertical(["left"]), "top")
        XCTAssertEqual(GravityAxes.horizontal(["top"]), "left")
        XCTAssertEqual(GravityAxes.vertical(nil), "top")
        XCTAssertEqual(GravityAxes.horizontal(nil), "left")
        XCTAssertEqual(GravityAxes.vertical([]), "top")
        XCTAssertEqual(GravityAxes.horizontal([]), "left")
    }

    // The canon states this consequence explicitly: in LTR, `left` and `top`
    // both resolve to (start, top) and are observationally identical. A
    // fixture expecting them to differ tests something never promised.
    func testLeftAndTopResolveIdentically() {
        XCTAssertEqual(GravityAxes.horizontal(["left"]), GravityAxes.horizontal(["top"]))
        XCTAssertEqual(GravityAxes.vertical(["left"]), GravityAxes.vertical(["top"]))
    }

    // The single-axis centre spellings. This is what the stale copy dropped.
    func testSingleAxisCentreSpellings() {
        XCTAssertEqual(GravityAxes.horizontal(["centerHorizontal"]), "center")
        XCTAssertEqual(GravityAxes.vertical(["centerVertical"]), "center")
        XCTAssertEqual(GravityAxes.horizontal(["centerVertical"]), "left",
                       "a vertical spelling must not move the horizontal axis")
        XCTAssertEqual(GravityAxes.vertical(["centerHorizontal"]), "top",
                       "a horizontal spelling must not move the vertical axis")
    }

    func testBothAxesNamedTogether() {
        XCTAssertEqual(GravityAxes.horizontal(["right", "bottom"]), "right")
        XCTAssertEqual(GravityAxes.vertical(["right", "bottom"]), "bottom")
    }

    // `start`, not `left`: the canon is RTL-aware and so is the alignment.
    func testHorizontalAlignmentIsLeadingNotLeft() {
        XCTAssertEqual(GravityAxes.horizontalAlignment(nil), .leading)
        XCTAssertEqual(GravityAxes.horizontalAlignment(["right"]), .trailing)
        XCTAssertEqual(GravityAxes.horizontalAlignment(["centerHorizontal"]), .center)
        XCTAssertEqual(GravityAxes.verticalAlignment(nil), .top)
        XCTAssertEqual(GravityAxes.verticalAlignment(["bottom"]), .bottom)
    }
}
#endif
