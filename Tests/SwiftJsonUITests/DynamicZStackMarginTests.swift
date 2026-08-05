//
//  DynamicZStackMarginTests.swift
//  SwiftJsonUITests
//
//  A ZStack child's individual margins are emitted by the parent as an
//  .offset (semantics.margins, "full-margin offset"), so the child must not
//  pad them a second time. But an offset only carries the DIFFERENCE of two
//  opposing margins: suppressing the padding outright made a symmetric
//  declaration — 10/10, 24/24 — cancel to nothing and disappear. These pin
//  the split that fixed it, and the cases that must keep the old behaviour.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicZStackMarginTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    private func insets(_ json: String, data: [String: Any] = [:]) throws -> EdgeInsets {
        DynamicModifierHelper.offsetOwnedMarginInsets(component: try component(json), data: data)
    }

    // MARK: - Bound centring (50 §4, group C)

    /// A centred axis has its offset zeroed, and `centerInParent` /
    /// `centerHorizontal` / `centerVertical` are all `boolean|binding`. The
    /// hand-decoded slot was nil for `@{expr}`, so a BOUND centring left the
    /// margin offset in place and the child sat off-centre by its own margin.
    func testBoundCentringZeroesTheOffset() throws {
        // Opposing pairs, because the inset this returns is the SHARED part
        // of two margins — a lone leftMargin shares nothing and is 0 either way.
        let json = """
        { "type": "View", "leftMargin": 20, "rightMargin": 20,
          "topMargin": 10, "bottomMargin": 10,
          "centerInParent": "@{isCentred}" }
        """

        let centred = try insets(json, data: ["isCentred": true])
        XCTAssertEqual(centred.leading, 0)
        XCTAssertEqual(centred.top, 0)

        let notCentred = try insets(json, data: ["isCentred": false])
        XCTAssertEqual(notCentred.leading, 20)
        XCTAssertEqual(notCentred.top, 10)
    }

    /// One axis at a time: a bound `centerHorizontal` must not zero the
    /// vertical margin.
    func testBoundHorizontalCentringLeavesTheVerticalMargin() throws {
        let result = try insets("""
        { "type": "View", "leftMargin": 20, "rightMargin": 20,
          "topMargin": 10, "bottomMargin": 10,
          "centerHorizontal": "@{h}" }
        """, data: ["h": true])

        XCTAssertEqual(result.leading, 0)
        XCTAssertEqual(result.top, 10)
    }

    // MARK: - The regression

    func testSymmetricVerticalMarginKeepsItsSharedInset() throws {
        let result = try insets("""
        { "type": "View", "topMargin": 10, "bottomMargin": 10 }
        """)

        XCTAssertEqual(result.top, 10)
        XCTAssertEqual(result.bottom, 10)
        XCTAssertEqual(result.leading, 0)
        XCTAssertEqual(result.trailing, 0)
    }

    func testSymmetricHorizontalMarginKeepsItsSharedInset() throws {
        let result = try insets("""
        { "type": "View", "leftMargin": 24, "rightMargin": 24 }
        """)

        XCTAssertEqual(result.leading, 24)
        XCTAssertEqual(result.trailing, 24)
        XCTAssertEqual(result.top, 0)
        XCTAssertEqual(result.bottom, 0)
    }

    /// 12/4 decomposes into a shared inset of 4 plus a single-edge 8 — and the
    /// 8 is exactly what the offset emits.
    func testAsymmetricPairPadsBySmallerEdge() throws {
        let result = try insets("""
        { "type": "View", "topMargin": 12, "bottomMargin": 4 }
        """)

        XCTAssertEqual(result.top, 4)
        XCTAssertEqual(result.bottom, 4)
    }

    // MARK: - What must not change

    /// The measured case behind the contract: a single declared edge is the
    /// offset's alone. Padding it here double-applied it (+12pt for a
    /// declared 8 in the centred conformance frame).
    func testSingleDeclaredEdgeLiftsNothing() throws {
        let result = try insets("""
        { "type": "View", "topMargin": 8, "leftMargin": 8 }
        """)

        XCTAssertEqual(result.top, 0)
        XCTAssertEqual(result.leading, 0)
        XCTAssertEqual(result.bottom, 0)
        XCTAssertEqual(result.trailing, 0)
    }

    func testCentredAxisLiftsNothing() throws {
        let result = try insets("""
        { "type": "View", "leftMargin": 24, "rightMargin": 24, "centerHorizontal": true }
        """)

        XCTAssertEqual(result.leading, 0)
        XCTAssertEqual(result.trailing, 0)
    }

    func testCenterInParentLiftsNeitherAxis() throws {
        let result = try insets("""
        {
            "type": "View", "centerInParent": true,
            "topMargin": 10, "bottomMargin": 10, "leftMargin": 24, "rightMargin": 24
        }
        """)

        XCTAssertEqual(result.top, 0)
        XCTAssertEqual(result.bottom, 0)
        XCTAssertEqual(result.leading, 0)
        XCTAssertEqual(result.trailing, 0)
    }

    func testUncentredAxisStillLifts() throws {
        let result = try insets("""
        {
            "type": "View", "centerVertical": true,
            "topMargin": 10, "bottomMargin": 10, "leftMargin": 24, "rightMargin": 24
        }
        """)

        XCTAssertEqual(result.top, 0)
        XCTAssertEqual(result.bottom, 0)
        XCTAssertEqual(result.leading, 24)
        XCTAssertEqual(result.trailing, 24)
    }

    /// A mixed-sign pair has no common inset to lift; it stays with the offset.
    func testMixedSignPairLiftsNothing() throws {
        let result = try insets("""
        { "type": "View", "leftMargin": -8, "rightMargin": 12 }
        """)

        XCTAssertEqual(result.leading, 0)
        XCTAssertEqual(result.trailing, 0)
    }

    // MARK: - start/endMargin, which the offset never owned

    func testStartAndEndMarginKeepTheirPadding() throws {
        let result = try insets("""
        { "type": "View", "startMargin": 12, "endMargin": 6 }
        """)

        XCTAssertEqual(result.leading, 12)
        XCTAssertEqual(result.trailing, 6)
    }

    func testStartMarginWinsOverTheSharedLeftRightInset() throws {
        let result = try insets("""
        { "type": "View", "startMargin": 12, "leftMargin": 24, "rightMargin": 24 }
        """)

        XCTAssertEqual(result.leading, 12)
        XCTAssertEqual(result.trailing, 24)
    }

    // MARK: - Bindings

    func testBoundSymmetricMarginResolvesBeforeSplitting() throws {
        let result = try insets("""
        { "type": "View", "topMargin": "@{gap}", "bottomMargin": "@{gap}" }
        """, data: ["gap": 16])

        XCTAssertEqual(result.top, 16)
        XCTAssertEqual(result.bottom, 16)
    }
}
#endif
