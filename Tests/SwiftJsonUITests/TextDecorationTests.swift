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

    // An unrecognised or absent spelling means "a line, unstyled" — the same
    // thing the boolean face means.
    func testUnrecognisedLineStyleFallsToSingle() {
        XCTAssertEqual(TextDecoration.LineStyle.from(nil), .single)
        XCTAssertEqual(TextDecoration.LineStyle.from("notAStyle"), .single)
    }

    // `lineStyle: None` asks for NO line. This is the convention the ios
    // codegen settled on (51-B), matched here so the two ios paths cannot
    // answer differently — and it is what keeps the declared value from being
    // pixel-identical to `Single`.
    func testNoneDrawsNoLineOnEveryEntryPoint() {
        let c = label(["underline": ["lineStyle": "None", "color": "#FF0000"]])
        XCTAssertFalse(c.decorationFlag(\.underline), "None must not draw a line")
        XCTAssertNil(c.decorationStyle(\.underline), "None carries no style to draw")
        XCTAssertFalse(TextDecoration.draws(["lineStyle": "None"]))
        XCTAssertNil(TextDecoration(from: ["lineStyle": "None", "color": "#FF0000"]))
    }

    // The boolean and object faces still turn the line ON.
    func testDrawsAgreesAcrossTheDeclaredFaces() {
        XCTAssertTrue(TextDecoration.draws(true))
        XCTAssertFalse(TextDecoration.draws(false))
        XCTAssertFalse(TextDecoration.draws(nil))
        XCTAssertTrue(TextDecoration.draws(["lineStyle": "Single"]))
        XCTAssertTrue(TextDecoration.draws(["color": "#FF0000"]))
        // `underline` is declared boolean|object|ARRAY; the array face draws.
        XCTAssertTrue(TextDecoration.draws(["Single"]))
    }

    // The colour is declared `string`, so a colours.json name has to resolve
    // the same way every other colour read does.
    func testColourResolvesThroughTheSharedReader() {
        let c = label(["underline": ["color": "#00FF00"]])
        XCTAssertEqual(c.decorationStyle(\.underline)?.color, DynamicHelpers.getColor("#00FF00"))
    }
}
#endif
