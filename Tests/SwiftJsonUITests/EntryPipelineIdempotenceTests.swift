//
//  EntryPipelineIdempotenceTests.swift
//  SwiftJsonUITests
//
//  The dictionary stages a layout goes through before it is decoded —
//  StyleProcessor, then ResponsiveResolver — run twice give what they give
//  once (4f's condition on the entries that skip stages: ConformanceHost's
//  FixtureLoader applies styles and then hands the component to
//  DynamicView(component:), which will run the stages again).
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class EntryPipelineIdempotenceTests: XCTestCase {

    private var written: [URL] = []

    override func setUp() {
        super.setUp()
        StyleProcessor.clearCache()
    }

    override func tearDown() {
        written.forEach { try? FileManager.default.removeItem(at: $0) }
        StyleProcessor.clearCache()
        super.tearDown()
    }

    /// A style file where StyleProcessor reads it (Caches/Styles).
    private func style(_ name: String, _ body: [String: Any]) throws {
        let dir = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])
            .appendingPathComponent("Styles", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).json")
        try JSONSerialization.data(withJSONObject: body).write(to: url)
        written.append(url)
    }

    private func stages(_ json: [String: Any]) -> [String: Any] {
        let styled = StyleProcessor.processStyles(json)
        return ResponsiveResolver(horizontalSizeClass: .regular, verticalSizeClass: .regular).resolveTree(styled)
    }

    private func same(_ a: [String: Any], _ b: [String: Any]) -> Bool {
        NSDictionary(dictionary: a).isEqual(to: b)
    }

    private func text(_ json: [String: Any]) -> String {
        String(data: (try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])) ?? Data(), encoding: .utf8) ?? "?"
    }

    func testAStyleAppliedOnceIsNotAppliedAgain() throws {
        let tag = "idem_\(UUID().uuidString.prefix(8))"
        try style("\(tag)_red", ["fontColor": "#FF0000", "fontSize": 20])
        let once = stages(["type": "Label", "text": "a", "style": "\(tag)_red", "fontSize": 12])
        XCTAssertTrue(same(once, stages(once)), "once \(text(once)) twice \(text(stages(once)))")
    }

    func testAResponsiveBlockResolvedOnceIsNotResolvedAgain() {
        let once = stages(["type": "Label", "text": "a", "fontSize": 12, "responsive": ["regular": ["fontSize": 30]]])
        XCTAssertTrue(same(once, stages(once)), "once \(text(once)) twice \(text(stages(once)))")
    }

    /// A style that brings children, one of them styled itself: the child's
    /// style is applied the first time, as every other path applies it
    /// (4f's ruling, 1.9.0). It was left on the child, and a second pass
    /// applied it.
    func testAStyleThatBringsAStyledChild() throws {
        let tag = "idem_\(UUID().uuidString.prefix(8))"
        try style("\(tag)_red", ["fontColor": "#FF0000"])
        try style("\(tag)_box", ["child": [["type": "Label", "text": "k", "style": "\(tag)_red"]]])
        let once = stages(["type": "View", "style": "\(tag)_box"])
        let child = try XCTUnwrap((once["child"] as? [[String: Any]])?.first)
        XCTAssertEqual(child["fontColor"] as? String, "#FF0000", text(once))
        XCTAssertNil(child["style"], text(once))
        XCTAssertTrue(same(once, stages(once)), "once \(text(once)) twice \(text(stages(once)))")
    }

    /// A responsive override that names a style: applied by no path, and
    /// named (4f's ruling, 1.9.0). It was merged onto the node unapplied, and
    /// a second pass applied it.
    func testAResponsiveOverrideThatNamesAStyle() throws {
        let tag = "idem_\(UUID().uuidString.prefix(8))"
        try style("\(tag)_red", ["fontColor": "#FF0000"])
        var said: [String] = []
        ResponsiveResolver.named = false
        ResponsiveResolver.warningHandler = { said.append($0) }
        defer { ResponsiveResolver.warningHandler = nil }
        let once = stages(["type": "Label", "text": "a", "responsive": ["regular": ["style": "\(tag)_red", "fontSize": 30]]])
        XCTAssertNil(once["fontColor"], text(once))
        XCTAssertNil(once["style"], text(once))
        XCTAssertEqual(once["fontSize"] as? Int, 30, "the override's own attributes are merged")
        XCTAssertTrue(same(once, stages(once)), "once \(text(once)) twice \(text(stages(once)))")
        XCTAssertEqual(said, ["'style' inside a responsive override is not applied — put the attributes in the override"])
    }
}
#endif
