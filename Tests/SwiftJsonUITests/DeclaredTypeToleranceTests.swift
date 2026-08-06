//
//  DeclaredTypeToleranceTests.swift
//  SwiftJsonUITests
//
//  Attributes whose declaration allows more than one JSON type, measured by
//  decoding the zero-population type of each (run-4 type sweep).
//
//  `underline` / `strikethrough` are declared `boolean|object|array`; the
//  hand-decoded `Bool?` slot THREW on the object form, and children go
//  through FailableDecodable — so `underline: {"lineStyle": "Single"}`
//  replaced the whole Label with an error placeholder. codegen never threw:
//  label_converter.rb tests Ruby truthiness, so an object underlines.
//  Same node-deletion mechanism as `fontSize: "@{x}"`, this wave's opening
//  find, arriving through a third door (bound spelling, string-boolean
//  spelling, and now the object spelling).
//
//  `weight` is declared `number|string|binding`; codegen reads the string
//  with `.to_f > 0`, dynamic's unwrapDouble had no String branch.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class DeclaredTypeToleranceTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    // MARK: - underline / strikethrough

    /// The severe half: the object form must not throw, and a Label carrying
    /// it must stay a Label.
    func testObjectUnderlineDoesNotDeleteTheNode() throws {
        let parent = try component("""
        { "type": "View", "child": [
            { "type": "Label", "text": "x",
              "underline": {"lineStyle": "Single", "color": "#FF0000"} } ] }
        """)
        let child = parent.childComponents?.first
        XCTAssertEqual(child?.type, "Label", "not __jui_decode_error__")
        XCTAssertTrue(child?.decorationFlag(\.underline) ?? false,
                      "codegen truthiness: an object underlines")
    }

    func testObjectStrikethroughDoesNotDeleteTheNode() throws {
        let c = try component(#"{ "type": "Label", "text": "x", "strikethrough": {"lineStyle": "Single"} }"#)
        XCTAssertEqual(c.type, "Label")
        XCTAssertTrue(c.decorationFlag(\.strikethrough))
    }

    func testBooleanSpellingKeepsItsMeaning() throws {
        let on = try component(#"{ "type": "Label", "text": "x", "underline": true }"#)
        XCTAssertTrue(on.decorationFlag(\.underline))
        let off = try component(#"{ "type": "Label", "text": "x", "underline": false }"#)
        XCTAssertFalse(off.decorationFlag(\.underline),
                       "false is the one non-nil value that means OFF — Ruby truthiness")
        let absent = try component(#"{ "type": "Label", "text": "x" }"#)
        XCTAssertFalse(absent.decorationFlag(\.underline))
    }

    func testArraySpellingUnderlines() throws {
        let c = try component(#"{ "type": "Label", "text": "x", "underline": ["Single"] }"#)
        XCTAssertTrue(c.decorationFlag(\.underline))
    }

    // MARK: - weight string

    /// `weight: "1"` weighs 1 — `.to_f` semantics, matching
    /// label_converter.rb:329.
    func testStringWeightWeighs() throws {
        let c = try component(#"{ "type": "View", "weight": "1" }"#)
        XCTAssertEqual(DynamicHelpers.resolveWeight(from: c, data: [:]), 1)
    }

    func testNumberWeightStillWeighs() throws {
        let c = try component(#"{ "type": "View", "weight": 2 }"#)
        XCTAssertEqual(DynamicHelpers.resolveWeight(from: c, data: [:]), 2)
    }

    /// A non-numeric string is not a weight; nil, not 0 — the callers gate
    /// on `> 0` and nil keeps them out of the weighted path entirely.
    func testNonNumericStringIsNotAWeight() throws {
        let c = try component(#"{ "type": "View", "weight": "heavy" }"#)
        XCTAssertNil(DynamicHelpers.resolveWeight(from: c, data: [:]))
    }
}
#endif
