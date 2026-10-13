//
//  ScrollRouteProbeUITests.swift
//  ConformanceHostUITests
//
//  Whether a scrollTo reaches its cells on the flow and the sectioned List,
//  and when it scrolls (ScrollRouteProbeView; jsonui-cli 1.9.0, the SSoT's
//  Collection.scrollTo):
//  - "go 6" lands B1 — the seventh cell, headers and footers not counted — at
//    the top; "go k3" lands a3, the first section's cell of a key both
//    sections have;
//  - a Collection drawn with scrollTo 6 stays at its top;
//  - (Dynamic) a value sent where the Collection had none scrolls too.
//  The third page (4f round 14): with cellIdProperty, an Int scrollTo lands
//  b2 on a sectioned list, the class-list List and a pager; and a key is the
//  first cell's — "3" lands g1 over g3, which has no key; "k", which three
//  cells have (two in one section), lands g6 each time.
//  The fourth page (4f round 15): with autoChangeTrackingId a key is the
//  enriched cellId on a list, the class-list List and a pager alike — "k3"
//  names no cell, a3's enriched cellId a3; with no cellIdProperty the
//  cellIds are keys by the same rule — "c2" lands c2 (not c5, which has it
//  too), "1:3" nowhere, "e4" d4. The fifth: with cellIdProperty and no
//  scrollTo, a list whose cells repeat a key draws every cell once, in order.
//  The sixth (round 16): a section-0 key "2:x" beside a section-2 key "x",
//  and the class-list shape with repeated keys — every cell drawn once, in
//  order. The seventh: on a horizontal Collection scrollAnchor top / center /
//  bottom lands the target's leading edge / middle / trailing edge at the
//  viewport's. The eighth: defaultScrollAnchor top / center / bottom starts a
//  horizontal Collection at its leading edge / middle / trailing edge.
//  The Dynamic half always; the generated half in the codegen host only.
//  NOT opt-in.
//

import XCTest

final class ScrollRouteProbeUITests: XCTestCase {
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
        XCTAssertTrue(app.staticTexts["sp_ready"].waitForExistence(timeout: 15), "probe did not start")
        return app
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func report(_ lines: [String], _ prefix: String) {
        lines.forEach { print("\(prefix) \($0)") }
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Of `labels` on screen in `frame`, the one nearest below its top edge,
    /// and how far below (a label sits 4pt into its cell; a List row may add
    /// its inset). Labels on one row tie; the first in `labels` wins. One
    /// snapshot (ProbeSnapshot), not a query per label.
    private func top(of frame: XCUIElement, among labels: [String]) -> (label: String, offset: CGFloat)? {
        let got = ProbeSnapshot(frame, labels: labels).flatMap { top(in: $0, among: labels) }
        if ProbeSnapshot.compare { compareRead("top", describe(queriedTop(of: frame, among: labels)), describe(got)) }
        return got
    }

    private func top(in snap: ProbeSnapshot, among labels: [String]) -> (label: String, offset: CGFloat)? {
        var best: (String, CGFloat)? = nil
        for label in labels {
            guard let f = snap.visible(label) else { continue }
            let offset = f.minY - snap.frame.minY
            if offset >= -2 && offset < (best?.1 ?? .infinity) { best = (label, offset) }
        }
        return best
    }

    private let rowLabels = ["H0", "F0", "H1"] + (0..<5).map { "A\($0)" } + (0..<8).map { "B\($0)" }
    private let keyLabels = (0..<10).map { "a\($0)" } + (0..<10).map { "b\($0)" }

    /// One reading of a list: how far below its top edge `target` sits (nil
    /// off screen) and the label nearest the top, from one snapshot — the same
    /// instant for both.
    private struct ListReading {
        let target: String
        let at: CGFloat?
        let nearest: (label: String, offset: CGFloat)?

        var value: String {
            "\(target)@\(at.map { "\(Int($0))" } ?? "off") nearest \(nearest.map { "\($0.label)@\(Int($0.offset))" } ?? "none")"
        }

        /// What `check` asserts: `target` within `slack` of the top, and no
        /// label of the list nearer than its row.
        func landed(slack: CGFloat) -> Bool {
            guard let at else { return false }
            return at < slack && (nearest.map { abs(at - $0.offset) <= 1 } ?? true)
        }
    }

    private func reading(_ frame: XCUIElement, labels: [String], target: String) -> ListReading {
        let snap = ProbeSnapshot(frame, labels: labels + [target])
        let got = ListReading(target: target,
                              at: snap?.visible(target).map { $0.minY - snap!.frame.minY },
                              nearest: snap.flatMap { top(in: $0, among: labels) })
        if ProbeSnapshot.compare {
            let old = ListReading(target: target, at: queriedOffset(of: target, in: frame), nearest: queriedTop(of: frame, among: labels))
            let partly = (labels + [target]).filter { snap?.partlyVisible($0) ?? false }
            compareRead("reading", old.value, got.value, partly: partly)
        }
        return got
    }

    /// `target`'s row is at the top, on the reading the wait ended on — not on
    /// a second read: `target` sits within `slack` of the top edge, and no
    /// label of the list sits nearer than its row does.
    private func check(_ name: String, _ r: ListReading, slack: CGFloat, lines: inout [String]) {
        lines.append("\(name): \(r.target) at \(r.at.map { "\(Int($0))" } ?? "off screen"), nearest \(r.nearest.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
        guard let at = r.at else { return XCTFail("\(name): \(r.target) is not on screen") }
        XCTAssertLessThan(at, slack, "\(name): \(r.target) is \(at) below the top, not at it")
        if let nearest = r.nearest { XCTAssertEqual(at, nearest.offset, accuracy: 1, "\(name): \(nearest.label) sits above \(r.target)") }
    }

    /// Taps `button`, then reads `frame` until `target` is at the top as
    /// `check` judges it, or the list rests (Landing.wait); the series goes
    /// to `lines`. Returns the reading the wait ended on, for `check`.
    private func go(_ app: XCUIApplication, _ button: String, _ name: String, _ frame: XCUIElement, labels: [String],
                    target: String, slack: CGFloat, lines: inout [String]) -> ListReading {
        let before = reading(frame, labels: labels, target: target).value
        app.buttons[button].tap()
        var last = ListReading(target: target, at: nil, nearest: nil)
        lines.append(Landing.wait(name, from: before) {
            last = reading(frame, labels: labels, target: target)
            return (last.value, last.landed(slack: slack))
        })
        return last
    }

    /// `top`'s answer as one reading: the label and how far below.
    private func nearest(_ frame: XCUIElement, among labels: [String]) -> String {
        describe(top(of: frame, among: labels))
    }

    private func describe(_ top: (label: String, offset: CGFloat)?) -> String {
        top.map { "\($0.label)@\(Int($0.offset))" } ?? "none"
    }

    // MARK: The same readings by one query per label — what the probe read
    // before ProbeSnapshot. Only for CONFORMANCE_PROBE_READ_COMPARE=1.

    private func queriedTop(of frame: XCUIElement, among labels: [String]) -> (label: String, offset: CGFloat)? {
        let frameTop = frame.frame.minY
        var best: (String, CGFloat)? = nil
        for label in labels {
            let e = frame.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
            guard e.exists && e.isHittable else { continue }
            let offset = e.frame.minY - frameTop
            if offset >= -2 && offset < (best?.1 ?? .infinity) { best = (label, offset) }
        }
        return best
    }

    private func queriedOffset(of label: String, in frame: XCUIElement) -> CGFloat? {
        let e = frame.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
        guard e.exists && e.isHittable else { return nil }
        return e.frame.minY - frame.frame.minY
    }

    private func queriedOnPage(_ frame: XCUIElement, among labels: [String]) -> [String] {
        labels.filter { label in
            let e = frame.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
            return e.exists && e.isHittable && frame.frame.contains(CGPoint(x: e.frame.midX, y: e.frame.midY))
        }
    }

    private func compareRead(_ kind: String, _ old: String, _ new: String, partly: [String] = []) {
        print("PROBE_READ \(old == new ? "SAME" : "DIFF") \(kind) | queried: \(old) | snapshot: \(new) | partly visible: \(partly)")
    }

    private func run(prefix: String, argument: String, dynamic: Bool) {
        let app = launch(argument)
        var lines: [String] = []
        let p = prefix
        let initial = element(app, "\(p)_route_initial")
        XCTAssertTrue(initial.waitForExistence(timeout: 5), "\(p): no initial list")
        let drawn = top(of: initial, among: rowLabels)
        lines.append("\(p)_route_initial drawn with 6: nearest \(drawn.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
        XCTAssertEqual(drawn?.label, "H0", "\(p): the value it is drawn with scrolled it")

        for (route, slack) in [("flow", CGFloat(10)), ("list", CGFloat(24))] {
            let index = element(app, "\(p)_route_\(route)")
            XCTAssertTrue(index.waitForExistence(timeout: 5), "\(p): no \(route)")
            let afterSix = go(app, "\(p) \(route) go 6", "\(p)_route_\(route) after 6", index, labels: rowLabels, target: "B1", slack: slack, lines: &lines)
            check("\(p)_route_\(route) after 6", afterSix, slack: slack, lines: &lines)

            let key = element(app, "\(p)_route_\(route)_key")
            let afterK3 = go(app, "\(p) \(route) go k3", "\(p)_route_\(route)_key after k3", key, labels: keyLabels, target: "a3", slack: slack, lines: &lines)
            check("\(p)_route_\(route)_key after k3", afterK3, slack: slack, lines: &lines)
        }

        if dynamic {
            let none = element(app, "dyn_route_nil")
            lines.append("dyn_route_nil drawn with none: nearest \(top(of: none, among: rowLabels).map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
            let nilAfterSix = go(app, "dyn nil go 6", "dyn_route_nil after 6", none, labels: rowLabels, target: "B1", slack: 10, lines: &lines)
            check("dyn_route_nil after 6", nilAfterSix, slack: 10, lines: &lines)
        }
        report(lines, "SPR")
    }

    /// The pager's page on screen: of `labels`, the ones whose view sits
    /// inside `frame` (its centre — ProbeSnapshot.visible).
    private func onPage(_ frame: XCUIElement, among labels: [String]) -> [String] {
        let snap = ProbeSnapshot(frame, labels: labels)
        let got = labels.filter { snap?.visible($0) != nil }
        if ProbeSnapshot.compare {
            compareRead("onPage", "\(queriedOnPage(frame, among: labels))", "\(got)", partly: labels.filter { snap?.partlyVisible($0) ?? false })
        }
        return got
    }

    private func runSecond(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        let classLabels = (0..<5).map { "A\($0)" } + (0..<8).map { "B\($0)" }
        let cellIdLabels = (0..<10).map { "a\($0)" } + (0..<10).map { "b\($0)" }

        let list = element(app, "\(p)_route_class")
        XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p): no class-list List")
        let classAfterSix = go(app, "\(p) class go 6", "\(p)_route_class after 6", list, labels: classLabels, target: "B1", slack: 24, lines: &lines)
        check("\(p)_route_class after 6", classAfterSix, slack: 24, lines: &lines)
        let classAfterK3 = go(app, "\(p) class go k3", "\(p)_route_class_key after k3", element(app, "\(p)_route_class_key"), labels: keyLabels, target: "a3", slack: 24, lines: &lines)
        check("\(p)_route_class_key after k3", classAfterK3, slack: 24, lines: &lines)

        for (go, id, want, labels) in [("\(p) pager go 6", "\(p)_route_pager", "B1", classLabels),
                                        ("\(p) pager go k3", "\(p)_route_pager_key", "a3", keyLabels)] {
            let pager = element(app, id)
            XCTAssertTrue(pager.waitForExistence(timeout: 5), "\(p): no \(id)")
            let before = onPage(pager, among: labels)
            app.buttons[go].tap()
            var after: [String] = []
            lines.append(Landing.wait(id, from: "\(before)", landed: { $0 == "\([want])" }) {
                after = onPage(pager, among: labels)
                return "\(after)"
            })
            lines.append("\(id): page before \(before), after \(go.split(separator: " ").last ?? ""): \(after)")
            XCTAssertEqual(after, [want], "\(id): the page on screen is not \(want)'s")
        }

        let cellId = element(app, "\(p)_route_cellid")
        let cellIdAfterC3 = go(app, "\(p) cellid go c3", "\(p)_route_cellid after c3", cellId, labels: cellIdLabels, target: "a3", slack: 10, lines: &lines)
        check("\(p)_route_cellid after c3", cellIdAfterC3, slack: 10, lines: &lines)
        report(lines, "SPR2")
    }

    private func runThird(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        for (route, slack) in [("list", CGFloat(10)), ("class", CGFloat(24))] {
            let list = element(app, "\(p)_route_int_\(route)")
            XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p): no int \(route)")
            let afterTwelve = go(app, "\(p) int \(route) go 12", "\(p)_route_int_\(route) after 12", list, labels: keyLabels, target: "b2", slack: slack, lines: &lines)
            check("\(p)_route_int_\(route) after 12", afterTwelve, slack: slack, lines: &lines)
        }
        let pager = element(app, "\(p)_route_int_pager")
        XCTAssertTrue(pager.waitForExistence(timeout: 5), "\(p): no int pager")
        let before = onPage(pager, among: keyLabels)
        app.buttons["\(p) int pager go 12"].tap()
        var after: [String] = []
        lines.append(Landing.wait("\(p)_route_int_pager", from: "\(before)", landed: { $0 == "\(["b2"])" }) {
            after = onPage(pager, among: keyLabels)
            return "\(after)"
        })
        lines.append("\(p)_route_int_pager: page before \(before), after 12: \(after)")
        XCTAssertEqual(after, ["b2"], "\(p)_route_int_pager: the page on screen is not b2's")

        let dup = element(app, "\(p)_route_dup")
        XCTAssertTrue(dup.waitForExistence(timeout: 5), "\(p): no dup list")
        let dupLabels = (0..<10).map { "g\($0)" } + (0..<10).map { "h\($0)" }
        for (value, want) in [("3", "g1"), ("k", "g6"), ("w5", "h5"), ("k", "g6")] {
            let before = nearest(dup, among: dupLabels)
            app.buttons["\(p) dup go \(value)"].tap()
            var landed: (label: String, offset: CGFloat)? = nil
            lines.append(Landing.wait("\(p)_route_dup go \(value)", from: before) {
                landed = top(of: dup, among: dupLabels)
                return (describe(landed), landed?.label == want)
            })
            lines.append("\(p)_route_dup after \(value): nearest \(landed.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
            XCTAssertEqual(landed?.label, want, "\(p)_route_dup: after \"\(value)\" the top is not \(want)")
        }
        report(lines, "SPR3")
    }

    private func runFourth(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        let list = element(app, "\(p)_route_auto_list")
        let classList = element(app, "\(p)_route_auto_class")
        let pager = element(app, "\(p)_route_auto_pager")
        XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p): no auto list")
        // All three stay at a0 — nothing lands, so they must rest for the 2 s
        // the fixed sleep gave a move to show.
        var autoTops: [(name: String, at: (label: String, offset: CGFloat)?)] = []
        var autoPage: [String] = []
        let autoReading = { () -> String in
            autoTops = [("list", self.top(of: list, among: self.keyLabels)), ("class", self.top(of: classList, among: self.keyLabels))]
            autoPage = self.onPage(pager, among: self.keyLabels)
            return "list \(self.describe(autoTops[0].at)) class \(self.describe(autoTops[1].at)) pager \(autoPage)"
        }
        app.buttons["\(p) auto go k3"].tap()
        lines.append(Landing.wait("\(p)_route_auto go k3", still: 2, read: autoReading))
        for (name, at) in autoTops {
            lines.append("\(p)_route_auto_\(name) after k3: nearest \(at.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
            XCTAssertEqual(at?.label, "a0", "\(p)_route_auto_\(name): the data's own key moved it")
        }
        let raw = autoPage
        lines.append("\(p)_route_auto_pager after k3: \(raw)")
        XCTAssertEqual(raw, ["a0"], "\(p)_route_auto_pager: the data's own key turned it")
        var listK3 = ListReading(target: "a3", at: nil, nearest: nil)
        var classK3 = ListReading(target: "a3", at: nil, nearest: nil)
        var enriched: [String] = []
        let k3Reading = { () -> (value: String, landed: Bool) in
            listK3 = self.reading(list, labels: self.keyLabels, target: "a3")
            classK3 = self.reading(classList, labels: self.keyLabels, target: "a3")
            enriched = self.onPage(pager, among: self.keyLabels)
            return ("list \(listK3.value) class \(classK3.value) pager \(enriched)",
                    listK3.landed(slack: 10) && classK3.landed(slack: 24) && enriched == ["a3"])
        }
        // `before` by the same reading the wait takes. It was autoReading's,
        // another format, so the first reading already differed from it — the
        // list counted as moved at once, and rested (the start-delay specimen
        // caught it: still 1s at 1.32s, a3 off screen).
        let autoBefore = k3Reading().value
        app.buttons["\(p) auto go k3~"].tap()
        lines.append(Landing.wait("\(p)_route_auto go k3~", from: autoBefore, read: k3Reading))
        check("\(p)_route_auto_list after k3~", listK3, slack: 10, lines: &lines)
        check("\(p)_route_auto_class after k3~", classK3, slack: 24, lines: &lines)
        lines.append("\(p)_route_auto_pager after k3~: \(enriched)")
        XCTAssertEqual(enriched, ["a3"], "\(p)_route_auto_pager: a3's cellId did not turn it to a3")

        let cellId = element(app, "\(p)_route_cellid2")
        let labels = (0..<10).map { "c\($0)" } + (0..<10).map { "d\($0)" }
        for (value, want) in [("c2", "c2"), ("1:3", "c2"), ("e4", "d4"), ("c2", "c2")] {
            let before = nearest(cellId, among: labels)
            app.buttons["\(p) cellid2 go \(value)"].tap()
            var landed: (label: String, offset: CGFloat)? = nil
            lines.append(Landing.wait("\(p)_route_cellid2 go \(value)", from: before) {
                landed = top(of: cellId, among: labels)
                return (describe(landed), landed?.label == want)
            })
            lines.append("\(p)_route_cellid2 after \(value): nearest \(landed.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
            XCTAssertEqual(landed?.label, want, "\(p)_route_cellid2: after \"\(value)\" the top is not \(want)")
        }
        report(lines, "SPR4")
    }

    /// Every one of `labels` drawn once in `id`'s frame, in that order.
    private func drawnOnceInOrder(_ app: XCUIApplication, _ id: String, _ labels: [String], lines: inout [String]) {
        let list = element(app, id)
        XCTAssertTrue(list.waitForExistence(timeout: 5), "no \(id)")
        var ys: [CGFloat] = []
        for label in labels {
            let matches = list.staticTexts.matching(NSPredicate(format: "label == %@", label))
            let count = matches.count
            let y = count > 0 ? matches.firstMatch.frame.minY - list.frame.minY : -1
            lines.append("\(id) \(label): drawn \(count) time(s), y=\(Int(y))")
            XCTAssertEqual(count, 1, "\(id): \(label) is drawn \(count) time(s)")
            ys.append(y)
        }
        XCTAssertEqual(ys, ys.sorted(), "\(id): the cells are not in their order")
    }

    private func runFifth(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        drawnOnceInOrder(app, "\(p)_route_dup_noscroll", (0..<6).map { "n\($0)" }, lines: &lines)
        report(lines, "SPR5")
    }

    private func runSixth(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        drawnOnceInOrder(app, "\(p)_route_spell", ["s0", "s1", "s2", "H1", "t0", "t1"], lines: &lines)
        drawnOnceInOrder(app, "\(p)_route_class_dup", ["u0", "u1", "u2", "v0", "v1"], lines: &lines)
        report(lines, "SPR6")
    }

    private func runSeventh(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        XCTAssertTrue(element(app, "\(p)_hanchor_top").waitForExistence(timeout: 5), "\(p): no horizontal list")
        // Each list's a5: how far its anchored edge is from the viewport's.
        let anchored = { () -> (value: String, landed: Bool) in
            let off = ["top", "center", "bottom"].map { anchor -> CGFloat? in
                let frame = self.element(app, "\(p)_hanchor_\(anchor)").frame
                let cell = self.element(app, "\(p)_hanchor_\(anchor)_item_5")
                guard cell.exists else { return nil }
                let c = cell.frame
                return anchor == "top" ? c.minX - frame.minX : anchor == "center" ? c.midX - frame.midX : c.maxX - frame.maxX
            }
            return (off.map { $0.map { "\(Int($0))" } ?? "off" }.joined(separator: "/"), off.allSatisfy { $0.map { abs($0) <= 2 } ?? false })
        }
        let before = anchored().value
        app.buttons["\(p) h go 5"].tap()
        lines.append(Landing.wait("\(p)_hanchor go 5", from: before, read: anchored))
        for anchor in ["top", "center", "bottom"] {
            let frame = element(app, "\(p)_hanchor_\(anchor)").frame
            let cell = element(app, "\(p)_hanchor_\(anchor)_item_5")
            guard cell.exists else {
                lines.append("\(p)_hanchor_\(anchor): a5 not on screen")
                XCTFail("\(p)_hanchor_\(anchor): a5 is not on screen")
                continue
            }
            let c = cell.frame
            let (edge, want, got): (String, CGFloat, CGFloat) = anchor == "top" ? ("leading", frame.minX, c.minX)
                : anchor == "center" ? ("middle", frame.midX, c.midX) : ("trailing", frame.maxX, c.maxX)
            lines.append("\(p)_hanchor_\(anchor): a5 x \(Int(c.minX - frame.minX))…\(Int(c.maxX - frame.minX)) in 0…\(Int(frame.width)); \(edge) off by \(Int(got - want))")
            XCTAssertEqual(got, want, accuracy: 2, "\(p)_hanchor_\(anchor): a5's \(edge) edge is not at the viewport's")
        }
        report(lines, "SPR7")
    }

    private func runEighth(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        XCTAssertTrue(element(app, "\(p)_hstart_top").waitForExistence(timeout: 5), "\(p): no horizontal list")
        // Nothing is tapped: the lists start where they start. Read until
        // they rest, the first cell on screen and its x in each.
        lines.append(Landing.wait("\(p)_hstart drawn") {
            ["top", "center", "bottom"].map { anchor -> String in
                let frame = element(app, "\(p)_hstart_\(anchor)").frame
                let first = (0..<10).lazy.map { (i: $0, e: self.element(app, "\(p)_hstart_\(anchor)_item_\($0)")) }
                    .first { $0.e.exists && $0.e.frame.intersects(frame) }
                return first.map { "\($0.i)@\(Int($0.e.frame.minX - frame.minX))" } ?? "none"
            }.joined(separator: "/")
        })
        for anchor in ["top", "center", "bottom"] {
            let frame = element(app, "\(p)_hstart_\(anchor)").frame
            // The cells on screen, by their address: the content's leading
            // edge and its width follow from two neighbours' places.
            let seen = (0..<10).compactMap { i -> (Int, CGRect)? in
                let e = element(app, "\(p)_hstart_\(anchor)_item_\(i)")
                return e.exists && e.frame.intersects(frame) ? (i, e.frame) : nil
            }
            guard let first = seen.first, seen.count >= 2 else {
                lines.append("\(p)_hstart_\(anchor): fewer than two cells on screen")
                XCTFail("\(p)_hstart_\(anchor): fewer than two cells on screen")
                continue
            }
            let pitch = seen[1].1.minX - first.1.minX
            let width = first.1.width
            let start = first.1.minX - pitch * CGFloat(first.0)
            let end = start + pitch * 9 + width
            let (edge, want, got): (String, CGFloat, CGFloat) = anchor == "top" ? ("leading", frame.minX, start)
                : anchor == "center" ? ("middle", frame.midX, (start + end) / 2) : ("trailing", frame.maxX, end)
            lines.append("\(p)_hstart_\(anchor): content x \(Int(start - frame.minX))…\(Int(end - frame.minX)) in 0…\(Int(frame.width)); \(edge) off by \(Int(got - want))")
            XCTAssertEqual(got, want, accuracy: 2, "\(p)_hstart_\(anchor): the content's \(edge) is not at the viewport's")
        }
        report(lines, "SPR8")
    }

    func testAHorizontalDefaultAnchorIsAlongTheScrollAxisDynamic() throws {
        runEighth(prefix: "dyn", argument: "-scrollRouteProbe8")
    }

    func testAHorizontalDefaultAnchorIsAlongTheScrollAxisGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runEighth(prefix: "cg", argument: "-scrollRouteProbe8Codegen")
    }

    func testAHorizontalAnchorIsAlongTheScrollAxisDynamic() throws {
        runSeventh(prefix: "dyn", argument: "-scrollRouteProbe7")
    }

    func testAHorizontalAnchorIsAlongTheScrollAxisGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runSeventh(prefix: "cg", argument: "-scrollRouteProbe7Codegen")
    }

    func testAKeyCannotSpellAnotherSectionsIdDynamic() throws {
        runSixth(prefix: "dyn", argument: "-scrollRouteProbe6")
    }

    func testAKeyCannotSpellAnotherSectionsIdGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runSixth(prefix: "cg", argument: "-scrollRouteProbe6Codegen")
    }

    func testTheEnrichedKeyAndTheCellIdsAreKeysByOneRuleDynamic() throws {
        runFourth(prefix: "dyn", argument: "-scrollRouteProbe4")
    }

    func testTheEnrichedKeyAndTheCellIdsAreKeysByOneRuleGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runFourth(prefix: "cg", argument: "-scrollRouteProbe4Codegen")
    }

    func testARepeatedKeyWithNoScrollToDrawsEveryCellOnceDynamic() throws {
        runFifth(prefix: "dyn", argument: "-scrollRouteProbe5")
    }

    func testARepeatedKeyWithNoScrollToDrawsEveryCellOnceGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runFifth(prefix: "cg", argument: "-scrollRouteProbe5Codegen")
    }

    func testAnIntWithCellIdPropertyAndADuplicateKeyDynamic() throws {
        runThird(prefix: "dyn", argument: "-scrollRouteProbe3")
    }

    func testAnIntWithCellIdPropertyAndADuplicateKeyGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runThird(prefix: "cg", argument: "-scrollRouteProbe3Codegen")
    }

    func testTheClassListPagerAndCellIdRoutesDynamic() throws {
        runSecond(prefix: "dyn", argument: "-scrollRouteProbe2")
    }

    func testTheClassListPagerAndCellIdRoutesGenerated() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        runSecond(prefix: "cg", argument: "-scrollRouteProbe2Codegen")
    }

    func testTheDynamicRoutesScrollOnAChange() throws {
        run(prefix: "dyn", argument: "-scrollRouteProbe", dynamic: true)
    }

    func testTheGeneratedRoutesScrollOnAChange() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-scrollRouteProbeCodegen", dynamic: false)
    }
}
