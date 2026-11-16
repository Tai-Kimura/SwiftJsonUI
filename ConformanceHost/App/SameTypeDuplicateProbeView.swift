//
//  SameTypeDuplicateProbeView.swift
//  ConformanceHost
//
//  When several elements share an identifier AND share a type, which one
//  does the driver return? NOT part of the conformance suite. Launch with
//  `-sameTypeDuplicateProbe`.
//
//  This is the half of the 1.9.5 -> 1.9.6 equivalence that source reading
//  cannot close. The two implementations pick from different enumerations:
//
//    1.9.5   descendants(matching: .button).matching(identifier: id).firstMatch
//            -> first of the TYPE-FILTERED enumeration
//    1.9.6+  first index of the `.any` enumeration whose type wins on rank
//            -> first of the UNFILTERED enumeration that happens to be a button
//
//  Those are the same element only if the two enumerations order the shared
//  elements the same way, and nothing documents that they must — it is an
//  internal property of XCTest. So it is measured here rather than argued.
//
//  The axis is isolated deliberately: FOUR matches, all `.button`, which is
//  under the eight-candidate bound. The bound is fixture 1's axis; mixing
//  them would leave a failure ambiguous between the two.
//
//  Each button reports its own index when tapped, so a resolution names
//  itself instead of leaving a silent pass — the same property that made
//  fixture 1's wrong answer legible as `row0`.
//
//  Expectation, stated before running: both rules reduce to "the first
//  interactive element in tree order", so every version should resolve
//  index 0. The test asserts that, and a failure on ANY version is the
//  finding — including on 1.9.5, whose behaviour is being measured rather
//  than assumed correct.
//

import SwiftUI

struct SameTypeDuplicateProbeView: View {
    @State private var lastTapped: String = "none"

    static let sharedIdentifier = "same_type_target"
    /// Four: enough for order to be observable, under the bound of 8 so the
    /// slice cannot participate.
    static let buttonCount = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tapped: \(lastTapped)")
                .accessibilityIdentifier("same_type_probe_result")

            Button("reset") { lastTapped = "none" }
                .accessibilityIdentifier("same_type_probe_reset")

            // Every one of these is a Button, so no candidate can outrank
            // another on type — the only thing left to decide the winner is
            // enumeration order, which is exactly the open question.
            ForEach(0..<Self.buttonCount, id: \.self) { index in
                Button {
                    lastTapped = "btn\(index)"
                } label: {
                    Text("button \(index)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        .background(Color(white: index % 2 == 0 ? 0.92 : 0.85))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(Self.sharedIdentifier)
            }

            Divider()

            // Second group: same identifier, same type, but at DIFFERENT
            // TREE DEPTHS. The flat group above only proves the two
            // enumerations agree on SIBLING order; if they can diverge at
            // all it is here, where document order and depth disagree.
            //
            //   nested0  depth 2 (HStack > VStack)  first in document order
            //   nested1  depth 0 (flat sibling)     second
            //   nested2  depth 1 (HStack)           third
            // ⚠️ `.accessibilityElement(children: .contain)` is required, not
            // decoration: plain HStack/VStack wrappers carry no accessibility
            // role and SwiftUI FLATTENS them. Measured — without it all three
            // matches reported the same snapshot depth (14, 14, 14), so the
            // arm was the flat sibling case wearing another name. `.contain`
            // makes the wrapper a container element without overwriting the
            // descendants' identifiers (which `.accessibilityIdentifier` on a
            // container would).
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    nestedButton(0)
                }
                .accessibilityElement(children: .contain)
            }
            .accessibilityElement(children: .contain)

            nestedButton(1)

            HStack(spacing: 0) {
                nestedButton(2)
            }
            .accessibilityElement(children: .contain)

            Spacer()
        }
        .padding(12)
        // No identifier on the root: it would propagate down and overwrite
        // every descendant's own identifier (measured in
        // OffsetHitTargetProbeView). The HStack/VStack wrappers above carry
        // none either, for the same reason.
    }

    static let nestedIdentifier = "nested_type_target"
    static let nestedCount = 3

    @ViewBuilder
    private func nestedButton(_ index: Int) -> some View {
        Button {
            lastTapped = "nested\(index)"
        } label: {
            Text("nested \(index)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .background(Color(white: index % 2 == 0 ? 0.90 : 0.83))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(Self.nestedIdentifier)
    }
}
