//
//  IncludeIdsSharedFixtureTests.swift
//  SwiftJsonUITests
//
//  The ids an expanded screen carries, answered by jsonui-cli's shared
//  fixture (shared/core/include_ids_fixture.json, copied byte-identical into
//  Fixtures/; CI's vendored-attr-guard job compares the copy with the file at
//  the pinned jsonui-cli ref). jsonui-cli reads the same file against its
//  Python expander and the generated SwiftUI / Compose / React code, so a
//  pass here is the Dynamic runtime landing on the ids they land on.
//
//  `expected` is a SORTED LIST WITH DUPLICATES KEPT, and is compared as one:
//  a partial included twice under the same id carries its ids twice, and a
//  set would make that specimen read the same as including it once.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class IncludeIdsSharedFixtureTests: XCTestCase {

    private struct Specimen {
        let layouts: [String: Any]
        let expected: [String]
    }

    private func loadFixture() throws -> (screen: String, specimens: [String: Specimen]) {
        let data = try TestFixtures.loadJSON(named: "include_ids_fixture")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let screen = try XCTUnwrap(root["screen"] as? String, "fixture has no screen name")
        let raw = try XCTUnwrap(root["specimens"] as? [String: [String: Any]], "fixture has no specimens")
        var specimens: [String: Specimen] = [:]
        for (name, specimen) in raw {
            specimens[name] = Specimen(
                layouts: try XCTUnwrap(specimen["layouts"] as? [String: Any], "[\(name)] no layouts"),
                expected: try XCTUnwrap(specimen["expected"] as? [String], "[\(name)] no expected")
            )
        }
        return (screen, specimens)
    }

    private func collectIds(_ node: Any, into ids: inout [String]) {
        guard let dict = node as? [String: Any] else { return }
        if let id = dict["id"] as? String { ids.append(id) }
        var children: [Any] = []
        if let array = dict["child"] as? [Any] { children += array } else if let one = dict["child"] { children.append(one) }
        if let array = dict["children"] as? [Any] { children += array }
        for child in children { collectIds(child, into: &ids) }
    }

    /// Writes a specimen's layouts under a fresh layouts root, at the paths
    /// the fixture keys them by, and expands its screen from that root.
    private func expandedIds(_ specimen: Specimen, screen: String) throws -> [String] {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("include-ids-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for (path, layout) in specimen.layouts {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: layout).write(to: url)
        }
        let screenJSON = try XCTUnwrap(specimen.layouts[screen] as? [String: Any], "no \(screen) in the specimen")
        let expanded = IncludeExpander.shared.processIncludes(screenJSON, baseDir: root.path)
        var ids: [String] = []
        collectIds(expanded, into: &ids)
        return ids.sorted()
    }

    func testEverySpecimenExpandsToTheSharedFixturesIds() throws {
        let fixture = try loadFixture()
        XCTAssertFalse(fixture.specimens.isEmpty, "the fixture has no specimens")
        for name in fixture.specimens.keys.sorted() {
            let specimen = fixture.specimens[name]!
            XCTAssertEqual(try expandedIds(specimen, screen: fixture.screen), specimen.expected, "[\(name)]")
        }
    }
}
#endif
