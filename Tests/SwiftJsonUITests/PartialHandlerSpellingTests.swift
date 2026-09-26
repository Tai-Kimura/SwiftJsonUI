//
//  PartialHandlerSpellingTests.swift
//  SwiftJsonUITests
//
//  A partialAttributes range's handler is read in both declared spellings:
//  `onClick` (canonical, a binding) and `onclick` (its alias, a selector),
//  the canonical one first when both are written (4f ruling, jsonui-cli
//  1.9.0). The Label's and the Button's ranges read it the same way.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class PartialHandlerSpellingTests: XCTestCase {

    func testBothSpellingsAreReadAndTheCanonicalOneWins() {
        let cases: [(String, [String: Any], String?)] = [
            ("onClick binding", ["onClick": "@{onTerms}"], "onTerms"),
            ("onclick selector", ["onclick": "onTerms"], "onTerms"),
            ("both: onClick wins", ["onClick": "@{onTerms}", "onclick": "onOther"], "onTerms"),
            ("onClick not a binding: the alias is read", ["onClick": "onTerms", "onclick": "onOther"], "onOther"),
            ("onclick as a binding is no selector", ["onclick": "@{onTerms}"], nil),
            ("blank", ["onClick": "@{ }", "onclick": " "], nil),
            ("none", [:], nil),
        ]
        for (name, dict, want) in cases {
            XCTAssertEqual(LabelConverter.partialHandlerName(dict), want, name)
        }
    }

    /// Through the Label: a range spelled either way calls its handler.
    func testTheLabelsRangeCallsItsHandlerInEitherSpelling() throws {
        for spelling in [#""onClick": "@{onTerms}""#, #""onclick": "onTerms""#] {
            var calls = 0
            let json = #"{"type": "Label", "id": "l", "text": "Terms and more", "partialAttributes": [{"range": "Terms", \#(spelling)}]}"#
            let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
            let handler: () -> Void = { calls += 1 }
            let attrs = LabelConverter.partialAttributesForTest(component: component, data: ["onTerms": handler])
            XCTAssertEqual(attrs.count, 1, spelling)
            attrs.first?.onClick?()
            XCTAssertEqual(calls, 1, spelling)
        }
    }
}
#endif
