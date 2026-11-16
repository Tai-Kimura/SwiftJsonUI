//
//  ClippedViewportProbeView.swift
//  ConformanceHost
//
//  Is a scroll container's `frame` a faithful viewport? NOT part of the
//  conformance suite. Launch with `-clippedViewportProbe`.
//
//  jsonui-test-runner-ios 1.9.8's scroll diagnosis decides which guesses to
//  print from one bit: is the element's hit point inside the scroll
//  container's viewport. It takes the viewport to be `scroller.frame`. When
//  the frame covers more than the container can actually show, an element in
//  the difference is out of view while its hit point still falls inside the
//  frame, and the diagnosis says "something is drawn in front of it" about
//  an element nothing is covering.
//
//  Building that discrepancy with an ANCESTOR CLIP does not work, and the
//  reason is worth keeping: `.clipped()` restricts drawing but not hit
//  testing, and adding `.contentShape(Rectangle())` did not change it
//  either — XCUITest still reported the clipped element hittable=true at its
//  drawn-away position (measured: item_10 at y=602 under a 200pt window).
//  XCUITest's hittability does not track SwiftUI's internal clipping. That
//  also means the driver would never reach the diagnosis in that shape: the
//  path opens only when the element is present and NOT hittable.
//
//  So the discrepancy is built where hittability does respond — the scroll
//  view's frame extends past the app window:
//
//      ScrollView, frame 1400pt tall, content exactly 1400pt (nothing to scroll)
//      the window is ~874pt, so the lower half of that frame is off-window
//
//    item_1   near the top      on window,  hittable      <- positive control
//    item_26  y ~= 1300         off window, not hittable  <- the case in question
//
//  Its hit point is still inside scroller.frame, which is the whole point:
//  frame and visible region have come apart.
//

import SwiftUI

struct ClippedViewportProbeView: View {

    static let itemCount = 28
    static let itemHeight: CGFloat = 50
    /// Content is exactly this tall, so the container has nothing to scroll
    /// and "not hittable" cannot be explained by "it just needs scrolling".
    static let scrollHeight: CGFloat = 1400

    var body: some View {
        // A GeometryReader takes the proposed (window) size and places its
        // content at the top-leading corner, so an oversized child overflows
        // DOWNWARD. Plain stacks centre it instead: measured twice, viewport
        // origin y=-249 with item_1 at y=-199 and hittable=false, which put
        // the positive control off-window too. `.frame(maxHeight: .infinity,
        // alignment: .top)` did not change that (the file was recompiled and
        // the app rebuilt — the numbers were identical, not stale).
        GeometryReader { _ in
            // No identifier on the ScrollView or on this container: an
            // identifier on a SwiftUI container propagates down and
            // overwrites every descendant's own identifier (measured in
            // OffsetHitTargetProbeView). The driver resolves "first scroll
            // view" when no container is named, so none is needed.
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<Self.itemCount, id: \.self) { index in
                        Text("item \(index)")
                            .frame(maxWidth: .infinity, minHeight: Self.itemHeight)
                            .background(index % 2 == 0 ? Color(white: 0.92) : Color(white: 0.85))
                            .accessibilityIdentifier("item_\(index)")
                    }
                }
            }
            .frame(width: 320, height: Self.scrollHeight)
        }
    }
}
