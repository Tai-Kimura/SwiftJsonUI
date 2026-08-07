//
//  VisualEffectStyleTests.swift
//  SwiftJsonUITests
//
//  The `effectStyle` vocabulary table. Every declared appearance must draw a
//  DIFFERENT picture: two declared values agreeing is a value_discrimination
//  collapsedPair, and that should not need a device run to notice.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class VisualEffectStyleTests: XCTestCase {

    func testDeclaredSpellingsNormalise() {
        XCTAssertEqual(VisualEffectStyle.from("Prominent"), .prominent)
        XCTAssertEqual(VisualEffectStyle.from("prominent"), .prominent)
        XCTAssertEqual(VisualEffectStyle.from("ExtraLight"), .extraLight)
        XCTAssertEqual(VisualEffectStyle.from("UltraThin"), .ultraThin)
        XCTAssertEqual(VisualEffectStyle.from("Chrome"), .chrome)
    }

    // The `system*Material` names are declared valueAliases of the appearance
    // names in shared/core/attribute_definitions.json.
    func testSystemMaterialAliasesFold() {
        XCTAssertEqual(VisualEffectStyle.from("systemMaterial"), .regular)
        XCTAssertEqual(VisualEffectStyle.from("systemUltraThinMaterial"), .ultraThin)
        XCTAssertEqual(VisualEffectStyle.from("systemThinMaterial"), .thin)
        XCTAssertEqual(VisualEffectStyle.from("systemThickMaterial"), .thick)
        XCTAssertEqual(VisualEffectStyle.from("systemChromeMaterial"), .chrome)
    }

    // `Regular` is the declared default and the fallback all three platforms
    // already used for an absent or unrecognised value.
    func testAbsentAndUnknownFallBackToRegular() {
        XCTAssertEqual(VisualEffectStyle.from(nil), .regular)
        XCTAssertEqual(VisualEffectStyle.from(""), .regular)
        XCTAssertEqual(VisualEffectStyle.from("  "), .regular)
        XCTAssertEqual(VisualEffectStyle.from("notAnAppearance"), .regular)
    }

    /// The collapsedPair guard, mechanically: SwiftUI ships five materials for
    /// a nine-appearance vocabulary, so four of the nine share a material and
    /// are separated by a tint. If a later edit drops a tint or points two
    /// spellings at one material with no tint, two DECLARED values start
    /// drawing the same picture — which is precisely what the
    /// value_discrimination gate exists to catch, and it should not need a
    /// device run to notice.
    func testEveryDeclaredAppearanceIsDistinct() {
        // `Material` is not Equatable, so compare its description — enough to
        // tell the five apart, which is all this assertion needs.
        let signatures = VisualEffectStyle.allCases.map { style in
            [
                String(describing: style.material),
                style.tint.map { String(describing: $0) } ?? "-",
                style.colorScheme.map { String(describing: $0) } ?? "-"
            ].joined(separator: "|")
        }
        XCTAssertEqual(
            Set(signatures).count, VisualEffectStyle.allCases.count,
            "two declared effectStyle values render identically: \(signatures)"
        )
    }

    func testColorSchemeOverrideOnlyForTheThreeAppearanceValues() {
        XCTAssertEqual(VisualEffectStyle.light.colorScheme, .light)
        XCTAssertEqual(VisualEffectStyle.extraLight.colorScheme, .light)
        XCTAssertEqual(VisualEffectStyle.dark.colorScheme, .dark)
        for style in [VisualEffectStyle.regular, .thin, .thick, .ultraThin, .chrome, .prominent] {
            XCTAssertNil(style.colorScheme, "\(style) must not override the colour scheme")
        }
    }
}
#endif
