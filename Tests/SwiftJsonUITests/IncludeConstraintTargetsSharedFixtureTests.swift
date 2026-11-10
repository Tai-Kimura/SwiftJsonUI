//
//  IncludeConstraintTargetsSharedFixtureTests.swift
//  SwiftJsonUITests
//
//  A constraint inside an include names its target as the target is spelled
//  after expansion, answered by jsonui-cli's shared fixture
//  (shared/core/include_constraint_targets_fixture.json, copied byte-identical
//  into Fixtures/; CI's vendored-attr-guard job compares the copy with the
//  file at the pinned jsonui-cli ref). jsonui-cli reads the same file against
//  the sjui and kjui codegen expanders.
//
//  Under an include with an id the elements' ids are prefixed (`cardA`); a
//  relative constraint between two elements of the same partial kept naming
//  `a`, found nothing, and was dropped (jsonui-cli ticket
//  rjui-include-root-sibling-constraint-dropped, row D4). `expected` maps each
//  constrained element's expanded id to its constraint attributes and their
//  expanded targets.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class IncludeConstraintTargetsSharedFixtureTests: XCTestCase {

    private func collectConstraints(_ node: Any, keys: [String], into out: inout [String: [String: String]]) {
        if let array = node as? [Any] {
            for item in array { collectConstraints(item, keys: keys, into: &out) }
            return
        }
        guard let dict = node as? [String: Any] else { return }
        var found: [String: String] = [:]
        for key in keys { if let target = dict[key] as? String { found[key] = target } }
        if !found.isEmpty { out[dict["id"] as? String ?? "?"] = found }
        for key in ["child", "children"] { if let kids = dict[key] { collectConstraints(kids, keys: keys, into: &out) } }
    }

    private func expandedConstraints(_ layouts: [String: Any], screen: String, keys: [String]) throws -> [String: [String: String]] {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("include-constraints-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for (path, layout) in layouts {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: layout).write(to: url)
        }
        let screenJSON = try XCTUnwrap(layouts[screen] as? [String: Any], "no \(screen) in the specimen")
        let expanded = IncludeExpander.shared.processIncludes(screenJSON, baseDir: root.path)
        var out: [String: [String: String]] = [:]
        collectConstraints(expanded, keys: keys, into: &out)
        return out
    }

    func testEverySpecimenNamesItsTargetsAsTheSharedFixtureDoes() throws {
        let data = try TestFixtures.loadJSON(named: "include_constraint_targets_fixture")
        let fixture = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let screen = try XCTUnwrap(fixture["screen"] as? String)
        let keys = try XCTUnwrap(fixture["constraint_keys"] as? [String])
        XCTAssertEqual(keys, IncludeExpander.constraintTargetKeys, "the expander and the fixture read the same keys")
        let specimens = try XCTUnwrap(fixture["specimens"] as? [String: [String: Any]])
        XCTAssertFalse(specimens.isEmpty, "the fixture has no specimens")
        for name in specimens.keys.sorted() {
            let specimen = specimens[name]!
            let layouts = try XCTUnwrap(specimen["layouts"] as? [String: Any], "[\(name)] no layouts")
            let expected = try XCTUnwrap(specimen["expected"] as? [String: [String: String]], "[\(name)] no expected")
            XCTAssertEqual(try expandedConstraints(layouts, screen: screen, keys: keys), expected, "[\(name)]")
        }
    }
}
#endif
