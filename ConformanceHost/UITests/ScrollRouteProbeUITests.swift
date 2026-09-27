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
    /// its inset). Labels on one row tie; the first in `labels` wins.
    private func top(of frame: XCUIElement, among labels: [String]) -> (label: String, offset: CGFloat)? {
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

    /// How far below `frame`'s top edge `label` sits, nil when it is not on screen.
    private func offset(of label: String, in frame: XCUIElement) -> CGFloat? {
        let e = frame.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
        guard e.exists && e.isHittable else { return nil }
        return e.frame.minY - frame.frame.minY
    }

    private let rowLabels = ["H0", "F0", "H1"] + (0..<5).map { "A\($0)" } + (0..<8).map { "B\($0)" }
    private let keyLabels = (0..<10).map { "a\($0)" } + (0..<10).map { "b\($0)" }

    /// `target`'s row is at the top: `target` sits within `slack` of the top
    /// edge, and no label of the list sits nearer than its row does.
    private func check(_ name: String, _ frame: XCUIElement, labels: [String], target: String, slack: CGFloat,
                       lines: inout [String]) {
        let at = offset(of: target, in: frame)
        let nearest = top(of: frame, among: labels)
        lines.append("\(name): \(target) at \(at.map { "\(Int($0))" } ?? "off screen"), nearest \(nearest.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
        guard let at else { return XCTFail("\(name): \(target) is not on screen") }
        XCTAssertLessThan(at, slack, "\(name): \(target) is \(at) below the top, not at it")
        if let nearest { XCTAssertEqual(at, nearest.offset, accuracy: 1, "\(name): \(nearest.label) sits above \(target)") }
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
            app.buttons["\(p) \(route) go 6"].tap()
            sleep(1)
            check("\(p)_route_\(route) after 6", index, labels: rowLabels, target: "B1", slack: slack, lines: &lines)

            let key = element(app, "\(p)_route_\(route)_key")
            app.buttons["\(p) \(route) go k3"].tap()
            sleep(1)
            check("\(p)_route_\(route)_key after k3", key, labels: keyLabels, target: "a3", slack: slack, lines: &lines)
        }

        if dynamic {
            let none = element(app, "dyn_route_nil")
            lines.append("dyn_route_nil drawn with none: nearest \(top(of: none, among: rowLabels).map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
            app.buttons["dyn nil go 6"].tap()
            sleep(1)
            check("dyn_route_nil after 6", none, labels: rowLabels, target: "B1", slack: 10, lines: &lines)
        }
        report(lines, "SPR")
    }

    /// The pager's page on screen: of `labels`, the ones whose view sits
    /// inside `frame` and can be hit.
    private func onPage(_ frame: XCUIElement, among labels: [String]) -> [String] {
        labels.filter { label in
            let e = frame.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
            return e.exists && e.isHittable && frame.frame.contains(CGPoint(x: e.frame.midX, y: e.frame.midY))
        }
    }

    private func runSecond(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        let classLabels = (0..<5).map { "A\($0)" } + (0..<8).map { "B\($0)" }
        let cellIdLabels = (0..<10).map { "a\($0)" } + (0..<10).map { "b\($0)" }

        let list = element(app, "\(p)_route_class")
        XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p): no class-list List")
        app.buttons["\(p) class go 6"].tap()
        sleep(1)
        check("\(p)_route_class after 6", list, labels: classLabels, target: "B1", slack: 24, lines: &lines)
        app.buttons["\(p) class go k3"].tap()
        sleep(1)
        check("\(p)_route_class_key after k3", element(app, "\(p)_route_class_key"), labels: keyLabels, target: "a3", slack: 24, lines: &lines)

        for (go, id, want, labels) in [("\(p) pager go 6", "\(p)_route_pager", "B1", classLabels),
                                        ("\(p) pager go k3", "\(p)_route_pager_key", "a3", keyLabels)] {
            let pager = element(app, id)
            XCTAssertTrue(pager.waitForExistence(timeout: 5), "\(p): no \(id)")
            let before = onPage(pager, among: labels)
            app.buttons[go].tap()
            sleep(2)
            let after = onPage(pager, among: labels)
            lines.append("\(id): page before \(before), after \(go.split(separator: " ").last ?? ""): \(after)")
            XCTAssertEqual(after, [want], "\(id): the page on screen is not \(want)'s")
        }

        let cellId = element(app, "\(p)_route_cellid")
        app.buttons["\(p) cellid go c3"].tap()
        sleep(1)
        check("\(p)_route_cellid after c3", cellId, labels: cellIdLabels, target: "a3", slack: 10, lines: &lines)
        report(lines, "SPR2")
    }

    private func runThird(prefix p: String, argument: String) {
        let app = launch(argument)
        var lines: [String] = []
        for (route, slack) in [("list", CGFloat(10)), ("class", CGFloat(24))] {
            let list = element(app, "\(p)_route_int_\(route)")
            XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p): no int \(route)")
            app.buttons["\(p) int \(route) go 12"].tap()
            sleep(1)
            check("\(p)_route_int_\(route) after 12", list, labels: keyLabels, target: "b2", slack: slack, lines: &lines)
        }
        let pager = element(app, "\(p)_route_int_pager")
        XCTAssertTrue(pager.waitForExistence(timeout: 5), "\(p): no int pager")
        let before = onPage(pager, among: keyLabels)
        app.buttons["\(p) int pager go 12"].tap()
        sleep(2)
        let after = onPage(pager, among: keyLabels)
        lines.append("\(p)_route_int_pager: page before \(before), after 12: \(after)")
        XCTAssertEqual(after, ["b2"], "\(p)_route_int_pager: the page on screen is not b2's")

        let dup = element(app, "\(p)_route_dup")
        XCTAssertTrue(dup.waitForExistence(timeout: 5), "\(p): no dup list")
        let dupLabels = (0..<10).map { "g\($0)" } + (0..<10).map { "h\($0)" }
        for (value, want) in [("3", "g1"), ("k", "g6"), ("w5", "h5"), ("k", "g6")] {
            app.buttons["\(p) dup go \(value)"].tap()
            sleep(1)
            let landed = top(of: dup, among: dupLabels)
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
        app.buttons["\(p) auto go k3"].tap()
        sleep(2)
        for (name, frame) in [("list", list), ("class", classList)] {
            let at = top(of: frame, among: keyLabels)
            lines.append("\(p)_route_auto_\(name) after k3: nearest \(at.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
            XCTAssertEqual(at?.label, "a0", "\(p)_route_auto_\(name): the data's own key moved it")
        }
        let raw = onPage(pager, among: keyLabels)
        lines.append("\(p)_route_auto_pager after k3: \(raw)")
        XCTAssertEqual(raw, ["a0"], "\(p)_route_auto_pager: the data's own key turned it")
        app.buttons["\(p) auto go k3~"].tap()
        sleep(2)
        check("\(p)_route_auto_list after k3~", list, labels: keyLabels, target: "a3", slack: 10, lines: &lines)
        check("\(p)_route_auto_class after k3~", classList, labels: keyLabels, target: "a3", slack: 24, lines: &lines)
        let enriched = onPage(pager, among: keyLabels)
        lines.append("\(p)_route_auto_pager after k3~: \(enriched)")
        XCTAssertEqual(enriched, ["a3"], "\(p)_route_auto_pager: a3's cellId did not turn it to a3")

        let cellId = element(app, "\(p)_route_cellid2")
        let labels = (0..<10).map { "c\($0)" } + (0..<10).map { "d\($0)" }
        for (value, want) in [("c2", "c2"), ("1:3", "c2"), ("e4", "d4"), ("c2", "c2")] {
            app.buttons["\(p) cellid2 go \(value)"].tap()
            sleep(1)
            let landed = top(of: cellId, among: labels)
            lines.append("\(p)_route_cellid2 after \(value): nearest \(landed.map { "\($0.label)@\(Int($0.offset))" } ?? "none")")
            XCTAssertEqual(landed?.label, want, "\(p)_route_cellid2: after \"\(value)\" the top is not \(want)")
        }
        report(lines, "SPR4")
    }

    private func runFifth(prefix p: String, argument: String) {
        let app = launch(argument)
        let list = element(app, "\(p)_route_dup_noscroll")
        XCTAssertTrue(list.waitForExistence(timeout: 5), "\(p): no list")
        var lines: [String] = []
        var ys: [CGFloat] = []
        for i in 0..<6 {
            let matches = list.staticTexts.matching(NSPredicate(format: "label == %@", "n\(i)"))
            let count = matches.count
            let y = count > 0 ? matches.firstMatch.frame.minY - list.frame.minY : -1
            lines.append("\(p)_route_dup_noscroll n\(i): drawn \(count) time(s), y=\(Int(y))")
            XCTAssertEqual(count, 1, "\(p): n\(i) is drawn \(count) time(s)")
            ys.append(y)
        }
        XCTAssertEqual(ys, ys.sorted(), "\(p): the cells are not in their order")
        report(lines, "SPR5")
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
