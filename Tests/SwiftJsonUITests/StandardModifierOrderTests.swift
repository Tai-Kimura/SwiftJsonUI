//
//  StandardModifierOrderTests.swift
//  SwiftJsonUITests
//
//  The wiring of the standard modifier chain, asserted in one test.
//
//  Measured 2026-09-01: deleting any single stage from the old hand-written
//  chain left the whole suite green for 21 of 23 stages. The 2 that were
//  caught (frameSize, background) are not wiring tests — they are pixel
//  fixtures written for distribution gaps and relative margins that happen to
//  sample a coordinate the stage changes, so that coverage would vanish
//  silently if those fixtures changed. Read it as 0 of 23.
//
//  Per-stage tests cannot close this: nothing in the suite calls
//  applyStandardModifiers directly, and the only path through it renders to a
//  CGImage and samples colours — so every stage without a visible colour
//  consequence (accessibility traits, disabled, hitTesting, the dialog family)
//  is invisible to it in principle.
//
//  So the chain is DRIVEN by `standardOrder` instead: a stage that leaves the
//  list stops being applied, and one in the list is always applied. Wiring can
//  then only break as "a name left the list", which is what this asserts.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class StandardModifierOrderTests: XCTestCase {

    /// Written out here rather than read back from `standardOrder`: comparing
    /// the constant against itself is true no matter what it holds. Adding or
    /// removing a stage must touch both places, which is what makes the change
    /// a statement of intent instead of a side effect.
    ///
    /// ORDER IS LOAD-BEARING. `disabled` really does appear twice — the second
    /// application sits outside the accessibility element, because an element
    /// outside the disabled environment never carries the notEnabled trait
    /// (measured on the View-hosted enabled__false conformance fixture). It is
    /// not a duplicate to be tidied away.
    private let expectedOrder = [
        "padding",
        "frameConstraints",
        "frameSize",
        "insets",
        "background",
        "safeAreaInsets",
        "cornerRadius",
        "border",
        "margins",
        "opacity",
        "shadow",
        "clipped",
        "offset",
        "zIndex",
        "hidden",
        "disabled",
        "hitTesting",
        "tint",
        "events",
        "confirmationDialog",
        "alert",
        "accessibilityId",
        "disabledOuter",
    ]

    func testEveryStageIsWiredInOrder() {
        XCTAssertEqual(
            DynamicModifierHelper.standardOrder.map(\.name),
            expectedOrder,
            "the applied chain no longer matches the declared order — a stage "
            + "was added, removed, or moved without updating both places"
        )
    }

    /// The opt-outs remove a stage from the chain rather than leaving it in
    /// place doing nothing. Both readings apply the same modifiers, but only
    /// this one keeps `standardOrder` an honest description of what ran — and
    /// the equivalence capture during the migration caught the difference.
    func testSkipsRemoveExactlyTheirOwnStages() {
        func names(padding: Bool = false, insets: Bool = false, background: Bool = false) -> [String] {
            let skips = DynamicModifierHelper.Skips(
                padding: padding, insets: insets, background: background)
            return DynamicModifierHelper.standardOrder
                .filter { $0.appliesWhen(skips) }
                .map(\.name)
        }

        XCTAssertEqual(names(), expectedOrder)
        XCTAssertEqual(names(padding: true), expectedOrder.filter { $0 != "padding" })
        XCTAssertEqual(names(insets: true), expectedOrder.filter { $0 != "insets" })
        // background covers safeAreaInsets too: it has always lived inside
        // that opt-out.
        XCTAssertEqual(names(background: true),
                       expectedOrder.filter { $0 != "background" && $0 != "safeAreaInsets" })
        XCTAssertEqual(names(padding: true, insets: true, background: true),
                       expectedOrder.filter {
                           !["padding", "insets", "background", "safeAreaInsets"].contains($0)
                       })
    }
}
#endif
