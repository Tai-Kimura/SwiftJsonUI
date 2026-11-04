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
    @discardableResult
    func tap(_ what: String, until landed: () -> Bool, wait: TimeInterval = 3, _ touch: () -> Void) -> Bool {
        touch()
        if Self.poll(landed, wait) { return false }
        guard spend(what, seconds: wait) else { return false }
        XCTContext.runActivity(named: "retap \(what) (touch not delivered)") { _ in touch() }
        if !Self.poll(landed, wait) { log("PROBE_RETAP \(probe) \(what): the second touch showed nothing either") }
        return true
    }

    /// For a probe that reads its effects after all its touches: says the retap
    /// and returns true, or says why not and returns false. The caller touches.
    func spend(_ what: String, seconds: TimeInterval? = nil) -> Bool {
        if let used = spentOn {
            log("PROBE_RETAP \(probe) \(what): no effect, and this test already retapped \(used) — not tapped again")
            return false
        }
        spentOn = what
        let after = seconds.map { " \($0)s after one touch" } ?? " after one touch"
        log("PROBE_RETAP \(probe) \(what): no effect\(after) (touch not delivered) — touched once more")
        return true
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
