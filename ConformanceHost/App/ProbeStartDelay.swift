//
//  ProbeStartDelay.swift
//  ConformanceHost
//
//  Test-only: holds a probe button's scroll request back by a declared delay,
//  so a scroll starts well after the tap that asked for it.
//
//  XCUITest's tap returns once the app is idle, and on a fast machine the
//  list has already landed by then: a probe that read the list without
//  waiting at all passed exactly as one that waited (measured 2026-10-13,
//  Xcode 26.3 / iOS 26.2: the no-wait mutation of Landing.wait, 12 of 12
//  green). The wait was only exercised on a slow runner. With the delay set,
//  reading too early — or giving up on a list that has not started — reads
//  the list where it was, and the probe goes red on any machine.
//
//  The delay is declared by the run (CONFORMANCE_SCROLL_START_DELAY, seconds,
//  forwarded as a launch environment variable by the probe); unset or 0 is
//  the ordinary run. Choose it from Landing's own numbers, not from a
//  measurement: an order above its 0.25 s read period, above its 1 s rest
//  window, and well inside its 10 s budget — 2.5.
//

import Foundation

enum ProbeStartDelay {
    static let seconds: Double =
        Double(ProcessInfo.processInfo.environment["CONFORMANCE_SCROLL_START_DELAY"] ?? "") ?? 0

    /// Runs `change` now, or `seconds` later when a delay is declared.
    static func run(_ change: @escaping () -> Void) {
        guard seconds > 0 else { return change() }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: change)
    }
}
