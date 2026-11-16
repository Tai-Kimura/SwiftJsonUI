//
//  OnClickArrayTests.swift
//  SwiftJsonUITests
//
//  `onclick` is declared `["string", "array"]` — the array spelling names
//  several selectors and every one of them fires.
//
//  base_view_converter.rb:658 has always emitted one call per name
//  (`names = value.is_a?(Array) ? value : [value]`). Dynamic read the
//  attribute as `as? String`, which is nil for an array, so it fired
//  NOTHING where codegen fired two handlers. Found by sweeping the
//  generated tables by declared CONTENT type rather than by wrapper kind
//  (the wrapper sweep that caught `contentMode` could not see this).
//
//  Fired in declaration order: the array is a sequence, and the generated
//  Swift calls them top to bottom.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class OnClickArrayTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    func testArraySpellingNamesEveryHandler() throws {
        let c = try component(#"{ "type": "View", "onclick": ["first", "second"] }"#)
        XCTAssertEqual(c.effectiveOnClickHandlers, ["first", "second"])
    }

    func testStringSpellingStillNamesOne() throws {
        let c = try component(#"{ "type": "View", "onclick": "only" }"#)
        XCTAssertEqual(c.effectiveOnClickHandlers, ["only"])
    }

    /// `onClick` (camelCase, binding-only) wins over the legacy spelling —
    /// the precedence the single-value accessor always had.
    func testCamelCaseBindingWins() throws {
        let c = try component(#"{ "type": "View", "onClick": "@{bound}", "onclick": ["a", "b"] }"#)
        XCTAssertEqual(c.effectiveOnClickHandlers, ["@{bound}"])
        XCTAssertEqual(c.effectiveOnClick, "@{bound}")
    }

    func testUndeclaredIsEmptyNotACrash() throws {
        let c = try component(#"{ "type": "View" }"#)
        XCTAssertTrue(c.effectiveOnClickHandlers.isEmpty)
        XCTAssertNil(c.effectiveOnClick)
    }

    /// The whole point: every named handler is invoked, in order.
    func testAllHandlersActuallyFire() throws {
        var fired: [String] = []
        let data: [String: Any] = [
            "first": { fired.append("first") } as () -> Void,
            "second": { fired.append("second") } as () -> Void,
        ]
        let c = try component(#"{ "type": "View", "onclick": ["first", "second"] }"#)
        for handler in c.effectiveOnClickHandlers {
            DynamicEventHelper.call(handler, data: data)
        }
        XCTAssertEqual(fired, ["first", "second"], "both, in declaration order")
    }

    /// A handler names a method (TapAccessibility.namesAMethod): an empty or
    /// blank one is none, so `applyOnClick` attaches no tap. It attached one
    /// that called nothing and took the tap from the view around it
    /// (XCUITest, 2026-09-25: a row holding a Label with `"onClick": ""` did
    /// not fire when the Label was tapped).
    func testEmptyAndBlankHandlersNameNothing() throws {
        let blanks = [
            #""onClick": """#, #""onClick": "   ""#, #""onClick": "@{}""#, #""onClick": "@{ }""#,
            #""onClick": "\u3000""#, #""onclick": """#, #""onclick": "   ""#, #""onclick": []"#,
            #""onclick": ["", " "]"#,
        ]
        for blank in blanks {
            let c = try component(#"{ "type": "View", "# + blank + " }")
            XCTAssertEqual(c.effectiveOnClickHandlers, [], blank)
            XCTAssertNil(c.effectiveOnClick, blank)
        }
    }

    /// A blank element is not called; a blank onClick leaves the tap to onclick.
    func testBlankElementsAreDroppedAndBlankOnClickFallsThrough() throws {
        let array = try component(#"{ "type": "View", "onclick": ["", "first", " "] }"#)
        XCTAssertEqual(array.effectiveOnClickHandlers, ["first"])
        let fallback = try component(#"{ "type": "View", "onClick": "", "onclick": "only" }"#)
        XCTAssertEqual(fallback.effectiveOnClickHandlers, ["only"])
    }
}
#endif
