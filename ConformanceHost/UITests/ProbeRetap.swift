//
//  ProbeRetap.swift
//  ConformanceHostUITests
//
//  One named retap for a probe, as a fixture has (jsonui-cli RESULTS_SCHEMA.md
//  `retap`, tickets 2026-10-24-ios-conformance-tap-not-delivered-recurred and
//  2026-11-02-conformance-weekly-ios-cantap-gate-probe-red). The simulator
//  sometimes loses a touch on a hittable element, about once in three weeks of
//  runs, and a probe that reads the first tap's effect then goes red with
//  nothing wrong in the library.
//
//  The rules are the fixture's: a touch whose effect does not show is sent once
//  more and the log says so (`PROBE_RETAP …`); one per test, so a second lost
//  touch stays red. A row whose job is to see a control stop (a gate) is never
//  tapped through this: a second tap must never be the reason a gate reads as
//  holding. Taps there stay plain `.tap()`.
//
//  The wording of these lines is a contract: jsonui-cli's
//  .github/scripts/ios_retaps.py counts them against the run's retap cap, and a
//  line it cannot parse counts as a retap rather than as nothing. Change the
//  wording there too.
//

import XCTest

final class ProbeRetap {
    private let probe: String
    private let log: (String) -> Void
    private(set) var spentOn: String?

    /// `log` is for the unit test; a probe's lines go to the run's log.
    init(_ probe: String, log: @escaping (String) -> Void = { print($0) }) {
        self.probe = probe
        self.log = log
    }

    /// Touches once, then waits up to `wait` seconds for `landed`. When it does
    /// not answer true, touches once more if this test has not retapped yet, and
    /// waits again. Returns whether it touched again. The caller's assertions
    /// stay as they were: this only decides whether a touch was delivered.
    ///
    /// `window`: a probe whose app logs every touch its window receives, apart
    /// from any handler, reads that log here. Read before the touch and after the
    /// wait, it says which a missing effect was: a touch the app never received,
    /// or one it received whose effect was late or went elsewhere — which the
    /// effect alone cannot tell when a second touch gives the same result
    /// (ticket 2026-11-07-ios-conformance-anchortap-retap-twice). It changes no
    /// count and no retap: the line says it, nothing else.
    @discardableResult
    func tap(_ what: String, until landed: () -> Bool, wait: TimeInterval = 3, window: (() -> String)? = nil,
             _ touch: () -> Void) -> Bool {
        let before = window?()
        touch()
        if Self.poll(landed, wait) { return false }
        let seen = before.flatMap { b in window.map { Self.saw(before: b, after: $0()) } } ?? ""
        guard spend(what, seconds: wait, seen: seen) else { return false }
        XCTContext.runActivity(named: "retap \(what) (touch not delivered)") { _ in touch() }
        if !Self.poll(landed, wait) { log("PROBE_RETAP \(probe) \(what): the second touch showed nothing either") }
        return true
    }

    /// For a probe that reads its effects after all its touches: says the retap
    /// and returns true, or says why not and returns false. The caller touches.
    /// `seen` is what the window's own log said (`saw`), or nothing.
    func spend(_ what: String, seconds: TimeInterval? = nil, seen: String = "") -> Bool {
        if let used = spentOn {
            log("PROBE_RETAP \(probe) \(what): no effect, and this test already retapped \(used) — not tapped again\(seen)")
            return false
        }
        spentOn = what
        let after = seconds.map { " \($0)s after one touch" } ?? " after one touch"
        log("PROBE_RETAP \(probe) \(what): no effect\(after) (touch not delivered) — touched once more\(seen)")
        return true
    }

    /// What the window's touch log says about the touch sent between two reads of it.
    /// A log that reads `unread` was never installed: it says nothing about the touch.
    static let unread = "none"
    static func saw(before: String, after: String) -> String {
        if before == unread || after == unread { return "; the app's window logs no touches (its log was not installed): delivery unknown" }
        if after == before { return "; the app's window saw no touch either: not delivered" }
        return "; the app's window saw that touch (\(after)): delivered, its effect late or elsewhere"
    }

    private static func poll(_ landed: () -> Bool, _ wait: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(wait)
        while true {
            if landed() { return true }
            if Date() >= deadline { return false }
            Thread.sleep(forTimeInterval: min(0.2, wait / 4))
        }
    }
}
