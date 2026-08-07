//
//  BoundPaddingTests.swift
//  SwiftJsonUITests
//
//  `padding` / `paddings` declared as a binding. They are carried as
//  AnyCodable, so a bound spelling arrives as the STRING "@{expr}" and the
//  literal-only decode answered nil for it — the declaration inset nothing
//  while the per-edge overrides resolved fine, and while the codegen already
//  emitted the resolved value (spacing_helper.rb#padding_value, plan 49).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class BoundPaddingTests: XCTestCase {

    private func component(_ dict: [String: Any]) -> DynamicComponent {
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    // A literal declaration keeps resolving exactly as it did — the bound
    // support must not be bought with a regression on the common shape.
    func testLiteralUniformPaddingIsUnchanged() {
        let c = component(["type": "View", "padding": 8])
        let insets = DynamicHelpers.getPadding(from: c)
        XCTAssertEqual(insets.top, 8)
        XCTAssertEqual(insets.leading, 8)
        XCTAssertEqual(insets.bottom, 8)
        XCTAssertEqual(insets.trailing, 8)
    }

    // The 4-element order is UIKit's — [top, RIGHT, bottom, LEFT] — which is
    // what `edgeInsetsFromArray` implements and what spacing_helper.rb emits.
    func testLiteralArrayPaddingIsUnchanged() {
        let c = component(["type": "View", "paddings": [1, 2, 3, 4]])
        let insets = DynamicHelpers.getPadding(from: c)
        XCTAssertEqual(insets.top, 1)
        XCTAssertEqual(insets.trailing, 2)
        XCTAssertEqual(insets.bottom, 3)
        XCTAssertEqual(insets.leading, 4)
    }

    // The defect: `padding: "@{boundPadding}"` inset nothing at all.
    func testBoundUniformPaddingResolves() {
        let c = component(["type": "View", "padding": "@{boundPadding}"])
        let insets = DynamicHelpers.getPadding(from: c, data: ["boundPadding": 8])
        XCTAssertEqual(insets.top, 8)
        XCTAssertEqual(insets.leading, 8)
        XCTAssertEqual(insets.bottom, 8)
        XCTAssertEqual(insets.trailing, 8)
    }

    // Both sides of the boundary are pinned: with NO data the bound spelling
    // must stay 0 rather than coerce the literal "@{...}" into a number.
    func testBoundPaddingWithoutDataInsetsNothing() {
        let c = component(["type": "View", "padding": "@{boundPadding}"])
        let insets = DynamicHelpers.getPadding(from: c, data: [:])
        XCTAssertEqual(insets.top, 0)
        XCTAssertEqual(insets.leading, 0)
    }

    func testBoundArrayPaddingResolves() {
        let c = component(["type": "View", "paddings": "@{boundPaddings}"])
        let insets = DynamicHelpers.getPadding(from: c, data: ["boundPaddings": [1, 2, 3, 4]])
        XCTAssertEqual(insets.top, 1)
        XCTAssertEqual(insets.trailing, 2)
        XCTAssertEqual(insets.bottom, 3)
        XCTAssertEqual(insets.leading, 4)
    }

    // The per-edge spellings read the literal half only (`commonNumber`), so a
    // bound edge fell to 0 the same way the uniform spelling did.
    func testBoundPerEdgePaddingResolves() {
        let c = component(["type": "View", "paddingTop": "@{boundTop}"])
        let insets = DynamicHelpers.getPadding(from: c, data: ["boundTop": 12])
        XCTAssertEqual(insets.top, 12)
        XCTAssertEqual(insets.leading, 0)
    }
}
#endif
