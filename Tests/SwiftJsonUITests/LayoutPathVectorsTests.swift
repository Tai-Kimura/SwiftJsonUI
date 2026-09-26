//
//  LayoutPathVectorsTests.swift
//  SwiftJsonUITests
//
//  A node's position in its layout (LayoutPath) — the name an id-less Radio
//  takes in its group — by the rule sjui build and kjui build run: the table
//  jsonui-cli's shared/core/layout_path_vectors.json, copied byte-identical
//  into Fixtures/ (CI's vendored-fixture step compares the copy with the file
//  at the pinned jsonui-cli ref). A case with `includes` is expanded with this
//  runtime's own IncludeExpander first, as the table says, then stamped.
//  Ticket sjui-codegen-state-declarations-collide-by-name.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class LayoutPathVectorsTests: XCTestCase {

    private func paths(_ node: Any, into found: inout [String: String]) {
        guard let dict = node as? [String: Any] else { return }
        if let id = dict["id"] as? String { found[id] = dict[LayoutPath.key] as? String ?? "(none)" }
        for field in ["child", "children"] {
            if let list = dict[field] as? [Any] { list.forEach { paths($0, into: &found) } }
            else if let one = dict[field] { paths(one, into: &found) }
        }
    }

    private func expand(_ layout: [String: Any], includes: [String: Any]) throws -> [String: Any] {
        guard !includes.isEmpty else { return layout }
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("layout-path-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for (name, included) in includes {
            try JSONSerialization.data(withJSONObject: included).write(to: root.appendingPathComponent("\(name).json"))
        }
        return IncludeExpander.shared.processIncludes(layout, baseDir: root.path)
    }

    func testEveryVectorsCase() throws {
        let table = try XCTUnwrap(
            JSONSerialization.jsonObject(with: TestFixtures.loadJSON(named: "layout_path_vectors")) as? [String: Any])
        let cases = try XCTUnwrap(table["cases"] as? [[String: Any]])
        XCTAssertGreaterThan(cases.count, 0)
        var checked = 0
        for testCase in cases {
            let name = testCase["name"] as? String ?? "?"
            let layout = try XCTUnwrap(testCase["layout"] as? [String: Any], name)
            let expanded = try expand(layout, includes: testCase["includes"] as? [String: Any] ?? [:])
            var found: [String: String] = [:]
            paths(LayoutPath.stamp(expanded), into: &found)
            let expect = try XCTUnwrap(testCase["expect"] as? [String: String], name)
            for (id, path) in expect {
                XCTAssertEqual(found[id], path, "\(name): \(id)")
                checked += 1
            }
        }
        print("LayoutPath vectors: \(cases.count) cases, \(checked) nodes")
    }

    /// JSONLayoutLoader.decodeComponent stamps a tree nobody stamped — a
    /// caller's own dictionary — so an id-less Radio gets its position there
    /// too; a tree the loader stamped keeps its paths.
    func testTheLoadersDecodeStampsAnUnstampedTreeAndKeepsAStampedOne() throws {
        let tree: [String: Any] = ["type": "View", "child": [
            ["type": "Radio", "group": "g", "text": "a"],
            ["type": "Radio", "group": "g", "text": "b"],
        ]]
        let component = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: tree))
        let radios = try XCTUnwrap(component.childComponents)
        XCTAssertEqual(radios.map(LayoutPath.path(of:)), ["0_0", "0_1"])

        var stamped = LayoutPath.stamp(tree, path: "0_3")
        stamped["type"] = "View"
        let kept = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: stamped)?.childComponents)
        XCTAssertEqual(kept.map(LayoutPath.path(of:)), ["0_3_0", "0_3_1"])
    }
}
#endif
