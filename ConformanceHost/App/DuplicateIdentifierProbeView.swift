//
//  DuplicateIdentifierProbeView.swift
//  ConformanceHost
//
//  Does the driver still find an interactive element that shares its
//  identifier with many others and sits DEEP in the match order? NOT part of
//  the conformance suite. Launch with `-duplicateIdentifierProbe`.
//
//  Why this exists: jsonui-test-runner-ios 1.9.5 searched for an interactive
//  type with one query PER TYPE (`descendants(matching: type)`), which is
//  unbounded in position — the control was found wherever it sat. 1.9.6
//  replaced that with a single `.any` query and took `min(total, 8)` of it
//  BEFORE looking for an interactive type, so a control at index 8 or later
//  stopped being seen. Nothing in either consumer corpus reaches nine matches
//  on one identifier (measured: longest driving array is 3), so this probe is
//  the only thing that can tell 1.9.6 from 1.9.5/1.9.7 apart.
//
//  The shape is chosen against the defect, not around it:
//
//    * TWELVE elements share `dup_target` — past the bound of 8.
//    * Exactly ONE is interactive, at row 9 — past the bound.
//    * The other eleven are `Text`, which stays `.staticText`. They must NOT
//      be interactive: `.cell` is itself in ElementPreference.interactive, so
//      building this out of Collection rows would make EVERY row interactive
//      and the winner would be index 0 — an arm that cannot fail.
//
//  Every row reports its own index when tapped, including the eleven that are
//  not the intended target. That is deliberate. If only the button reported,
//  a mis-resolved tap would leave the label at its previous value and silence
//  would have to be read as failure; here a wrong resolution NAMES the
//  element the driver picked. Under 1.9.6 the expected wrong answer is
//  `row0` — the interactive search misses, and the hittable fallback returns
//  the first of the eight candidates.
//

import SwiftUI

struct DuplicateIdentifierProbeView: View {
    @State private var lastTapped: String = "none"

    /// Shared by every row. The whole point is that it is ambiguous.
    static let sharedIdentifier = "dup_target"
    /// Twelve, so the match count is past the bound of 8 with room to spare.
    static let rowCount = 12
    /// Ninth row: index 9 in match order, past the bound. The test asserts
    /// the index it actually observes rather than trusting this constant —
    /// if SwiftUI ever reorders the tree, the arm must fail loudly instead
    /// of quietly measuring a row that is within the bound.
    static let interactiveRow = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("tapped: \(lastTapped)")
                .accessibilityIdentifier("dup_probe_result")

            // A tap that resolves to nothing must not read like the previous
            // run's success. Same reasoning as the offset probe's reset.
            Button("reset") { lastTapped = "none" }
                .accessibilityIdentifier("dup_probe_reset")

            ForEach(0..<Self.rowCount, id: \.self) { index in
                row(index)
            }

            Spacer()
        }
        .padding(12)
        // NO identifier on the root: an identifier on a SwiftUI container
        // propagates down and overwrites every descendant's own identifier
        // (measured in OffsetHitTargetProbeView). Here that would collapse
        // the whole probe into one ambiguous blob.
    }

    @ViewBuilder
    private func row(_ index: Int) -> some View {
        if index == Self.interactiveRow {
            // The one interactive row. SwiftUI exposes Button as
            // `.button`, which is first in ElementPreference.interactive,
            // so no other candidate can outrank it on type.
            Button {
                lastTapped = "row\(index)"
            } label: {
                Text("row \(index) (button)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(Self.sharedIdentifier)
        } else {
            // `.onTapGesture` does not add the button trait, so these stay
            // `.staticText` — the test asserts exactly that, because if a
            // future SwiftUI promoted them the arm would silently stop
            // reaching the defect.
            Text("row \(index)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { lastTapped = "row\(index)" }
                .accessibilityIdentifier(Self.sharedIdentifier)
        }
    }
}
