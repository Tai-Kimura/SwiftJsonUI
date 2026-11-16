//
//  DeclaredSpellingTests.swift
//  SwiftJsonUITests
//
//  An enum value is its declared spelling, case and all (jsonui-cli 1.9.0):
//  a spelling declared in no case is read as no declared value is — the
//  default — as the validator names it, on every path.
//

import XCTest
import SwiftUI
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

    /// gravity and safeAreaInsetPositions hold one or a list of declared
    /// values; the generator publishes their spellings beside the enums.
    func testGravityIsReadByItsDeclaredSpellings() {
        // centerHorizontal centres the horizontal axis; the lowercased
        // compare against "centerHorizontal" dropped it (to .topLeading).
        XCTAssertEqual(DynamicDecodingHelper.gravityToAlignment(["centerHorizontal"]), .top)
        XCTAssertEqual(DynamicDecodingHelper.gravityToAlignment(["centerVertical", "right"]), .trailing)
        XCTAssertEqual(DynamicDecodingHelper.gravityToAlignment(["RIGHT"]), .topLeading, "declared in no case")
        XCTAssertEqual(DynamicDecodingHelper.gravityToAlignment(["end"]), .topLeading, "declared nowhere")
    }

    func testSafeAreaInsetPositionsReadItsDeclaredItems() {
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["top", "left"]), .top)
        XCTAssertNil(DynamicModifierHelper.safeAreaEdgeSet(["left", "horizontal"]), "declared nowhere")
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["all"]), .all)
    }

    #if DEBUG
    /// Where a Label's text sits in its frame (DynamicModifierHelper's
    /// labelHorizontal / labelVertical): textAlign and each gravity part by
    /// its declared spelling, as sjui's frame_helper.rb label_horizontal /
    /// label_vertical_named read them (EnumSpelling.lowered). A textAlign in
    /// no declared spelling is the start, and gravity is not read beside it;
    /// a gravity part in none names nothing.
    func testALabelsPlaceInItsFrameReadsDeclaredSpellings() throws {
        func label(_ json: String) throws -> DynamicComponent {
            try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        }
        let across: [(String, HorizontalAlignment)] = [
            (#"{"type":"Label","textAlign":"Center"}"#, .center),
            (#"{"type":"Label","textAlign":"right"}"#, .trailing),
            (#"{"type":"Label","textAlign":"CENTER","gravity":"centerHorizontal"}"#, .leading),
            (#"{"type":"Label","gravity":"centerHorizontal"}"#, .center),
            (#"{"type":"Label","gravity":"right|bottom"}"#, .trailing),
            (#"{"type":"Label","gravity":"CenterHorizontal"}"#, .leading),
            (#"{"type":"Label","gravity":"Right"}"#, .leading),
        ]
        for (json, expected) in across {
            XCTAssertEqual(DynamicModifierHelper.labelHorizontal(try label(json)), expected, json)
        }
        let down: [(String, VerticalAlignment)] = [
            (#"{"type":"Label","gravity":"bottom"}"#, .bottom),
            (#"{"type":"Label","gravity":"Bottom"}"#, .center),
            (#"{"type":"Label","gravity":"TOP|left"}"#, .center),
        ]
        for (json, expected) in down {
            XCTAssertEqual(DynamicModifierHelper.labelVertical(try label(json)), expected, json)
        }
    }
    #endif
}
