//
//  CoveredTapProbeView.swift
//  ConformanceHost
//
//  Where does a tap land when the target is COVERED? NOT part of the
//  conformance suite. Launch with `-coveredTapProbe`.
//
//  jsonui-test-runner-ios routes a tap on a non-hittable element whose
//  centre is inside the window to `.frameCenter`, which taps the COORDINATE:
//
//      element.coordinate(withNormalizedOffset: (0.5, 0.5)).tap()
//
//  A coordinate tap hits whatever is drawn there. If something covers the
//  target, the cover receives it — TapRouting's own docstring records a 1.9.4
//  case where a fixed bar at 818..874 swallowed a tap aimed at an element at
//  818..850 and opened a different screen. 1.9.5 fixed one route INTO that
//  situation (scrolling stopping early); `.frameCenter` itself is unchanged
//  through 1.9.9.
//
//  ⚠️ Reaching that branch is narrow, and the two shapes already built here
//  do NOT reach it (measured):
//
//    ancestor-clipped element   -> `.clipped()` does not restrict hit
//                                  testing, so it stays hittable=true and
//                                  routes to `.element`
//    element past the window    -> its centre is outside the window, so it
//                                  routes to `.offscreen`
//
//  What is left is an element that something is genuinely drawn in front of,
//  with its centre still on screen. That is what this builds: two buttons at
//  the same position, the later one on top.
//
//  Both report when tapped, so the result NAMES what received the tap rather
//  than leaving a silence to interpret.
//

import SwiftUI

struct CoveredTapProbeView: View {
    @State private var lastTapped: String = "none"

    /// Placed well inside the window so the centre cannot fall outside it —
    /// that would route to `.offscreen` and miss the branch under test.
    static let targetTop: CGFloat = 220
    static let targetSize = CGSize(width: 240, height: 80)

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("tapped: \(lastTapped)")
                    .accessibilityIdentifier("covered_probe_result")
                Button("reset") { lastTapped = "none" }
                    .accessibilityIdentifier("covered_probe_reset")
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            // The target, underneath.
            layer(id: "covered_target", title: "target", color: .blue)

            // The cover, drawn after and therefore ON TOP, at the same
            // position. Being a Button it is an accessibility element in its
            // own right, which is what makes the target report
            // isHittable == false.
            layer(id: "covering_bar", title: "cover", color: .red)
        }
    }

    @ViewBuilder
    private func layer(id: String, title: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: Self.targetTop)
            Button {
                lastTapped = title
            } label: {
                Text(title)
                    .foregroundColor(.white)
                    .frame(width: Self.targetSize.width, height: Self.targetSize.height)
                    .background(color)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(id)
            Spacer()
        }
    }
}
