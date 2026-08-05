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
}
#endif
