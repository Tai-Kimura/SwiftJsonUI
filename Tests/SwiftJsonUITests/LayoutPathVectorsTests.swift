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
import SwiftUI
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

    /// The viewId rows of the shared table (`view_id_cases`): nodes named by
    /// `_label`, each read after stamping — the id, else the drawn type with
    /// its first letter lowercased and the position.
    func testEveryViewIdCase() throws {
        let table = try XCTUnwrap(
            JSONSerialization.jsonObject(with: TestFixtures.loadJSON(named: "layout_path_vectors")) as? [String: Any])
        let cases = try XCTUnwrap(table["view_id_cases"] as? [[String: Any]])
        XCTAssertGreaterThan(cases.count, 0)
        var checked = 0
        for testCase in cases {
            let name = testCase["name"] as? String ?? "?"
            let layout = try XCTUnwrap(testCase["layout"] as? [String: Any], name)
            var found: [String: String] = [:]
            func walk(_ node: Any) {
                guard let dict = node as? [String: Any] else { return }
                if let label = dict["_label"] as? String { found[label] = LayoutPath.viewId(of: dict) }
                for field in ["child", "children"] {
                    if let list = dict[field] as? [Any] { list.forEach(walk) } else if let one = dict[field] { walk(one) }
                }
            }
            walk(LayoutPath.stamp(layout))
            let expect = try XCTUnwrap(testCase["expect"] as? [String: String], name)
            for (label, viewId) in expect {
                XCTAssertEqual(found[label], viewId, "\(name): \(label)")
                checked += 1
            }
        }
        print("LayoutPath viewId vectors: \(cases.count) cases, \(checked) nodes")
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

    /// A component the app decoded itself — no loader — is stamped on its way
    /// into DynamicView(component:) (JSONLayoutLoader.stamped), keeping its
    /// normalization; a stamped one is left as it is.
    func testAComponentDecodedWithoutTheLoaderIsStampedOnItsWayIn() throws {
        let json = #"{"type":"View","child":[{"type":"Radio","group":"g","text":"a"},{"type":"Radio","group":"g","text":"b"}]}"#
        let own = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        XCTAssertEqual(try XCTUnwrap(own.childComponents).map(LayoutPath.path(of:)), ["0", "0"], "unstamped: every node its own root")

        let stamped = JSONLayoutLoader.stamped(own)
        XCTAssertEqual(try XCTUnwrap(stamped.childComponents).map(LayoutPath.path(of:)), ["0_0", "0_1"])
        XCTAssertEqual(LayoutPath.path(of: JSONLayoutLoader.stamped(stamped)), "0", "stamped: left as it is")

        let decoder = JSONDecoder()
        JsonUINormalization.apply(to: decoder, normalized: true)
        let normalized = try decoder.decode(DynamicComponent.self, from: Data(json.utf8))
        XCTAssertTrue(JSONLayoutLoader.stamped(normalized).isNormalized, "the normalization is kept")
        XCTAssertFalse(JSONLayoutLoader.stamped(own).isNormalized)
    }

    private struct RegisteredProbe: CustomComponentAdapter {
        let componentType: String
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            AnyView(EmptyView())
        }
    }

    /// A spelling the app registers as its own component (CustomComponentRegistry)
    /// is drawn by the app as written, so it is named as written: an app's own
    /// ProgressBar is `progressBar_<path>`, as sjui's codegen names it
    /// (JsonUIShared::LayoutPath.view_id reads TypeSynonyms.drawn_type, which
    /// takes the app's spellings first). Unregistered, the same spelling is
    /// named as the built-in it is drawn as (control).
    func testASpellingTheAppRegistersIsNamedAsWritten() throws {
        let node: [String: Any] = ["type": "ProgressBar", LayoutPath.key: "0_16"]
        XCTAssertEqual(LayoutPath.viewId(of: node), "progress_0_16", "unregistered: the built-in Progress")
        CustomComponentRegistry.shared.register(RegisteredProbe(componentType: "ProgressBar"))
        defer { CustomComponentRegistry.shared.reset() }
        XCTAssertEqual(LayoutPath.viewId(of: node), "progressBar_0_16", "registered: the app's, as written")
    }
}
#endif
