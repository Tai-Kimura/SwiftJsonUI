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

    // MARK: - NetworkImage url (declared alias of src; L0 keeps the fallback)

    func testUrlSpellingReachesTheLoader() throws {
        let c = try component(#"{ "type": "NetworkImage", "url": "https://example.com/a.png" }"#)
        XCTAssertEqual(
            NetworkImageConverter.declaredURL(c, data: [:]),
            "https://example.com/a.png",
            "a raw layout writing the declared `url` alias must still load — " +
            "dropping it hands the view no url and the idle branch draws Color.clear"
        )
    }

    func testBoundUrlSpellingResolves() throws {
        let c = try component(#"{ "type": "NetworkImage", "url": "@{imageUrl}" }"#)
        XCTAssertEqual(
            NetworkImageConverter.declaredURL(c, data: ["imageUrl": "https://example.com/b.png"]),
            "https://example.com/b.png"
        )
    }

    func testCanonicalSrcStillWinsAndResolves() throws {
        let c = try component(#"{ "type": "NetworkImage", "src": "https://example.com/c.png", "url": "https://example.com/ignored.png" }"#)
        XCTAssertEqual(
            NetworkImageConverter.declaredURL(c, data: [:]),
            "https://example.com/c.png",
            "canonical spelling first — the alias is the fallback"
        )
    }

    // MARK: - Same-family converters (Table / Toggle / Picker / TextField)

    func testBoundFontSizeReachesEachConverterFont() throws {
        let expected = SwiftJsonUIConfiguration.shared.resolveFont(
            FontSpec(family: nil, weight: SwiftJsonUIConfiguration.shared.font.weight, size: 21)
        )
        let data: [String: Any] = ["s": 21]
        let table = try component(#"{ "type": "Table", "fontSize": "@{s}" }"#)
        XCTAssertEqual(TableConverter.declaredFont(table, data: data), expected)
        let toggle = try component(#"{ "type": "Switch", "fontSize": "@{s}" }"#)
        XCTAssertEqual(ToggleConverter.declaredFont(toggle, data: data), expected)
        let picker = try component(#"{ "type": "SelectBox", "fontSize": "@{s}" }"#)
        XCTAssertEqual(PickerConverter.declaredFont(picker, data: data), expected)
        let field = try component(#"{ "type": "TextField", "fontSize": "@{s}" }"#)
        XCTAssertEqual(TextFieldConverter.declaredFont(field, data: data), expected)
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

    func testItemWeightDrivesTheGridColumns() throws {
        // Per-item width is the canonical semantics (UIKit:
        // itemSize.width = W * weight) — in a grid that IS the column count,
        // and the weight wins over a conflicting `columns`.
        let weighted = try component(#"{ "type": "Collection", "itemWeight": 0.5, "columns": 3 }"#)
        XCTAssertEqual(CollectionConverter.effectiveGridColumns(weighted, declared: 3), 2)
        let plain = try component(#"{ "type": "Collection", "columns": 3 }"#)
        XCTAssertEqual(CollectionConverter.effectiveGridColumns(plain, declared: 3), 3)
    }
}
#endif // DEBUG
