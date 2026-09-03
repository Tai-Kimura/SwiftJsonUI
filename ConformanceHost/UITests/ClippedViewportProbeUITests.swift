//
//  ClippedViewportProbeUITests.swift
//  ConformanceHostUITests
//
//  Opt-in: TEST_RUNNER_CLIPPED_VIEWPORT_PROBE=1 in the xcodebuild process
//  environment, with the `test` action.
//
//  jsonui-test-runner-ios 1.9.8's scroll diagnosis decides which set of
//  guesses to print from one bit: is the element's hit point inside the
//  scroll container's viewport. It takes the viewport to be
//  `scroller.frame`. This measures whether that is a faithful viewport when
//  the frame covers more than the container can actually show: an element in
//  the difference is out of view with its hit point still inside the frame,
//  and the diagnosis would say "something is drawn in front of it" about an
//  element nothing is covering.
//
//  ⚠️ The discrepancy is built by letting the scroll view's frame extend
//  PAST THE APP WINDOW, not by clipping it with an ancestor. Ancestor
//  clipping was tried first and does not work: `.clipped()` restricts
//  drawing but not hit testing, and `.contentShape(Rectangle())` did not
//  change that — XCUITest reported the clipped element hittable=true at its
//  drawn-away position. XCUITest's hittability does not track SwiftUI's
//  internal clipping, which also means the driver could never reach the
//  diagnosis in that shape (the path opens only when the element is present
//  and NOT hittable). So this arm covers the off-window case only; whether
//  an ancestor-clipped pane can mislead the discriminator is NOT settled
//  here, because on iOS it cannot be reached at all.
//
//  ⚠️ The predicate is re-stated here rather than imported. ScrollDiagnosis
//  lives in the vendored driver and only exists from 1.9.8, and the host is
//  built against whatever driver is vendored — importing it would break the
//  build for earlier drivers. The rule copied is three lines
//  (`viewport.contains(CGPoint(x: element.midX, y: element.midY))`,
//  ScrollDiagnosis.placement). What is under test is the INPUT — whether
//  `scroller.frame` is the visible region — not the predicate. If the
//  driver's rule ever changes, this arm measures the old one.
//

import XCTest

final class ClippedViewportProbeUITests: XCTestCase {

    /// ScrollDiagnosis.placement's rule, restated (see the note above).
    private func hitPointIsInside(element: CGRect, viewport: CGRect) -> Bool {
        viewport.contains(CGPoint(x: element.midX, y: element.midY))
    }

    func testScrollContainerFrameIsAFaithfulViewport() throws {
        guard ProcessInfo.processInfo.environment["CLIPPED_VIEWPORT_PROBE"] == "1" else {
            throw XCTSkip("clipped viewport probe: run with the guard lifted, as the other probes are")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-clippedViewportProbe"]
        app.launch()

        let visible = app.staticTexts["item_1"]      // inside the clipped window
        let clipped = app.staticTexts["item_26"]     // inside the frame, off the window
        XCTAssertTrue(visible.waitForExistence(timeout: 10), "probe did not start")

        // The driver resolves "first scroll view" when no container is named,
        // and uses its `frame` as the viewport. Read the same thing.
        let scroller = app.scrollViews.firstMatch
        XCTAssertTrue(scroller.exists, "no scroll view resolved — the arm has no viewport to test")
        let viewport = scroller.frame

        print("CLIP_PROBE_VIEWPORT \(viewport)")
        print("CLIP_PROBE_VISIBLE   item_1  frame=\(visible.frame) hittable=\(visible.isHittable)")

        // If SwiftUI drops the clipped element from the accessibility tree,
        // the driver's `targetPresentWithAFrame()` gate never opens and the
        // diagnosis cannot be reached at all — a real constraint, not a pass.
        guard clipped.exists else {
            XCTFail("CONSTRAINT: item_26 is absent from the accessibility tree when clipped, so the "
                    + "diagnosis path (targetPresentWithAFrame) cannot be reached this way — this arm "
                    + "cannot test the viewport bit and the ticket should record that")
            return
        }
        let clippedFrame = clipped.frame
        print("CLIP_PROBE_CLIPPED   item_26 frame=\(clippedFrame) hittable=\(clipped.isHittable)")

        // ---- self-checks: does the fixture actually produce the situation? ----
        // Positive control: hittability discriminates here at all.
        XCTAssertTrue(
            visible.isHittable,
            "FIXTURE: item_1 should be visible and hittable; if it is not, 'not hittable' says nothing")
        // The case in question: out of view. Content is sized to the scroll
        // frame, so this cannot be explained by "it needs scrolling".
        XCTAssertFalse(
            clipped.isHittable,
            "FIXTURE: item_26 should be off the window and unhittable; if it is hittable the frame "
            + "and the visible region have not come apart and there is no discrepancy to measure")

        // ---- the measurement ----
        let inside = hitPointIsInside(element: clippedFrame, viewport: viewport)
        print("CLIP_PROBE_PLACEMENT hitPoint=(\(clippedFrame.midX), \(clippedFrame.midY)) "
              + "insideViewport=\(inside) -> diagnosis would say "
              + "\(inside ? "'something is drawn in front of it'" : "'out of view'")")

        XCTAssertFalse(
            inside,
            "DISCRIMINATOR: item_26 is out of view (unhittable, nothing left to scroll) yet its hit "
            + "point falls inside scroller.frame \(viewport). The 1.9.8 diagnosis would report "
            + "'something is drawn in front of it' and rule out 'not a scrolling problem' — both "
            + "wrong. The viewport must be the visible region, not the container's layout frame")
    }
}
