//
//  InteractionStopMarkingTests.swift
//  SwiftJsonUITests
//
//  What DynamicComponentBuilder hands down for `userInteractionEnabled`,
//  measured by drawing: each probe is an app-registered component that records
//  the component it was given (`interactionStoppedAround`, the mark the tap
//  rule reads) and the `jsonuiInteractionStopped` it sees in the environment
//  (what a drawn view's taps read — a Collection's cell, an Embed's screen).
//
//  A component whose flag is false, or a binding that is false, sets the
//  environment for what it builds, and each component built under it is
//  marked; a component beside it is not.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class InteractionStopMarkingTests: XCTestCase {
    private static var marked: [String: Bool] = [:]
    private static var environment: [String: Bool] = [:]

    private struct EnvironmentProbe: View {
        let key: String
        @Environment(\.jsonuiInteractionStopped) private var stopped
        var body: some View {
            Text(key).frame(width: 40, height: 20)
                .onAppear { InteractionStopMarkingTests.environment[key] = stopped }
        }
    }

    private struct Probe: CustomComponentAdapter {
        let componentType: String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            let key = (component.rawData["id"] as? String) ?? componentType
            InteractionStopMarkingTests.marked[key] = component.interactionStoppedAround
            return AnyView(EnvironmentProbe(key: key))
        }
    }

    private static let cell = "interaction_stop_probe_cell"
    private static let screen = "interaction_stop_probe_screen"
    private var written: [URL] = []

    override func setUpWithError() throws {
        let dir = URL(fileURLWithPath: JSONLayoutLoader.getLayoutFileDirPath())
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(Self.cell).json")
        try Data(#"{"type": "InteractionStopProbe", "id": "cell"}"#.utf8).write(to: url)
        written.append(url)
        JSONLayoutLoader.clearComponentCache(for: Self.cell)
        CustomComponentRegistry.shared.registerAll([
            Probe(componentType: "InteractionStopProbe"),
            // Tier 1 of an Embed's screen: a registered adapter (a compiled
            // screen registers one), given the Embed component.
            Probe(componentType: Self.screen),
        ])
    }

    override func tearDown() {
        CustomComponentRegistry.shared.reset()
        for url in written { try? FileManager.default.removeItem(at: url) }
        JSONLayoutLoader.clearComponentCache(for: Self.cell)
        written = []
    }

    private func draw(_ json: String, data: [String: Any] = [:]) throws {
        Self.marked = [:]
        Self.environment = [:]
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        let host = UIHostingController(rootView: DynamicComponentBuilder(component: component, data: data))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.isHidden = true
    }

    private func probe(_ id: String) -> String { #"{"type": "InteractionStopProbe", "id": "\#(id)"}"# }

    func testNoFlagMarksNothing() throws {
        try draw(#"{"type": "View", "child": [\#(probe("p"))]}"#)
        XCTAssertEqual(Self.marked["p"], false)
        XCTAssertEqual(Self.environment["p"], false)
    }

    func testFalseMarksWhatItBuildsHoweverDeep() throws {
        try draw(#"{"type": "View", "userInteractionEnabled": false, "child": [\#(probe("p")), {"type": "View", "child": [\#(probe("deep"))]}]}"#)
        XCTAssertEqual(Self.marked["p"], true)
        XCTAssertEqual(Self.environment["p"], true)
        XCTAssertEqual(Self.marked["deep"], true)
        XCTAssertEqual(Self.environment["deep"], true)
    }

    func testTrueMarksNothing() throws {
        try draw(#"{"type": "View", "userInteractionEnabled": true, "child": [\#(probe("p"))]}"#)
        XCTAssertEqual(Self.marked["p"], false)
        XCTAssertEqual(Self.environment["p"], false)
    }

    func testABindingMarksWhileItIsFalse() throws {
        let json = #"{"type": "View", "userInteractionEnabled": "@{u}", "child": [\#(probe("p"))]}"#
        try draw(json, data: ["u": false])
        XCTAssertEqual(Self.marked["p"], true)
        XCTAssertEqual(Self.environment["p"], true)
        try draw(json, data: ["u": true])
        XCTAssertEqual(Self.marked["p"], false)
        XCTAssertEqual(Self.environment["p"], false)
    }

    func testAComponentBesideAStopIsNotMarked() throws {
        try draw(#"{"type": "View", "child": [{"type": "View", "userInteractionEnabled": false, "child": [\#(probe("in"))]}, \#(probe("beside"))]}"#)
        XCTAssertEqual(Self.marked["in"], true)
        XCTAssertEqual(Self.marked["beside"], false)
        XCTAssertEqual(Self.environment["beside"], false)
    }

    /// A Collection's cell is drawn in a view of its own (DynamicView); the
    /// stop around the Collection reaches it through the environment.
    func testACollectionCellInsideAStopIsMarked() throws {
        let items = CollectionDataSource(sections: [
            CollectionDataSection(cells: (viewName: Self.cell, data: [["title": "a"]]))
        ])
        let collection = #"{"type": "Collection", "id": "c", "width": "matchParent", "height": 200, "items": "@{items}", "cellClasses": ["\#(Self.cell)"]}"#
        try draw(#"{"type": "View", "width": "matchParent", "height": "matchParent", "userInteractionEnabled": false, "child": [\#(collection)]}"#,
                 data: ["items": items])
        XCTAssertEqual(Self.marked["cell"], true)
        XCTAssertEqual(Self.environment["cell"], true)
        try draw(#"{"type": "View", "width": "matchParent", "height": "matchParent", "child": [\#(collection)]}"#,
                 data: ["items": items])
        XCTAssertEqual(Self.marked["cell"], false)
        XCTAssertEqual(Self.environment["cell"], false)
    }

    /// An Embed's screen is drawn by its registered adapter; the environment
    /// reaches what it draws.
    func testAnEmbeddedScreenInsideAStopSeesTheStop() throws {
        let embed = #"{"type": "Embed", "id": "e", "screen": "\#(Self.screen)"}"#
        try draw(#"{"type": "View", "userInteractionEnabled": false, "child": [\#(embed)]}"#)
        XCTAssertEqual(Self.environment["e"], true)
        try draw(#"{"type": "View", "child": [\#(embed)]}"#)
        XCTAssertEqual(Self.environment["e"], false)
    }
}
#endif
