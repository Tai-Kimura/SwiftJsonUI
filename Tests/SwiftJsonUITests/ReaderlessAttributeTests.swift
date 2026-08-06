//
//  ReaderlessAttributeTests.swift
//  SwiftJsonUITests
//
//  Parity hand-off (49-B → F): declared attributes whose dynamic side had a
//  decode slot but no reader, or a reader that was never handed `data`.
//
//  - Radio.spacing: both radio rows opened a bare `HStack {`, so a declared
//    spacing moved nothing (codegen: radio_converter.rb icon_text_spacing).
//  - Radio font/fontSize bound: both call sites used the data-less
//    fontFromComponent, whose `.value`-only size read drops a binding.
//  - fontFromComponent(data:): the data overload resolved only a bound
//    `font`; a bound `fontSize` on its own fell through to the data-less
//    fallback and rendered the configured default.
//  - Collection.itemWeight: no reader at all (codegen:
//    collection_converter.rb apply_item_weight → containerRelativeFrame).
//  - Family-less fonts now route through resolveFont so a configured
//    fontProvider sees them — same output as the old `.system` tail when no
//    provider is set.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ReaderlessAttributeTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    override func tearDown() {
        SwiftJsonUIConfiguration.shared.fontProvider = nil
        super.tearDown()
    }

    // MARK: - Radio.spacing (through the row read both shapes use)

    func testDeclaredSpacingReachesTheRow() throws {
        let c = try component(#"{ "type": "Radio", "text": "Sample", "spacing": 16 }"#)
        XCTAssertEqual(RadioConverter.iconTextSpacing(c, data: [:]), 16)
    }

    func testBoundSpacingResolvesFromData() throws {
        let c = try component(#"{ "type": "Radio", "text": "Sample", "spacing": "@{gap}" }"#)
        XCTAssertEqual(RadioConverter.iconTextSpacing(c, data: ["gap": 12]), 12)
    }

    func testUndeclaredSpacingIsDefaultNotZero() throws {
        let c = try component(#"{ "type": "Radio", "text": "Sample" }"#)
        XCTAssertNil(
            RadioConverter.iconTextSpacing(c, data: [:]),
            "codegen opens a bare HStack — absent must stay SwiftUI's default, not 0"
        )
    }

    // MARK: - Radio bound font/fontSize (through the converter's own read)

    func testBoundFontSizeReachesTheRadioFont() throws {
        let c = try component(#"{ "type": "Radio", "text": "Sample", "fontSize": "@{boundFontSize}" }"#)
        let font = RadioConverter.radioFont(c, data: ["boundFontSize": 20])
        XCTAssertEqual(
            font,
            SwiftJsonUIConfiguration.shared.resolveFont(
                FontSpec(family: nil, weight: SwiftJsonUIConfiguration.shared.font.weight, size: 20)
            ),
            "a bound fontSize must reach the size, not fall to the configured default"
        )
    }

    func testBoundFontWeightNameReachesTheRadioFont() throws {
        let c = try component(#"{ "type": "Radio", "text": "Sample", "font": "@{f}", "fontSize": 20 }"#)
        XCTAssertEqual(
            RadioConverter.radioFont(c, data: ["f": "bold"]),
            .system(size: 20, weight: .bold)
        )
    }

    // MARK: - fontFromComponent(data:) — the bound-size path itself

    func testDataOverloadResolvesBoundSizeWithoutBoundFont() throws {
        let c = try component(#"{ "type": "Label", "fontSize": "@{s}" }"#)
        XCTAssertEqual(
            DynamicHelpers.fontFromComponent(c, data: ["s": 33]),
            SwiftJsonUIConfiguration.shared.resolveFont(
                FontSpec(family: nil, weight: SwiftJsonUIConfiguration.shared.font.weight, size: 33)
            )
        )
    }

    func testDataLessReadStillDropsBoundSizeToDefault() throws {
        // The data-less overload keeps its documented contract: a bound size
        // stays unresolved (LabelConverter resolves on its own path).
        let c = try component(#"{ "type": "Label", "fontSize": "@{s}", "font": "bold" }"#)
        let config = SwiftJsonUIConfiguration.shared
        XCTAssertEqual(
            DynamicHelpers.fontFromComponent(c),
            config.resolveFont(FontSpec(family: nil, weight: .bold, size: config.font.size))
        )
    }

    // MARK: - fontProvider sees family-less fonts

    func testFamilyLessFontRoutesThroughTheProvider() throws {
        SwiftJsonUIConfiguration.shared.fontProvider = { spec in
            Font.custom("Courier", size: spec.size ?? 10)
        }
        let c = try component(#"{ "type": "Label", "fontSize": 20 }"#)
        XCTAssertEqual(
            DynamicHelpers.fontFromComponent(c),
            Font.custom("Courier", size: 20),
            "codegen's apply_font_modifiers always goes through resolveFont — the dynamic half must too"
        )
    }

    // MARK: - Collection.itemWeight (through the count read the modifier uses)

    func testItemWeightHalfIsTwoColumns() throws {
        let c = try component(#"{ "type": "Collection", "itemWeight": 0.5 }"#)
        XCTAssertEqual(CollectionConverter.itemWeightCount(c), 2)
    }

    func testItemWeightThirdRounds() throws {
        let c = try component(#"{ "type": "Collection", "itemWeight": 0.34 }"#)
        XCTAssertEqual(CollectionConverter.itemWeightCount(c), 3, "round(1/0.34) — same rounding as Ruby's .round")
    }

    func testItemWeightOutOfRangeIsInert() throws {
        let over = try component(#"{ "type": "Collection", "itemWeight": 1.5 }"#)
        XCTAssertNil(CollectionConverter.itemWeightCount(over))
        let zero = try component(#"{ "type": "Collection", "itemWeight": 0 }"#)
        XCTAssertNil(CollectionConverter.itemWeightCount(zero))
        let absent = try component(#"{ "type": "Collection" }"#)
        XCTAssertNil(CollectionConverter.itemWeightCount(absent))
    }
}
#endif // DEBUG
