//
//  OffsetHitTargetProbeView.swift
//  ConformanceHost
//
//  `offset` hit-target probe (51-E's ruling question) — NOT part of the
//  conformance suite. Launch the app with `-offsetProbe`.
//
//  The question E asked, having said outright that it was not measured: does
//  a control carrying `.offset` accept a tap at the position it is DRAWN, or
//  does the touch target stay where layout put it? android's absoluteOffset
//  ruling says the hit area travels with the drawing, so if ios leaves the
//  target behind, ios is the deviant.
//
//  Reading SwiftUI's documentation does not answer it: `.offset` is described
//  as a layout-neutral visual transform, which says nothing about hit
//  testing, and the failure mode people report (a view offset outside its
//  parent stops responding) is about the PARENT clipping the hit region — a
//  different question with a different answer. So the probe renders three
//  cases and lets XCUITest report the frames and what a tap actually reaches:
//
//    control  — no offset, the baseline
//    inside   — offset by (120, 0), staying well inside the parent
//    outside  — offset far enough to leave the parent's bounds
//
//  Each button records the last tap it received, so the test can distinguish
//  "the target moved with the drawing" from "the target stayed put" by
//  tapping COORDINATES rather than elements.
//

import SwiftUI

struct OffsetHitTargetProbeView: View {
    @State private var lastTapped: String = "none"

    private let boxSize: CGFloat = 80
    private let insideOffset: CGFloat = 120
    private let outsideOffset: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("tapped: \(lastTapped)")
                .accessibilityIdentifier("offset_probe_result")

            // A tap that lands on NOTHING leaves the label unchanged, which
            // reads identically to a hit if the previous value is still
            // there. The reset makes a miss observable — silence must not
            // look like success.
            Button("reset") { lastTapped = "none" }
                .accessibilityIdentifier("offset_probe_reset")

            // Baseline: no offset at all.
            probeRow(id: "control", offset: 0, parentWidth: 300)

            // Offset, still inside the parent's bounds.
            probeRow(id: "inside", offset: insideOffset, parentWidth: 300)

            // Offset past the parent's trailing edge. If the parent clips hit
            // testing, this one is unreachable at its drawn position even if
            // `inside` is reachable — which is a DIFFERENT finding from the
            // target staying behind, and the probe has to tell them apart.
            probeRow(id: "outside", offset: outsideOffset, parentWidth: 300)

            Spacer()
        }
        .padding(20)
        // NO identifier on the root: an identifier on a SwiftUI container
        // propagates down and OVERWRITES every descendant's own identifier
        // (measured here — the first run reported `offset_probe_root` for the
        // result text and all three buttons). Same shape as the screen-marker
        // probe's container finding.
    }

    @ViewBuilder
    private func probeRow(id: String, offset: CGFloat, parentWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color(white: 0.87)
                .frame(width: parentWidth, height: boxSize)
                .accessibilityIdentifier("\(id)_parent")

            Button {
                lastTapped = id
            } label: {
                Color.red
                    .frame(width: boxSize, height: boxSize)
            }
            .buttonStyle(.plain)
            .offset(x: offset)
            .accessibilityIdentifier("\(id)_button")
        }
        .frame(width: parentWidth, height: boxSize, alignment: .topLeading)
    }
}
