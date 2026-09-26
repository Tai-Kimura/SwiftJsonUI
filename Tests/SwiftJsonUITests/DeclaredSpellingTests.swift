//
//  DeclaredSpellingTests.swift
//  SwiftJsonUITests
//
//  An enum value is its declared spelling, case and all (jsonui-cli 1.9.0):
//  a spelling declared in no case is read as no declared value is — the
//  default — as the validator names it, on every path.
//

import XCTest
@testable import SwiftJsonUI

final class DeclaredSpellingTests: XCTestCase {

    func testADeclaredSpellingIsLoweredForTheSwitch() {
        XCTAssertEqual(DeclaredSpelling.lowered("fillEqually", in: ViewAttributes.Distribution.declaredSpellings), "fillequally")
        XCTAssertEqual(DeclaredSpelling.lowered("AspectFill", in: ImageAttributes.ContentMode.declaredSpellings), "aspectfill")
    }

    func testASpellingDeclaredInNoCaseIsNil() {
        XCTAssertNil(DeclaredSpelling.lowered("FillEqually", in: ViewAttributes.Distribution.declaredSpellings))
        XCTAssertNil(DeclaredSpelling.lowered("aspectFill", in: ImageAttributes.ContentMode.declaredSpellings))
        XCTAssertNil(DeclaredSpelling.lowered("no-such-value", in: ViewAttributes.Distribution.declaredSpellings))
        XCTAssertNil(DeclaredSpelling.lowered(nil, in: ViewAttributes.Distribution.declaredSpellings))
    }

    /// The two values the ruling names: View.orientation declares
    /// `horizontal`, SelectBox.selectItemType `Date`.
    func testTheRulingsTwoValuesAreReadAsNoDeclaredValue() {
        XCTAssertEqual(DeclaredSpelling.lowered("horizontal", in: ViewAttributes.Orientation.declaredSpellings), "horizontal")
        XCTAssertNil(DeclaredSpelling.lowered("Horizontal", in: ViewAttributes.Orientation.declaredSpellings))
        XCTAssertEqual(DeclaredSpelling.lowered("Date", in: SelectBoxAttributes.SelectItemType.declaredSpellings), "date")
        XCTAssertNil(DeclaredSpelling.lowered("date", in: SelectBoxAttributes.SelectItemType.declaredSpellings))
    }

    /// The set is the node's: a Blur declares Light / Dark / ExtraLight, any
    /// other node common's materials; NetworkImage declares no ScaleToFill.
    func testTheSetIsTheNodesDeclaration() {
        XCTAssertNil(DeclaredSpelling.lowered("Thick", in: BlurAttributes.EffectStyle.declaredSpellings))
        XCTAssertEqual(DeclaredSpelling.lowered("Thick", in: CommonAttributes.EffectStyle.declaredSpellings), "thick")
        XCTAssertEqual(VisualEffectStyle.from("Thick"), .thick)
        XCTAssertEqual(VisualEffectStyle.from("Thick", in: BlurAttributes.EffectStyle.declaredSpellings), .regular)
        XCTAssertEqual(ImageContentModeIntent.from("ScaleToFill"), .stretch)
        XCTAssertEqual(NetworkImage.ContentMode.from("ScaleToFill"), .fit)
    }
}
