//
//  IncludeMapsSharedFixtureTests.swift
//  SwiftJsonUITests
//
//  What an included layout reads, answered by jsonui-cli's shared fixture
//  (shared/core/include_maps_fixture.json, copied byte-identical into
//  Fixtures/; CI's vendored-attr-guard job compares the copy with the file at
//  the pinned jsonui-cli ref): the including layout's data, with the include
//  node's object maps over it — shared_data, then data (ruling 2026-10-02).
//  jsonui-cli reads the same file against its Python, sjui, kjui and rjui
//  expanders, so a pass here is the Dynamic runtime drawing what the
//  generated code draws. Until 10.29.2 this expander did not read an object
//  map, and wrote it over the included layout's own data array.
//
//  `expected` is, for every node of the expanded screen with a `text` or a
//  `visibility`, that value as JSON — a whole binding replaced by a literal
//  keeps the literal's type (`false` stays `false`).
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class IncludeMapsSharedFixtureTests: XCTestCase {

    private func loadFixture() throws -> (screen: String, specimens: [String: [String: Any]]) {
        let data = try TestFixtures.loadJSON(named: "include_maps_fixture")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let screen = try XCTUnwrap(root["screen"] as? String, "fixture has no screen name")
        let specimens = try XCTUnwrap(root["specimens"] as? [String: [String: Any]], "fixture has no specimens")
        return (screen, specimens)
    }

    private func drawn(_ node: Any, into out: inout [String: Any]) {
        guard let dict = node as? [String: Any] else { return }
        if let id = dict["id"] as? String {
            for key in ["text", "visibility"] { if let value = dict[key] { out[id] = value } }
        }
        if let array = dict["child"] as? [Any] { array.forEach { drawn($0, into: &out) } } else if let one = dict["child"] { drawn(one, into: &out) }
    }

    /// Writes a specimen's layouts under a fresh layouts root, at the paths
    /// the fixture keys them by, and expands its screen from that root.
    private func expandedDrawn(_ layouts: [String: Any], screen: String) throws -> NSDictionary {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("include-maps-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for (path, layout) in layouts {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: layout).write(to: url)
        }
        let screenJSON = try XCTUnwrap(layouts[screen] as? [String: Any], "no \(screen) in the specimen")
        let expanded = IncludeExpander.shared.processIncludes(screenJSON, baseDir: root.path)
        var out: [String: Any] = [:]
        drawn(expanded, into: &out)
        return out as NSDictionary
    }

    func testEverySpecimenDrawsTheSharedFixturesValues() throws {
        let fixture = try loadFixture()
        XCTAssertFalse(fixture.specimens.isEmpty, "the fixture has no specimens")
        for name in fixture.specimens.keys.sorted() {
            let specimen = fixture.specimens[name]!
            let layouts = try XCTUnwrap(specimen["layouts"] as? [String: Any], "[\(name)] no layouts")
            let expected = try XCTUnwrap(specimen["expected"] as? NSDictionary, "[\(name)] no expected")
            XCTAssertEqual(try expandedDrawn(layouts, screen: fixture.screen), expected, "[\(name)]")
        }
    }

    // The fixture's Bools and numbers sit apart only by CF type; a literal
    // inside a string must not take 1 for true.
    func testALiteralNumberOneIsNotTrue() {
        XCTAssertEqual(IncludeExpander.literalText(NSNumber(value: 1)), "1")
        XCTAssertEqual(IncludeExpander.literalText(NSNumber(value: true)), "true")
    }
}
#endif
