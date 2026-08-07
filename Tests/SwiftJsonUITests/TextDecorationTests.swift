//
//  TextDecorationTests.swift
//  SwiftJsonUITests
//
//  The OBJECT face of `underline` / `strikethrough`. Presence was read
//  everywhere and the contents nowhere, so `{lineStyle, color, lineOffset}`
//  and a bare `true` drew the same picture by construction — the
//  `presence-only` class in codegen_effect.json and the {styled, true} pair in
//  value_discrimination.json.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class TextDecorationTests: XCTestCase {

    private func label(_ dict: [String: Any]) -> DynamicComponent {
        var d: [String: Any] = ["type": "Label", "text": "Sample"]
        d.merge(dict) { _, new in new }
        let data = try! JSONSerialization.data(withJSONObject: d)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    // The boolean face keeps the plain-line rendering it always had: no
    // decoration means the modifiers inherit the foreground colour.
    func testBooleanFaceCarriesNoStyle() {
        let c = label(["underline": true])
        XCTAssertTrue(c.decorationFlag(\.underline))
        XCTAssertNil(c.decorationStyle(\.underline))
    }

    func testObjectFaceReadsColourStyleAndOffset() {
        let c = label(["underline": ["color": "#FF0000", "lineStyle": "Single", "lineOffset": 2]])
        XCTAssertTrue(c.decorationFlag(\.underline), "the object face still draws a line")
        let d = c.decorationStyle(\.underline)
        XCTAssertNotNil(d)
        XCTAssertEqual(d?.lineStyle, .single)
        XCTAssertEqual(d?.lineOffset, 2)
        XCTAssertEqual(d?.color, DynamicHelpers.getColor("#FF0000"))
        XCTAssertTrue(d?.isStyled == true, "a declared colour is what separates styled from true")
    }

    func testStrikethroughObjectFaceReadsColourAndStyle() {
        let c = label(["strikethrough": ["color": "#0000FF", "lineStyle": "Double"]])
        let d = c.decorationStyle(\.strikethrough)
        XCTAssertEqual(d?.lineStyle, .double)
        XCTAssertEqual(d?.color, DynamicHelpers.getColor("#0000FF"))
        XCTAssertNil(d?.lineOffset, "lineOffset is declared on underline only")
    }

    func testDeclaredLineStyleSpellings() {
        XCTAssertEqual(TextDecoration.LineStyle.from("Single"), .single)
        XCTAssertEqual(TextDecoration.LineStyle.from("Double"), .double)
        XCTAssertEqual(TextDecoration.LineStyle.from("Thick"), .thick)
        XCTAssertEqual(TextDecoration.LineStyle.from("None"), TextDecoration.LineStyle.none)
    }

    // Mirrors the UIKit half (SJUILabel.swift's switch), where every
    // unrecognised spelling falls to `.single`. Pinned so a later edit cannot
    // silently make the two ios halves disagree while the `None` question is
    // open with E.
    func testUnrecognisedLineStyleFallsToSingleLikeUIKit() {
        XCTAssertEqual(TextDecoration.LineStyle.from(nil), .single)
        XCTAssertEqual(TextDecoration.LineStyle.from("notAStyle"), .single)
    }

    // The colour is declared `string`, so a colours.json name has to resolve
    // the same way every other colour read does.
    func testColourResolvesThroughTheSharedReader() {
        let c = label(["underline": ["color": "#00FF00"]])
        XCTAssertEqual(c.decorationStyle(\.underline)?.color, DynamicHelpers.getColor("#00FF00"))
    }
}
#endif
