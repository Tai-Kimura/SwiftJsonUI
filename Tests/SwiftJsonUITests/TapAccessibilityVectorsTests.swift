//
//  TapAccessibilityVectorsTests.swift
//  SwiftJsonUITests
//
//  The tap shapes, run against jsonui-cli's shared table
//  (shared/core/tap_accessibility_vectors.json, copied byte-identical into
//  Fixtures/; CI's vendored-attr-guard compares the copy with the file at the
//  pinned jsonui-cli ref). Each layout is decoded the way the Dynamic runtime
//  decodes it (JSONLayoutLoader.decodeComponent), and the rule runs on the
//  DynamicComponent tree the converters see. The two type lists are held
//  equal to the table's, which carries component_metadata.json's
//  `interactive` declaration — a list edited here alone, or a declaration
//  changed there alone, is red.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class TapAccessibilityVectorsTests: XCTestCase {

    private func table() throws -> [String: Any] {
        let data = try TestFixtures.loadJSON(named: "tap_accessibility_vectors")
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func shapes(_ component: DynamicComponent, into out: inout [String: String?]) {
        if let id = component.id {
            out[id] = TapAccessibility.shape(of: component)?.rawValue
        }
        for child in component.childComponents ?? [] {
            shapes(child, into: &out)
        }
    }

    func testTheTypeListsAreTheTablesDeclaration() throws {
        let root = try table()
        XCTAssertEqual(TapAccessibility.interactiveTypes.sorted(), try XCTUnwrap(root["interactive_types"] as? [String]))
        XCTAssertEqual(TapAccessibility.knownTypes.sorted(), try XCTUnwrap(root["known_types"] as? [String]))
    }

    func testEveryCaseGetsTheShapesTheTableGives() throws {
        let cases = try XCTUnwrap(try table()["cases"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty, "the table has no cases")
        var seen = Set<String>()
        for vector in cases {
            let name = vector["name"] as? String ?? "?"
            let layout = try XCTUnwrap(vector["layout"] as? [String: Any], name)
            let expected = try XCTUnwrap(vector["shapes"] as? [String: Any], name)
            let component = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: layout), "\(name): did not decode")
            var got: [String: String?] = [:]
            shapes(component, into: &got)
            for (id, want) in expected {
                XCTAssertEqual(got[id] ?? nil, want as? String, "\(name): \(id)")
                if let want = want as? String { seen.insert(want) }
            }
        }
        XCTAssertEqual(seen, ["button", "combine", "none"])
    }
}
#endif
