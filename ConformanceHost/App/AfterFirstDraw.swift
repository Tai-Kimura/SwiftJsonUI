//
//  AfterFirstDraw.swift
//  ConformanceHost
//
//  The one change a fixture's manifest state may ask the host to make after
//  the fixture's first draw (jsonui-cli INTERACTIVE_HOST_CONTRACT.md
//  "afterFirstDraw", 2026-10-14). A scrollTo request is a CHANGE of the
//  bound value — the value a list is drawn with scrolls nowhere — so the
//  scrollAnchor fixtures photographed a list nothing had asked to scroll
//  until the host made one (conformance-collection-scrollanchor-family-
//  does-not-discriminate).
//
//  Both faces use it: FixtureScreen's dynamic path with the state store, and
//  each generated codegen host (scripts/codegen_host_emit.rb) with its own
//  Data store. It fires once, after the first frame has been presented, and
//  stamps two times for the UITest, in ms after that frame: when the change
//  was made, and when the first frame drawn WITH it was presented. The stamp
//  is published on FixtureScreen's `conformance_after_first_draw` marker;
//  ConformanceUITests waits for `applied=` and only then reads where the
//  picture comes to rest (Landing.wait) before the screenshot.
//

import SwiftUI
import QuartzCore

/// The current fixture's stamp. One fixture is on screen at a time; a new
/// fixture's modifier resets it.
final class AfterFirstDrawStamp: ObservableObject {
    static let shared = AfterFirstDrawStamp()

    @Published private(set) var fixtureId: String?
    @Published private(set) var firedAtMs: Int?
    @Published private(set) var appliedAtMs: Int?
    private var firstFrame: CFTimeInterval?

    func reset(_ fixtureId: String) {
        self.fixtureId = fixtureId
        firedAtMs = nil
        appliedAtMs = nil
        firstFrame = nil
    }

    func markFired(_ fixtureId: String) {
        guard self.fixtureId == fixtureId, firedAtMs == nil else { return }
        firstFrame = CACurrentMediaTime()
        firedAtMs = 0
    }

    func markApplied(_ fixtureId: String) {
        guard self.fixtureId == fixtureId, let firstFrame, appliedAtMs == nil else { return }
        appliedAtMs = Int(((CACurrentMediaTime() - firstFrame) * 1000).rounded())
    }

    /// What the marker carries: `fired=<ms>` once fired, then
    /// `fired=<ms> applied=<ms>`. Empty until fired.
    var markerValue: String {
        guard let firedAtMs else { return "" }
        if let appliedAtMs { return "fired=\(firedAtMs) applied=\(appliedAtMs)" }
        return "fired=\(firedAtMs)"
    }
}

/// Calls `body` once the next frame has been presented: a one-shot display
/// link, so "after the first draw" means a frame was actually on screen
/// rather than that a body was evaluated.
final class NextPresentedFrame: NSObject {
    private var link: CADisplayLink?
    private var body: (() -> Void)?
    private var ticks = 0

    static func after(_ body: @escaping () -> Void) {
        let waiter = NextPresentedFrame()
        waiter.body = body
        let link = CADisplayLink(target: waiter, selector: #selector(tick))
        waiter.link = link
        link.add(to: .main, forMode: .common)
    }

    @objc private func tick() {
        // The first callback is the frame being prepared; the second comes
        // after it was presented.
        ticks += 1
        guard ticks >= 2 else { return }
        link?.invalidate()
        link = nil
        let run = body
        body = nil
        run?()
    }
}

struct AfterFirstDrawModifier: ViewModifier {
    let fixtureId: String
    /// Whether the value the view is drawn with already carries the change.
    let applied: Bool
    let fire: () -> Void
    @State private var started = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !started else { return }
                started = true
                AfterFirstDrawStamp.shared.reset(fixtureId)
                NextPresentedFrame.after {
                    AfterFirstDrawStamp.shared.markFired(fixtureId)
                    fire()
                }
            }
            .onChange(of: applied) { _, isApplied in
                guard isApplied else { return }
                NextPresentedFrame.after {
                    AfterFirstDrawStamp.shared.markApplied(fixtureId)
                }
            }
    }
}

extension View {
    /// Fires `fire` once after the first presented frame and stamps it; a
    /// view with no declared change passes `nil` and is left as it was.
    @ViewBuilder
    func conformanceAfterFirstDraw(_ fixtureId: String, declared: Bool, applied: Bool, fire: @escaping () -> Void) -> some View {
        if declared {
            modifier(AfterFirstDrawModifier(fixtureId: fixtureId, applied: applied, fire: fire))
        } else {
            self
        }
    }
}
