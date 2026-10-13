//
//  Landing.swift
//  ConformanceHostUITests
//
//  Where a scroll, a swipe or a first layout came to rest, read by polling
//  instead of after a fixed sleep. conformance-mobile run 38339290220
//  (ios-codegen, Xcode 26.3 / iOS 26.2): ScrollRule's dynamic "go k3" read a0
//  one second after the tap — the list had not reached a3 yet, or had not
//  started. A fixed sleep reads one instant; this reads every 0.25 s and
//  prints the series, so a red says whether the list never moved, stopped
//  short, or was still on its way when the budget ran out.
//
//  The expectations do not move: the caller asserts on the reading this
//  returns exactly as it asserted on the one after the sleep.
//

import XCTest

enum Landing {

    /// Reads `read` every 0.25 s until one of:
    /// - it answers `landed`, having changed from `before` (a reading equal to
    ///   `before` is where the list already was — reaching it proves nothing);
    /// - it has answered the same for `still` seconds — the list stays where
    ///   it is, or stopped somewhere; the caller's assertion says which;
    /// - `budget` seconds have passed since the call.
    ///
    /// 🔻 STILL COUNTS ONLY ONCE THE LIST HAS MOVED, OR SITS WHERE IT SHOULD.
    /// A reading equal to `before` that is not the landing is a list that has
    /// not started: counting `still` from the first read ended the wait one
    /// second after the tap, so a scroll that began later than that was read
    /// where it started (CONFORMANCE_SCROLL_START_DELAY, the start-delay
    /// specimen, holds it back on purpose). Until it moves only `budget`
    /// bounds the wait. A reading equal to `before` that IS the landing — a
    /// step whose target is where the list already is — still rests after
    /// `still`. With no `before` there is nothing to have moved from, and
    /// `still` counts from the first read.
    /// Prints `LANDING <name>` with every change of the reading and its time,
    /// and returns that line for the caller's report.
    @discardableResult
    static func wait(_ name: String, from before: String? = nil, still: TimeInterval = 1, budget: TimeInterval = 10,
                     landed: @escaping (String) -> Bool = { _ in false }, read: () -> String) -> String {
        wait(name, from: before, still: still, budget: budget) { let value = read(); return (value, landed(value)) }
    }

    /// The same, for a reading that judges itself: `read` answers what it saw
    /// and whether that is the landing.
    @discardableResult
    static func wait(_ name: String, from before: String? = nil, still: TimeInterval = 1, budget: TimeInterval = 10,
                     read: () -> (value: String, landed: Bool)) -> String {
        let start = Date()
        var series: [String] = []
        var last: String? = nil
        var since = start
        var outcome = "budget \(Int(budget))s"
        while true {
            let (value, isLanded) = read()
            let now = Date()
            let t = now.timeIntervalSince(start)
            if value != last {
                series.append(String(format: "%.2f %@", t, value))
                last = value
                since = now
            }
            if isLanded && value != before {
                outcome = String(format: "landed %.2fs", t)
                break
            }
            if before != nil && value == before && !isLanded {
                since = now // not started yet: rest is not counted
            }
            if now.timeIntervalSince(since) >= still {
                outcome = String(format: "still %.0fs at %.2fs", still, t)
                break
            }
            if t >= budget { break }
            Thread.sleep(forTimeInterval: 0.25)
        }
        let line = "LANDING \(name): \(series.joined(separator: " → ")) (\(outcome))"
        print(line)
        return line
    }
}
