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

    func testTheDynamicRoutesScrollOnAChange() throws {
        run(prefix: "dyn", argument: "-scrollRouteProbe", dynamic: true)
    }

    func testTheGeneratedRoutesScrollOnAChange() throws {
        guard codegenHost else { throw XCTSkip("the generated half is in the codegen host only") }
        run(prefix: "cg", argument: "-scrollRouteProbeCodegen", dynamic: false)
    }
}
