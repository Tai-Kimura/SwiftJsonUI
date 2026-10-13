//
//  ProbeSnapshot.swift
//  ConformanceHostUITests
//
//  One accessibility snapshot of a probe's container, read as many times as a
//  reading needs. A reading used to ask XCUITest about every label it might
//  see — `exists`, `isHittable` and `frame`, each a query of its own — so one
//  reading of a twenty-label list cost up to eighty queries. Measured
//  2026-10-13 (Xcode 26.3 / iOS 26.2): 0.52 s a reading that way, 0.018 s
//  from one snapshot, the same answer in 22 of 22 readings; the queries were
//  half of the scroll probes' time.
//
//  `isHittable` cannot be read from a snapshot. "On screen" here is: the
//  label's first match in tree order — the element `.firstMatch` returned —
//  has a non-empty frame whose centre is inside the container's frame. That
//  is the hit point XCUITest checks, without its "not covered by another
//  element" half. CONFORMANCE_PROBE_READ_COMPARE=1 makes the probes read
//  both ways and print every reading that differs (PROBE_READ DIFF).
//

import XCTest

struct ProbeSnapshot {
    /// The container's frame, in screen coordinates.
    let frame: CGRect
    /// Each wanted label's first static text in tree order, visible or not.
    private let firstMatch: [String: CGRect]

    init?(_ container: XCUIElement, labels: [String]) {
        guard let snap = try? container.snapshot() else { return nil }
        let wanted = Set(labels)
        var found: [String: CGRect] = [:]
        func walk(_ node: XCUIElementSnapshot) {
            if node.elementType == .staticText, wanted.contains(node.label), found[node.label] == nil {
                found[node.label] = node.frame
            }
            node.children.forEach(walk)
        }
        walk(snap)
        frame = snap.frame
        firstMatch = found
    }

    /// `label`'s frame when it is on screen in the container, nil otherwise.
    func visible(_ label: String) -> CGRect? {
        guard let f = firstMatch[label], !f.isEmpty, frame.contains(CGPoint(x: f.midX, y: f.midY)) else { return nil }
        return f
    }

    /// On screen with part of it outside the container — where "centre inside"
    /// and XCUITest's hittability are most likely to part.
    func partlyVisible(_ label: String) -> Bool {
        guard let f = visible(label) else { return false }
        return !frame.contains(f)
    }

    static var compare: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_PROBE_READ_COMPARE"] == "1" }
}
