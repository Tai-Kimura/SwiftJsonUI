//
//  NumericFontWeightTests.swift
//  SwiftJsonUITests
//
//  `fontWeight` is declared `string|number|binding`, so `fontWeight: 600` is
//  as declared a spelling as `"semibold"`.
//
//  Run 4 parity put `Button/fontWeight__600` and `Label/fontWeight__600` at
//  distance 11 between ios dynamic and ios codegen. Measured on both sides:
//  the generated table carries the Int the layout wrote, `rawRepresentation
//  as? String` is nil for it, and dynamic dropped the weight — while
//  font_helper.rb#font_weight_to_swiftui maps 600 through the shared table.
//
//  The numbers come from shared/core/font_weight_mapping.json (css → swift),
//  which kjui and rjui read too. Changing them here without changing that
//  file re-splits the platforms.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class NumericFontWeightTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    func testNumericSpellingSurvivesTheRead() throws {
        for type in ["Button", "Label"] {
            let c = try component(#"{ "type": "\#(type)", "text": "x", "fontWeight": 600 }"#)
            XCTAssertEqual(
                c.fontWeightSpelling(), "600",
                "\(type): the numeric spelling is declared and must not be dropped"
            )
        }
    }

    func testStringSpellingStillReads() throws {
        let c = try component(#"{ "type": "Label", "text": "x", "fontWeight": "semibold" }"#)
        XCTAssertEqual(c.fontWeightSpelling(), "semibold")
    }

    /// A weight the layout declares must reach the rendered font. Going
    /// through `fontFromComponent` rather than the mapping table directly:
    /// the defect was in the read, and a test that skips the read stays green
    /// while the converter feeds it nil.
    func testEveryNumericWeightReachesTheFont() throws {
        let expected: [(Int, Font.Weight)] = [
            (100, .thin), (200, .ultraLight), (300, .light), (400, .regular),
            (500, .medium), (600, .semibold), (700, .bold), (900, .heavy),
        ]
        for (number, weight) in expected {
            let c = try component(#"{ "type": "Label", "text": "x", "fontWeight": \#(number) }"#)
            XCTAssertEqual(
                DynamicDecodingHelper.fontFromComponent(c),
                .system(size: SwiftJsonUIConfiguration.shared.font.size, weight: weight),
                "fontWeight: \(number) must resolve to the shared table's weight"
            )
        }
    }

    /// An undeclared number is not in the table and must not invent a weight.
    func testUnknownNumberFallsBackRatherThanGuessing() throws {
        let c = try component(#"{ "type": "Label", "text": "x", "fontWeight": 550 }"#)
        XCTAssertEqual(c.fontWeightSpelling(), "550", "the spelling is still read")
        XCTAssertEqual(
            DynamicDecodingHelper.fontFromComponent(c),
            .system(size: SwiftJsonUIConfiguration.shared.font.size,
                    weight: SwiftJsonUIConfiguration.shared.font.weight),
            "…but 550 has no entry, so the configured default stands"
        )
    }
}
#endif
