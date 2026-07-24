//
//  FontSpecTests.swift
//  SwiftJsonUITests
//
//  Tests for FontSpec + SwiftJsonUIConfiguration.resolveFont(_:) — the
//  unified font-provider entry point introduced in 9.5.0.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class FontSpecTests: XCTestCase {

    override func tearDown() {
        // Always release the singleton-level provider after each test so we
        // don't leak state into the rest of the test suite.
        SwiftJsonUIConfiguration.shared.fontProvider = nil
        super.tearDown()
    }

    // MARK: - FontSpec value semantics

    func testFontSpecDefaultInit() {
        let spec = FontSpec()
        XCTAssertNil(spec.family)
        XCTAssertNil(spec.weight)
        XCTAssertNil(spec.size)
        XCTAssertFalse(spec.italic)
    }

    func testFontSpecExplicitInit() {
        let spec = FontSpec(family: "Inter", weight: .bold, size: 18, italic: true)
        XCTAssertEqual(spec.family, "Inter")
        XCTAssertEqual(spec.weight, .bold)
        XCTAssertEqual(spec.size, 18)
        XCTAssertTrue(spec.italic)
    }

    func testFontSpecEquatable() {
        let a = FontSpec(family: "Inter", weight: .bold, size: 14)
        let b = FontSpec(family: "Inter", weight: .bold, size: 14)
        let c = FontSpec(family: "Inter", weight: .semibold, size: 14)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - resolveFont — provider absent (system-font fallback)

    func testResolveFontWithNoProviderUsesSystemFontForBareSpec() {
        SwiftJsonUIConfiguration.shared.fontProvider = nil

        let spec = FontSpec(weight: .bold, size: 22)
        let resolved = SwiftJsonUIConfiguration.shared.resolveFont(spec)

        XCTAssertEqual(resolved, Font.system(size: 22, weight: .bold))
    }

    func testResolveFontWithNoProviderDefaultsWeightToRegular() {
        SwiftJsonUIConfiguration.shared.fontProvider = nil

        let spec = FontSpec(size: 13)
        let resolved = SwiftJsonUIConfiguration.shared.resolveFont(spec)

        XCTAssertEqual(resolved, Font.system(size: 13, weight: .regular))
    }

    func testResolveFontWithNoProviderDefaultsSizeTo17() {
        SwiftJsonUIConfiguration.shared.fontProvider = nil

        let resolved = SwiftJsonUIConfiguration.shared.resolveFont(FontSpec())
        XCTAssertEqual(resolved, Font.system(size: 17, weight: .regular))
    }

    // MARK: - resolveFont — provider present

    func testResolveFontUsesProviderWhenItReturnsNonNil() {
        let sentinel = Font.system(size: 99, weight: .black)
        SwiftJsonUIConfiguration.shared.fontProvider = { _ in sentinel }

        let resolved = SwiftJsonUIConfiguration.shared.resolveFont(
            FontSpec(family: "Inter", weight: .bold, size: 18)
        )
        XCTAssertEqual(resolved, sentinel)
    }

    func testResolveFontReceivesSpecArguments() {
        var captured: FontSpec?
        SwiftJsonUIConfiguration.shared.fontProvider = { spec in
            captured = spec
            return nil // fall through to default so we still get a Font back
        }

        let input = FontSpec(family: "Inter", weight: .semibold, size: 16, italic: true)
        _ = SwiftJsonUIConfiguration.shared.resolveFont(input)
        XCTAssertEqual(captured, input)
    }

    func testResolveFontFallsThroughWhenProviderReturnsNil() {
        SwiftJsonUIConfiguration.shared.fontProvider = { _ in nil }

        let resolved = SwiftJsonUIConfiguration.shared.resolveFont(
            FontSpec(weight: .bold, size: 20)
        )
        XCTAssertEqual(resolved, Font.system(size: 20, weight: .bold))
    }

    // MARK: - defaultFont(for:) — family branch

    func testDefaultFontWithFamilyOnlyUsesCustom() {
        let resolved = SwiftJsonUIConfiguration.defaultFont(
            for: FontSpec(family: "Helvetica", size: 14)
        )
        XCTAssertEqual(resolved, Font.custom("Helvetica", size: 14))
    }

    func testDefaultFontWithFamilyAndWeightAppliesWeight() {
        let resolved = SwiftJsonUIConfiguration.defaultFont(
            for: FontSpec(family: "Helvetica", weight: .bold, size: 14)
        )
        XCTAssertEqual(resolved, Font.custom("Helvetica", size: 14).weight(.bold))
    }

    func testDefaultFontWithFamilyMissingSizeFallsBackTo17() {
        let resolved = SwiftJsonUIConfiguration.defaultFont(
            for: FontSpec(family: "Helvetica")
        )
        XCTAssertEqual(resolved, Font.custom("Helvetica", size: 17))
    }

    // MARK: - defaultFont(for:) — italic post-fix

    func testDefaultFontItalicAppliesToSystemFont() {
        let resolved = SwiftJsonUIConfiguration.defaultFont(
            for: FontSpec(weight: .regular, size: 17, italic: true)
        )
        XCTAssertEqual(resolved, Font.system(size: 17, weight: .regular).italic())
    }

    func testDefaultFontItalicAppliesToCustomFont() {
        let resolved = SwiftJsonUIConfiguration.defaultFont(
            for: FontSpec(family: "Helvetica", size: 14, italic: true)
        )
        XCTAssertEqual(resolved, Font.custom("Helvetica", size: 14).italic())
    }
}
