//
//  StandardOrderFollowsCodegenTests.swift
//  SwiftJsonUITests
//
//  DynamicModifierHelper.standardOrder applies the standard modifiers in the
//  order sjui codegen emits them — the release build is the reference, and
//  the Dynamic runtime exists to show what it will draw.
//
//  The order is not written here. It comes from jsonui-cli's
//  sjui_tools/lib/swiftui/views/modifier_order.json, copied byte for byte into
//  Fixtures/swiftui_modifier_order.json: jsonui-cli's spec holds that file to
//  ModifierBag::MODIFIER_ORDER and to the code the converters generate, and
//  this repository's CI (vendored-attr-guard) holds the copy to the file at
//  JSONUI_CLI_MANIFEST_REF. So a change on either side goes red: codegen's
//  order moves → the copy is stale until re-copied → re-copied, this test
//  fails until the chain follows; the chain moves → this test fails.
//
//  What IS written here is which codegen slot each Dynamic stage is emitted
//  in — the one mapping the two lists need, since the names differ. Every
//  stage must be in it, and every slot it names must be in the file.
//
//  Measured before this order was adopted (2026-09-25): 35 of the 276 stage
//  pairs ran in the opposite order from codegen. Rendered on iOS 18.6 and
//  26.4 with each pair swapped, 7 changed the size or the pixels — insets
//  with frameConstraints / frameSize (size), safeAreaInsets with
//  cornerRadius / border / clipped, clipped with margins / opacity.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class StandardOrderFollowsCodegenTests: XCTestCase {

    /// Dynamic stage → the codegen slot it is emitted in. A slot is a
    /// modifier_bag key, or `after_bag:<name>` for what BaseViewConverter
    /// writes after the bag.
    private let slotOf: [String: String] = [
        "padding": "padding",
        "insets": "padding",              // SpacingHelper#apply_insets appends to :padding
        "frameConstraints": "frame_constraints",
        "frameSize": "frame_size",
        "background": "background",
        "safeAreaInsets": "safe_area_insets",
        "glass": "glass",
        "cornerRadius": "corner_radius",
        "border": "border",
        "margins": "margin",
        "opacity": "opacity",
        "shadow": "shadow",
        "clipped": "clip_to_bounds",
        "offset": "offset",
        "zIndex": "z_index",
        "hidden": "hidden",
        "disabled": "disabled",
        "hitTesting": "allows_hit_testing",
        "tint": "tint_color",
        "events": "on_click",             // on_click … on_disappear, one stage here
        "confirmationDialog": "confirmation_dialog",
        "alert": "alert",
        "accessibilityId": "after_bag:accessibility_identifier",
        "disabledOuter": "after_bag:disabled",
    ]

    private struct CodegenOrder {
        let slots: [String]
        let shared: [String: [String]]
    }

    private func codegenOrder() throws -> CodegenOrder {
        let data = try TestFixtures.loadJSON(named: "swiftui_modifier_order")
        let doc = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let bag = try XCTUnwrap(doc["bag"] as? [String], "the copy has no bag")
        let after = try XCTUnwrap(doc["after_bag"] as? [String], "the copy has no after_bag")
        let shared = (doc["shared_slots"] as? [String: [String]]) ?? [:]
        return CodegenOrder(slots: bag + after.map { "after_bag:\($0)" }, shared: shared)
    }

    func testEveryStageHasASlotThatCodegenEmits() throws {
        let order = try codegenOrder()
        let stages = DynamicModifierHelper.standardOrder.map(\.name)
        XCTAssertEqual(Set(slotOf.keys), Set(stages),
                       "every stage of the chain needs the codegen slot it is emitted in, and only those")
        for (stage, slot) in slotOf {
            XCTAssertTrue(order.slots.contains(slot),
                          "\(stage): codegen emits no slot \(slot) — the copy moved, or the mapping is wrong")
        }
        XCTAssertEqual(order.shared["padding"], ["padding", "insets"],
                       "the :padding slot no longer carries padding then insets")
    }

    func testTheChainRunsInCodegensOrder() throws {
        let order = try codegenOrder()
        let stages = DynamicModifierHelper.standardOrder.map(\.name)
        // Rank: the slot's place, then the place within a shared slot.
        func rank(_ stage: String) -> (Int, Int) {
            let slot = slotOf[stage] ?? ""
            let within = order.shared[slot]?.firstIndex(of: stage) ?? 0
            return (order.slots.firstIndex(of: slot) ?? Int.max, within)
        }
        let expected = stages.sorted { rank($0) < rank($1) }
        XCTAssertEqual(stages, expected,
                       "standardOrder is not codegen's order (Fixtures/swiftui_modifier_order.json)")
    }
}
#endif
