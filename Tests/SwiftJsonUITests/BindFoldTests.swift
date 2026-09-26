//
//  BindFoldTests.swift
//  SwiftJsonUITests
//
//  `bind` folded on the node Dynamic draws (BindFold; jsonui-cli 1.9.0), by
//  the generated JsonUIBindPrimaryValue — against jsonui-cli's
//  shared/core/bind_fold_vectors.json, copied byte-identical into Fixtures
//  (CI compares the copy with the pinned ref). The same cases jsonui-cli's
//  codegen, its validator and KotlinJsonUI Dynamic run, so the paths fold
//  alike.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class BindFoldTests: XCTestCase {

    private func vectors() throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: TestFixtures.loadJSON(named: "bind_fold_vectors")) as? [String: Any])
    }

    private func same(_ a: [String: Any], _ b: [String: Any]) -> Bool {
        NSDictionary(dictionary: a).isEqual(to: b)
    }

    /// The table: every attributes_for case.
    func testTheGeneratedTableAnswersEveryAttributesForCase() throws {
        let cases = try XCTUnwrap(try vectors()["attributes_for_cases"] as? [[String: Any]])
        XCTAssertGreaterThan(cases.count, 5)
        for c in cases {
            let name = c["name"] as? String ?? "?"
            let answer = JsonUIBindPrimaryValue.attributes(for: c["type"] as? String ?? "", node: c["node"] as? [String: Any] ?? [:])
            XCTAssertEqual(answer, c["expect"] as? [String], name)
        }
    }

    /// The fold of one node: every case.
    func testEveryNodeFoldsAsTheSharedCasesSay() throws {
        let cases = try XCTUnwrap(try vectors()["cases"] as? [[String: Any]])
        XCTAssertGreaterThan(cases.count, 10)
        for c in cases {
            let name = c["name"] as? String ?? "?"
            let node = try XCTUnwrap(c["node"] as? [String: Any], name)
            let expect = try XCTUnwrap(c["expect"] as? [String: Any], name)
            let folded = BindFold.foldNode(node)
            XCTAssertTrue(same(folded, expect), "\(name): \(folded) != \(expect)")
        }
    }

    // MARK: - After the style merge

    private var stylesDir: String {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] + "/Styles/"
    }

    /// A style file where StyleProcessor reads one in DEBUG (the HotLoader
    /// cache directory), removed after the test.
    private func writeStyles(_ styles: [String: Any]) throws -> [String] {
        try FileManager.default.createDirectory(atPath: stylesDir, withIntermediateDirectories: true)
        var written: [String] = []
        for (name, body) in styles {
            let path = stylesDir + "\(name).json"
            try JSONSerialization.data(withJSONObject: body).write(to: URL(fileURLWithPath: path))
            written.append(path)
        }
        StyleProcessor.clearCache()
        return written
    }

    /// The style cases: the node's style merged first, then folded — the order
    /// JSONLayoutLoader.loadComponent runs (StyleProcessor, then BindFold).
    func testTheStyleCasesFoldAfterTheMerge() throws {
        let cases = try XCTUnwrap(try vectors()["style_cases"] as? [[String: Any]])
        XCTAssertEqual(cases.count, 2)
        for c in cases {
            let name = c["name"] as? String ?? "?"
            let written = try writeStyles(try XCTUnwrap(c["styles"] as? [String: Any], name))
            defer {
                written.forEach { try? FileManager.default.removeItem(atPath: $0) }
                StyleProcessor.clearCache()
            }
            let merged = StyleProcessor.processStyles(try XCTUnwrap(c["node"] as? [String: Any], name))
            var drawn = BindFold.fold(merged)
            drawn.removeValue(forKey: "style")
            let expect = try XCTUnwrap(c["drawn"] as? [String: Any], name)
            XCTAssertTrue(same(drawn, expect), "\(name): \(drawn) != \(expect)")
        }
    }

    // MARK: - After the responsive branch

    /// A value a responsive branch gives counts as set: the branch is resolved
    /// before decodeComponent(from:) folds, so on the regular width the
    /// branch's isOn is drawn and `bind` is dropped; on the compact one the
    /// lone `bind` is the isOn.
    func testAResponsiveBranchIsResolvedBeforeTheFold() throws {
        let node: [String: Any] = [
            "type": "View",
            "child": [["type": "Switch", "id": "sw", "bind": "@{on}",
                       "responsive": ["regular": ["isOn": true]]]]
        ]
        func drawnSwitch(_ horizontal: UserInterfaceSizeClass) throws -> SwitchAttributes {
            let resolved = ResponsiveResolver(horizontalSizeClass: horizontal, verticalSizeClass: .regular).resolveTree(node)
            let root = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: resolved))
            let child = try XCTUnwrap(root.childComponents?.first)
            return child.typedAttributes(SwitchAttributes.self)
        }
        let regular = try drawnSwitch(.regular)
        XCTAssertEqual(regular.isOn?.value, true, "the branch's isOn")
        XCTAssertNil(regular.common.bind, "bind beside it is dropped")
        let compact = try drawnSwitch(.compact)
        XCTAssertEqual(compact.isOn?.bindingExpression, "on", "a lone bind is the isOn")
        XCTAssertNil(compact.common.bind)
    }

    /// Nested nodes fold too, wherever they sit (`children`, a tab's inline
    /// view).
    func testNestedNodesFoldWhereverTheySit() {
        let tree: [String: Any] = [
            "type": "View",
            "child": [
                ["type": "View", "children": [["type": "Slider", "bind": "@{v}"]]],
                ["type": "TabView", "tabs": [["title": "a", "view": ["type": "Switch", "bind": "@{t}"]]]]
            ]
        ]
        let folded = BindFold.fold(tree)
        let child = folded["child"] as? [[String: Any]]
        let slider = (child?.first?["children"] as? [[String: Any]])?.first
        XCTAssertEqual(slider?["value"] as? String, "@{v}")
        XCTAssertNil(slider?["bind"])
        let tabView = (child?.last?["tabs"] as? [[String: Any]])?.first?["view"] as? [String: Any]
        XCTAssertEqual(tabView?["isOn"] as? String, "@{t}")
    }
}
#endif
