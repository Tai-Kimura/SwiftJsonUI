//
//  ButtonFontFamilyTests.swift
//  SwiftJsonUITests
//
//  Regression for the Button.fontFamily face (the codegen_effect ios rows):
//  StateAwareButtonView carries the family into PartialAttributedText, whose
//  FontSpec path hands family + weight + size to
//  SwiftJsonUIConfiguration.fontProvider — the declared semantics.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class ButtonFontFamilyTests: XCTestCase {

    // MARK: - StateAwareButtonView parameter (library face)

    /// The designated initializer takes `fontFamily` and stores it. Before
    /// the face landed, the codegen emit `fontFamily: "..."` was an
    /// "extra argument in call" compile error.
    func testDesignatedInitStoresFontFamily() {
        let view = StateAwareButtonView(
            text: "Go",
            action: {},
            fontSize: 20,
            fontWeight: .bold,
            fontFamily: "Noto Sans JP"
        )
        XCTAssertEqual(view.fontFamily, "Noto Sans JP")
    }

    /// The string-fontWeight convenience initializer (the one static codegen
    /// picks for a quoted weight) forwards the family unchanged.
    func testStringWeightConvenienceInitForwardsFontFamily() {
        let view = StateAwareButtonView(
            text: "Go",
            action: {},
            fontWeight: "bold",
            fontFamily: "Noto Sans JP"
        )
        XCTAssertEqual(view.fontFamily, "Noto Sans JP")
        XCTAssertEqual(view.fontWeight, .bold)
    }

    /// Omitting the parameter keeps the pre-face behavior: no family, system
    /// font resolution.
    func testFontFamilyDefaultsToNil() {
        let view = StateAwareButtonView(text: "Go", action: {})
        XCTAssertNil(view.fontFamily)
    }

    #if DEBUG
    // MARK: - Dynamic decode (ButtonAttributes.fontFamily)

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    /// A literal family decodes as the raw string the dynamic converter
    /// passes straight through.
    func testButtonAttributesDecodeLiteralFontFamily() throws {
        let c = try component("""
        { "type": "Button", "text": "Go", "fontFamily": "Noto Sans JP" }
        """)
        XCTAssertEqual(
            c.typedAttributes(ButtonAttributes.self).fontFamily?.rawRepresentation as? String,
            "Noto Sans JP"
        )
    }

    /// A bound family surfaces its binding expression; the converter resolves
    /// it through DynamicBindingResolver against the data dictionary (same
    /// resolution as LabelConverter).
    func testButtonAttributesBoundFontFamilyResolves() throws {
        let c = try component("""
        { "type": "Button", "text": "Go", "fontFamily": "@{fam}" }
        """)
        let attr = c.typedAttributes(ButtonAttributes.self).fontFamily
        XCTAssertEqual(attr?.bindingExpression, "fam")
        XCTAssertEqual(
            DynamicBindingResolver.resolveString(expression: "fam", data: ["fam": "Avenir Next"]),
            "Avenir Next"
        )
    }
    #endif // DEBUG
}
