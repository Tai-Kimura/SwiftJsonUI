//
//  ScrollRuleProbeUITests.swift
//  ConformanceHostUITests
//
//  What a scrollTo names across sections, and a sectioned grid's header and
//  footer rows (ScrollRuleProbeView; 4f round 10, 2026-09-27), on the
//  Dynamic renderer and — in the codegen host — as sjui generates it:
//  - scrollTo 6, on a list of a header, A0…A4, a footer, a header, B0…B7,
//    lands on B1 — the seventh cell — at the top of the list;
//  - scrollTo "k3", a key the first section's a3 and the second's b0 share,
//    lands on a3;
//  - in the grid, each header and footer is a full-width row with the view
//    at its start, and the rows are 4 apart (lineSpacing);
//  - a cell with no key has no key (4f round 13): "3", on a list whose first
//    section has no keys (c0…c9) and whose second keys d5 "3", lands on d5;
//    "1:7" and "1:y2" land nowhere; "y6" lands on d6.
//  NOT opt-in. The dynamic host has no generated half: it asks the Dynamic
//  half only.
//

import XCTest

final class ScrollRuleProbeUITests: XCTestCase {
    private var codegenHost: Bool { ProcessInfo.processInfo.environment["CONFORMANCE_HOST_MODE"] == "codegen" }

    private func launch(_ argument: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        if codegenHost { app.launchEnvironment["CONFORMANCE_HOST_MODE"] = "codegen" }
        // The start-delay specimen (App/ProbeStartDelay.swift), when the run declares one.
        if let delay = ProcessInfo.processInfo.environment["CONFORMANCE_SCROLL_START_DELAY"] {
            app.launchEnvironment["CONFORMANCE_SCROLL_START_DELAY"] = delay
        }
        app.launch()
        XCTAssertTrue(app.staticTexts["sr_ready"].waitForExistence(timeout: 15), "probe did not start")
        XCTAssertEqual(app.staticTexts["sr_codegen"].exists, codegenHost, "the generated half is there iff this is the codegen host")
        return app
    }

    /// A probe Collection by the identifier its scroll container carries: its
    /// own id (codegen), or the frame the probe view wraps it in (Dynamic —
    /// the wrapper's identifier is the one the ScrollView takes).
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func report(_ lines: [String], _ prefix: String) {
        lines.forEach { print("\(prefix) \($0)") }
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The label at the top of the list in `frame`: of `labels` on screen,
    /// the one nearest below the list's top edge (a label sits 4pt into its
    /// view), with how far below. One snapshot (ProbeSnapshot), not a query
    /// per label.
    private func top(of frame: XCUIElement, among labels: [String]) -> String {
        let snap = ProbeSnapshot(frame, labels: labels)
        var best: (String, CGFloat)? = nil
        for label in labels {
            guard let f = snap?.visible(label) else { continue }
            let offset = f.minY - snap!.frame.minY
            if offset >= -2 && offset < (best?.1 ?? .infinity) { best = (label, offset) }
        }
        let got = best.map { $0.1 < 10 ? $0.0 : "\($0.0)@\(Int($0.1))" } ?? "none"
        if ProbeSnapshot.compare {
            let old = queriedTop(of: frame, among: labels)
            let partly = labels.filter { snap?.partlyVisible($0) ?? false }
            print("PROBE_READ \(old == got ? "SAME" : "DIFF") top | queried: \(old) | snapshot: \(got) | partly visible: \(partly)")
        }
        return got
    }

    /// `top` by one query per label — what the probe read before
    /// ProbeSnapshot. Only for CONFORMANCE_PROBE_READ_COMPARE=1.
    private func queriedTop(of frame: XCUIElement, among labels: [String]) -> String {
        let listTop = frame.frame.minY
        var best: (String, CGFloat)? = nil
        for label in labels {
            let e = frame.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
            guard e.exists && e.isHittable else { continue }
            let offset = e.frame.minY - listTop
            if offset >= -2 && offset < (best?.1 ?? .infinity) { best = (label, offset) }
        }
        guard let best else { return "none" }
        return best.1 < 10 ? best.0 : "\(best.0)@\(Int(best.1))"
    }

    func testAScrollNamesACellAcrossTheSections() throws {
        let app = launch("-scrollRuleProbe")
        let listLabels = ["H0", "F0", "H1"] + (0..<5).map { "A\($0)" } + (0..<8).map { "B\($0)" }
        let keyLabels = (0..<10).map { "a\($0)" } + (0..<10).map { "b\($0)" }
        var lines: [String] = []
        var halves: [(name: String, goIndex: String, goKey: String, index: XCUIElement, key: XCUIElement)] = [
            ("dynamic", "dyn go 6", "dyn go k3", element(app, "dyn_index_frame"), element(app, "dyn_key_frame"))
        ]
        if codegenHost {
            halves.append(("codegen", "cg go 6", "cg go k3", element(app, "cg_rule_index"), element(app, "cg_rule_key")))
        }
        for half in halves {
            XCTAssertTrue(half.index.waitForExistence(timeout: 5), "\(half.name): no index list")
            let indexBefore = top(of: half.index, among: listLabels)
            lines.append("\(half.name) index before: top=\(indexBefore)")
            app.buttons[half.goIndex].tap()
            var landed = indexBefore
            lines.append(Landing.wait("\(half.name) index go 6", from: indexBefore, landed: { $0 == "B1" }) {
                landed = top(of: half.index, among: listLabels)
                return landed
            })
            lines.append("\(half.name) index after 6: top=\(landed)")
            XCTAssertEqual(landed, "B1", "\(half.name): scrollTo 6 did not land on B1, the seventh cell")

            let keyBefore = top(of: half.key, among: keyLabels)
            lines.append("\(half.name) key before: top=\(keyBefore)")
            app.buttons[half.goKey].tap()
            var keyed = keyBefore
            lines.append(Landing.wait("\(half.name) key go k3", from: keyBefore, landed: { $0 == "a3" }) {
                keyed = top(of: half.key, among: keyLabels)
                return keyed
            })
            lines.append("\(half.name) key after k3: top=\(keyed)")
            XCTAssertEqual(keyed, "a3", "\(half.name): scrollTo \"k3\" did not land on a3, the first section's cell")
        }
        report(lines, "SRP")
    }

    func testACellWithNoKeyAnswersNoKey() throws {
        let app = launch("-scrollNoKeyProbe")
        let labels = (0..<10).map { "c\($0)" } + (0..<10).map { "d\($0)" }
        var lines: [String] = []
        var halves: [(name: String, prefix: String, list: XCUIElement)] = [("dynamic", "dyn", element(app, "dyn_nokey_frame"))]
        if codegenHost { halves.append(("codegen", "cg", element(app, "cg_rule_nokey"))) }
        // The value, and the cell at the top after it: "3" is d5's key, and
        // c3's place; "1:7" and "1:y2" are no cell's key (d7's place and d2's
        // loop id before jsonui-cli 1.9.0), so the list stays at d5.
        let steps = [("3", "d5"), ("1:7", "d5"), ("1:y2", "d5"), ("y6", "d6")]
        for half in halves {
            XCTAssertTrue(half.list.waitForExistence(timeout: 5), "\(half.name): no list")
            lines.append("\(half.name) before: top=\(top(of: half.list, among: labels))")
            for (value, expected) in steps {
                let before = top(of: half.list, among: labels)
                app.buttons["\(half.prefix) go \(value)"].tap()
                var landed = before
                lines.append(Landing.wait("\(half.name) go \(value)", from: before, landed: { $0 == expected }) {
                    landed = top(of: half.list, among: labels)
                    return landed
                })
                lines.append("\(half.name) after \(value): top=\(landed)")
                XCTAssertEqual(landed, expected, "\(half.name): after scrollTo \"\(value)\" the top is not \(expected)")
            }
        }
        report(lines, "SNK")
    }

    func testASectionedGridDrawsItsHeadersAndFootersAsLeadingRows() throws {
        let app = launch("-sectionGridProbe")
        let labels = ["H0", "A0", "A1", "A2", "F0", "H1", "B0", "B1"]
        var frames: [(String, XCUIElement)] = [("dynamic", element(app, "dyn_grid_frame"))]
        if codegenHost { frames.append(("codegen", element(app, "cg_rule_grid"))) }
        var lines: [String] = []
        var placed: [String: [String: CGRect]] = [:]
        for (name, frame) in frames {
            XCTAssertTrue(frame.waitForExistence(timeout: 5), "\(name): no grid")
            let origin = frame.frame.origin
            var at: [String: CGRect] = [:]
            for label in labels {
                let e = frame.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
                guard e.exists else { lines.append("\(name) \(label): absent"); continue }
                // The label sits in its 60 × 28 view, 4pt in (the cell's padding).
                let r = e.frame.offsetBy(dx: -origin.x, dy: -origin.y)
                at[label] = r
                lines.append("\(name) \(label): x=\(Int(r.minX)) y=\(Int(r.minY))")
            }
            placed[name] = at
            if let h0 = at["H0"], let a0 = at["A0"], let f0 = at["F0"], let h1 = at["H1"], let b0 = at["B0"], let a2 = at["A2"] {
                XCTAssertLessThan(h0.minX, 8, "\(name): H0 is not at the row's start (x \(h0.minX))")
                XCTAssertLessThan(f0.minX, 8, "\(name): F0 is not at the row's start (x \(f0.minX))")
                XCTAssertLessThan(h1.minX, 8, "\(name): H1 is not at the row's start (x \(h1.minX))")
                // Rows 28 tall, 4 apart: H0, A0 A1, A2, F0, H1, B0 B1.
                XCTAssertEqual(a0.minY - h0.minY, 32, accuracy: 1, "\(name): H0 → A0 is not one row and 4")
                XCTAssertEqual(f0.minY - a2.minY, 32, accuracy: 1, "\(name): A2 → F0 is not one row and 4")
                XCTAssertEqual(h1.minY - f0.minY, 32, accuracy: 1, "\(name): F0 → H1 is not one row and 4")
                XCTAssertEqual(b0.minY - h1.minY, 32, accuracy: 1, "\(name): H1 → B0 is not one row and 4")
            } else {
                XCTFail("\(name): a label is absent")
            }
        }
        if let d = placed["dynamic"], let c = placed["codegen"] {
            let differ = labels.filter { l in
                guard let a = d[l], let b = c[l] else { return true }
                return abs(a.minX - b.minX) > 0.5 || abs(a.minY - b.minY) > 0.5
            }
            lines.append("codegen vs dynamic: \(differ.isEmpty ? "the same places" : "differ at \(differ)")")
            XCTAssertTrue(differ.isEmpty, "codegen and dynamic place \(differ) differently")
            for (name, frame) in frames {
                let shot = XCTAttachment(screenshot: frame.screenshot())
                shot.name = "grid_\(name)"
                shot.lifetime = .keepAlways
                add(shot)
            }
        }
        report(lines, "SGP")
    }
}
