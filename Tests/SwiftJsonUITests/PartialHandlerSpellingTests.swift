//
//  PartialHandlerSpellingTests.swift
//  SwiftJsonUITests
//
//  A partialAttributes range's handler is read in both declared spellings:
//  `onClick` (canonical) and `onclick` (its alias), each a binding or a
//  method name, the canonical one first when both are written. jsonui-cli
//  1.9.0 folds `onclick` into `onClick` in the layouts `jui build`
//  distributes, so a name arrives in onClick. The Label's and the Button's
//  ranges read it the same way, and so does the UIKit label.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class PartialHandlerSpellingTests: XCTestCase {

    func testBothSpellingsAreReadAndTheCanonicalOneWins() {
        let cases: [(String, [String: Any], String?)] = [
            ("onClick binding", ["onClick": "@{onTerms}"], "onTerms"),
            ("onclick selector", ["onclick": "onTerms"], "onTerms"),
            ("onClick holding a name (the alias folded)", ["onClick": "onTerms"], "onTerms"),
            ("onclick holding a binding", ["onclick": "@{onTerms}"], "onTerms"),
            ("both: onClick wins", ["onClick": "@{onTerms}", "onclick": "onOther"], "onTerms"),
            ("both names: onClick wins", ["onClick": "onTerms", "onclick": "onOther"], "onTerms"),
            ("onClick neither a binding nor a name: the alias is read", ["onClick": "@{onTerms} now", "onclick": "onOther"], "onOther"),
            ("blank binding: the alias is read", ["onClick": "@{ }", "onclick": "onOther"], "onOther"),
            ("blank", ["onClick": "@{ }", "onclick": " "], nil),
            ("none", [:], nil),
        ]
        for (name, dict, want) in cases {
            XCTAssertEqual(LabelConverter.partialHandlerName(dict), want, name)
        }
    }

    /// The UIKit label reads the same rule: a name is the selector it
    /// performs, a binding the closure the generated code sets
    /// (setPartialAttributeOnClick), and none is no linked range.
    func testTheUIKitLabelsRangeReadsTheSameRule() {
        typealias H = PartialRangeHandler
        let cases: [(String, [String: Any], H?)] = [
            ("onClick binding", ["onClick": "@{onTerms}"], .binding),
            ("onclick selector", ["onclick": "onTerms"], .selector("onTerms")),
            ("onClick holding a name (the alias folded)", ["onClick": "onTerms"], .selector("onTerms")),
            ("onclick holding a binding", ["onclick": "@{onTerms}"], .binding),
            ("both: onClick wins", ["onClick": "@{onTerms}", "onclick": "onOther"], .binding),
            ("both names: onClick wins", ["onClick": "onTerms", "onclick": "onOther"], .selector("onTerms")),
            ("onClick neither a binding nor a name: the alias is read", ["onClick": "@{onTerms} now", "onclick": "onOther"], .selector("onOther")),
            ("blank", ["onClick": "@{ }", "onclick": " "], nil),
            ("none", [:], nil),
        ]
        for (name, dict, want) in cases {
            XCTAssertEqual(H(JSON(dict)), want, name)
        }
        // Through the label: a folded name is a linked range with its selector.
        let label = SJUILabel()
        _ = NSAttributedString(string: "Terms and more").applyAttributesFromJSON(
            attrs: [JSON(["range": [[0, 5]], "onClick": "onTerms"])], toLabel: label)
        XCTAssertEqual(label.linkedRanges.count, 1)
        XCTAssertEqual(label.linkedRanges.first?["onclick"] as? String, "onTerms")
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
