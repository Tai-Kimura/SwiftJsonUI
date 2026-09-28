//
//  DynamicEffectStyleTests.swift
//  SwiftJsonUITests
//
//  `common.effectStyle` on a node that is not a Blur.
//
//  The attribute is declared on `common`; android and web draw a non-Blur
//  node's material, and this runtime read it only in BlurConverter, so a View
//  drew its control for every value. The standard chain's `glass` stage now
//  draws it first (DynamicModifierHelper.applyMaterials), through the same
//  library table BlurConverter calls — the order sjui codegen emits in its
//  :glass slot (`base_view_converter.rb#apply_glass`).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicEffectStyleTests: XCTestCase {

    private func component(_ dict: [String: Any]) -> DynamicComponent {
        var raw = dict
        raw["type"] = raw["type"] ?? "View"
        let data = try! JSONSerialization.data(withJSONObject: raw)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    private func spelling(_ dict: [String: Any]) -> String?? {
        DynamicModifierHelper.effectStyleSpelling(component(dict))
    }

    func testAbsentDrawsNothing() {
        XCTAssertNil(spelling([:]))
    }

    func testEveryDeclaredSpellingReachesTheTableOnAView() {
        let spellings = ["Thick", "Regular", "Thin", "UltraThin", "Chrome",
                         "Prominent", "Light", "Dark", "ExtraLight"]
        for declared in spellings {
            let resolved = spelling(["effectStyle": declared])
            XCTAssertNotNil(resolved, "\(declared) drew nothing on a View")
            // Judged against common's declaration: the declared spelling maps
            // to its own appearance, never the default (except Regular).
            let style = VisualEffectStyle.from(resolved ?? nil)
            XCTAssertEqual(style, VisualEffectStyle.from(declared))
        }
        let styles = Set(spellings.map { VisualEffectStyle.from(spelling(["effectStyle": $0]) ?? nil) })
        XCTAssertEqual(styles.count, spellings.count, "two declared spellings resolved to one appearance")
    }

    // The system*Material names are declared valueAliases; the table folds them.
    func testSystemMaterialAliasesFold() {
        XCTAssertEqual(VisualEffectStyle.from(spelling(["effectStyle": "systemThickMaterial"]) ?? nil), .thick)
        XCTAssertEqual(VisualEffectStyle.from(spelling(["effectStyle": "systemUltraThinMaterial"]) ?? nil), .ultraThin)
        XCTAssertEqual(VisualEffectStyle.from(spelling(["effectStyle": "systemChromeMaterial"]) ?? nil), .chrome)
    }

    // A value is its declared spelling, case and all: `thick` is declared in
    // no case and draws the default, as codegen's forwarded literal does.
    func testUndeclaredSpellingDrawsTheDefault() {
        XCTAssertEqual(VisualEffectStyle.from(spelling(["effectStyle": "thick"]) ?? nil), .regular)
    }

    // A binding is no spelling: codegen emits `.jsonUIVisualEffect(nil)`.
    func testBindingDrawsTheDefaultMaterial() {
        let resolved = spelling(["effectStyle": "@{material}"])
        XCTAssertNotNil(resolved, "a declared binding must still draw the material")
        XCTAssertNil(resolved ?? "unexpected")
    }

    // A Blur applies its own declaration in BlurConverter; the standard
    // chain must not draw it a second time.
    func testBlurIsLeftToItsOwnConverter() {
        XCTAssertNil(spelling(["type": "Blur", "effectStyle": "Dark"]))
    }

    func testReachesALeafToo() {
        XCTAssertEqual(spelling(["type": "Label", "text": "hi", "effectStyle": "Thin"]) ?? nil, "Thin")
    }

    func testTheGlassStageStillRunsInCodegensSlot() {
        XCTAssertTrue(DynamicModifierHelper.standardOrder.map(\.name).contains("glass"))
        XCTAssertFalse(DynamicModifierHelper.standardOrder.map(\.name).contains("effectStyle"),
                       "the material shares codegen's :glass slot; a stage of its own needs a slot in modifier_order.json")
    }
}
#endif
