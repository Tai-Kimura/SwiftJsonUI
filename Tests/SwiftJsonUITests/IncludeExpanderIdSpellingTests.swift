//
//  IncludeExpanderIdSpellingTests.swift
//  SwiftJsonUITests
//
//  Ruling U8 (include-child-ids-are-spelled-differently-on-each-platform):
//  an element inside an include that carries an id has ONE id on every face,
//  and it is the one the codegen writes. These arms hold the Dynamic
//  IncludeExpander to the codegen's answers.
//
//  WHERE THE EXPECTED VALUES COME FROM — both are machine output:
//  - the snake→camel table is jsonui-cli shared/core/camel_case_vectors.json,
//    copied byte-identical into Fixtures/ (CI's vendored-attr-guard compares
//    the copy with the file at the pinned jsonui-cli ref). jsonui-cli wrote it
//    by running sjui_tools and kjui_tools' include_expander.rb
//    (`to_camel_case`, `combine_with_prefix`), which agree on every row.
//  - `expectedJSON`: the ids, data names and bindings that the codegen's
//    `process_includes` produces for `specimensJSON`, run under ruby 3.2.2
//    against jsonui-cli f45a0cfc — sjui_tools and kjui_tools gave
//    byte-identical output. Nested partials sit at the layouts root so the
//    codegen's directory-relative lookup and this runtime's root-relative one
//    resolve the same files (the path rule is pinned separately below).
//  A transcription is not a compile: if the codegen's answer moves, these do
//  not follow by themselves — regenerate them from the Ruby.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class IncludeExpanderIdSpellingTests: XCTestCase {

    private let expander = IncludeExpander.shared

    // MARK: - The two functions, row by row (the snake→camel table)

    private struct CamelCaseRow: Decodable {
        let input: String
        let camel: String
        let combined: String
        let unprefixed: String
    }

    private struct CamelCaseVectors: Decodable {
        let prefix: String
        let cases: [CamelCaseRow]
    }

    /// camel = to_camel_case(input); combined = combine_with_prefix(prefix,
    /// input); unprefixed = combine_with_prefix(nil, input).
    private func camelCaseVectors() throws -> CamelCaseVectors {
        let vectors = try JSONDecoder().decode(
            CamelCaseVectors.self, from: TestFixtures.loadJSON(named: "camel_case_vectors"))
        XCTAssertFalse(vectors.cases.isEmpty, "camel_case_vectors.json has no cases")
        return vectors
    }

    func testToCamelCaseAnswersAsTheCodegenDoes() throws {
        for row in try camelCaseVectors().cases {
            XCTAssertEqual(expander.toCamelCase(row.input), row.camel, row.input)
        }
    }

    func testCombineWithPrefixAnswersAsTheCodegenDoes() throws {
        let vectors = try camelCaseVectors()
        for row in vectors.cases {
            XCTAssertEqual(expander.combineWithPrefix(vectors.prefix, row.input), row.combined, row.input)
        }
    }

    /// With no prefix the name is as written.
    func testNoPrefixLeavesEveryNameAsWritten() throws {
        for row in try camelCaseVectors().cases {
            XCTAssertEqual(expander.combineWithPrefix(nil, row.input), row.unprefixed, row.input)
        }
    }

    /// Only a nil prefix passes a name through (`return name unless prefix`).
    func testAnEmptyPrefixStillRaisesTheName() {
        XCTAssertEqual(expander.combineWithPrefix(nil, "type_badge"), "type_badge")
        XCTAssertEqual(expander.combineWithPrefix("", "type_badge"), "TypeBadge")
    }

    // MARK: - Whole layouts through processIncludes (the six specimens)

    private let specimensJSON = #"""
{
  "partials": {
    "u8_badges": {
      "type": "View",
      "id": "badges",
      "child": [
        {
          "type": "Label",
          "id": "type_badge",
          "text": "@{badge_text}"
        },
        {
          "type": "Label",
          "id": "typeBadge",
          "text": "b"
        }
      ],
      "data": [
        {
          "name": "badge_text",
          "class": "String",
          "defaultValue": ""
        }
      ]
    },
    "u8_card": {
      "type": "View",
      "id": "card",
      "child": [
        {
          "type": "Label",
          "id": "card_type_badge",
          "text": "c"
        }
      ]
    },
    "u8_plain": {
      "type": "View",
      "id": "plain",
      "child": [
        {
          "type": "Label",
          "id": "type_badge",
          "text": "p"
        },
        {
          "type": "Label",
          "id": "title",
          "text": "t"
        },
        {
          "type": "Label",
          "id": "verify_2FA_form",
          "text": "v"
        },
        {
          "type": "Label",
          "id": "clear_URL_button",
          "text": "u"
        },
        {
          "type": "Label",
          "id": "URL_field",
          "text": "f"
        },
        {
          "type": "Label",
          "id": "_leading",
          "text": "l"
        }
      ]
    },
    "u8_outer": {
      "type": "View",
      "id": "outer",
      "child": [
        {
          "include": "u8_plain",
          "id": "hero_card"
        }
      ]
    }
  },
  "screens": {
    "1_snake_and_camel_collide": {
      "type": "View",
      "id": "root",
      "child": [
        {
          "include": "u8_badges",
          "id": "hero"
        }
      ]
    },
    "2_prefix_boundary_collides": {
      "type": "View",
      "id": "root",
      "child": [
        {
          "include": "u8_card",
          "id": "hero"
        },
        {
          "include": "u8_plain",
          "id": "hero_card"
        }
      ]
    },
    "3_include_id_with_underscore": {
      "type": "View",
      "id": "root",
      "child": [
        {
          "include": "u8_plain",
          "id": "hero_card"
        }
      ]
    },
    "4_uppercase_segments": {
      "type": "View",
      "id": "root",
      "child": [
        {
          "include": "u8_plain",
          "id": "hero"
        },
        {
          "include": "u8_plain",
          "id": "info_URL"
        }
      ]
    },
    "5_nested_id_only_on_the_inner": {
      "type": "View",
      "id": "root",
      "child": [
        {
          "include": "u8_outer"
        }
      ]
    },
    "6_same_partial_twice": {
      "type": "View",
      "id": "root",
      "child": [
        {
          "include": "u8_plain",
          "id": "hero"
        },
        {
          "include": "u8_plain",
          "id": "hero"
        }
      ]
    }
  }
}
"""#

    private let expectedJSON = #"""
{
  "1_snake_and_camel_collide": {
    "ids": [
      "root",
      "heroBadges",
      "heroTypeBadge",
      "heroTypeBadge"
    ],
    "dataNames": [
      "heroBadgeText"
    ],
    "bindings": [
      "@{heroBadgeText}"
    ]
  },
  "2_prefix_boundary_collides": {
    "ids": [
      "root",
      "heroCard",
      "heroCardTypeBadge",
      "heroCardPlain",
      "heroCardTypeBadge",
      "heroCardTitle",
      "heroCardVerify2faForm",
      "heroCardClearUrlButton",
      "heroCardURLField",
      "heroCardLeading"
    ],
    "dataNames": [],
    "bindings": []
  },
  "3_include_id_with_underscore": {
    "ids": [
      "root",
      "heroCardPlain",
      "heroCardTypeBadge",
      "heroCardTitle",
      "heroCardVerify2faForm",
      "heroCardClearUrlButton",
      "heroCardURLField",
      "heroCardLeading"
    ],
    "dataNames": [],
    "bindings": []
  },
  "4_uppercase_segments": {
    "ids": [
      "root",
      "heroPlain",
      "heroTypeBadge",
      "heroTitle",
      "heroVerify2faForm",
      "heroClearUrlButton",
      "heroURLField",
      "heroLeading",
      "infoUrlPlain",
      "infoUrlTypeBadge",
      "infoUrlTitle",
      "infoUrlVerify2faForm",
      "infoUrlClearUrlButton",
      "infoUrlURLField",
      "infoUrlLeading"
    ],
    "dataNames": [],
    "bindings": []
  },
  "5_nested_id_only_on_the_inner": {
    "ids": [
      "root",
      "outer",
      "heroCardPlain",
      "heroCardTypeBadge",
      "heroCardTitle",
      "heroCardVerify2faForm",
      "heroCardClearUrlButton",
      "heroCardURLField",
      "heroCardLeading"
    ],
    "dataNames": [],
    "bindings": []
  },
  "6_same_partial_twice": {
    "ids": [
      "root",
      "heroPlain",
      "heroTypeBadge",
      "heroTitle",
      "heroVerify2faForm",
      "heroClearUrlButton",
      "heroURLField",
      "heroLeading",
      "heroPlain",
      "heroTypeBadge",
      "heroTitle",
      "heroVerify2faForm",
      "heroClearUrlButton",
      "heroURLField",
      "heroLeading"
    ],
    "dataNames": [],
    "bindings": []
  }
}
"""#

    private func object(_ text: String) -> [String: Any] {
        try! JSONSerialization.jsonObject(with: Data(text.utf8)) as! [String: Any]
    }

    private func collect(_ node: Any, ids: inout [String], data: inout [String], bindings: inout [String]) {
        guard let dict = node as? [String: Any] else { return }
        if let id = dict["id"] as? String { ids.append(id) }
        for item in (dict["data"] as? [[String: Any]]) ?? [] {
            if let name = item["name"] as? String { data.append(name) }
        }
        if let text = dict["text"] as? String, text.contains("@{") { bindings.append(text) }
        var children: [Any] = []
        if let array = dict["child"] as? [Any] { children += array } else if let one = dict["child"] { children.append(one) }
        if let array = dict["children"] as? [Any] { children += array }
        for child in children { collect(child, ids: &ids, data: &data, bindings: &bindings) }
    }

    /// Writes the partials into a fresh layouts root and expands one screen.
    private func expand(_ screen: String) throws -> (ids: [String], data: [String], bindings: [String]) {
        let specimens = object(specimensJSON)
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("u8-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for (name, layout) in specimens["partials"] as! [String: Any] {
            let data = try JSONSerialization.data(withJSONObject: layout)
            try data.write(to: root.appendingPathComponent("\(name).json"))
        }
        let screenJSON = (specimens["screens"] as! [String: Any])[screen] as! [String: Any]
        let expanded = expander.processIncludes(screenJSON, baseDir: root.path)
        var ids: [String] = [], data: [String] = [], bindings: [String] = []
        collect(expanded, ids: &ids, data: &data, bindings: &bindings)
        return (ids, data, bindings)
    }

    private func assertMatchesTheCodegen(_ screen: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let expected = object(expectedJSON)[screen] as! [String: Any]
        let actual = try expand(screen)
        XCTAssertEqual(actual.ids, expected["ids"] as! [String], "ids", file: file, line: line)
        XCTAssertEqual(actual.data, expected["dataNames"] as! [String], "data names", file: file, line: line)
        XCTAssertEqual(actual.bindings, expected["bindings"] as! [String], "bindings", file: file, line: line)
    }

    /// `type_badge` and `typeBadge` in one partial land on the same id — the
    /// codegen's collision, reproduced exactly; the data name and its binding
    /// are prefixed by the same rule.
    func testSnakeAndCamelSiblingsCollideAsInTheCodegen() throws {
        try assertMatchesTheCodegen("1_snake_and_camel_collide")
    }

    /// `hero` + `card_type_badge` and `hero_card` + `type_badge`.
    func testAPrefixBoundaryCollidesAsInTheCodegen() throws {
        try assertMatchesTheCodegen("2_prefix_boundary_collides")
    }

    /// The include id itself is camel-cased: `hero_card` gives `heroCard…`.
    func testAnIncludeIdWithAnUnderscoreIsCamelCased() throws {
        try assertMatchesTheCodegen("3_include_id_with_underscore")
    }

    /// `verify_2FA_form`, `clear_URL_button`, `URL_field`, `_leading`, and an
    /// include id `info_URL`.
    func testUppercaseSegmentsFollowCapitalize() throws {
        try assertMatchesTheCodegen("4_uppercase_segments")
    }

    /// An include without an id passes nothing down; the inner one's id is
    /// the whole prefix.
    func testANestedIncludeWithAnIdOnlyOnTheInnerOne() throws {
        try assertMatchesTheCodegen("5_nested_id_only_on_the_inner")
    }

    func testTheSamePartialTwiceGivesTheSameIdsTwice() throws {
        try assertMatchesTheCodegen("6_same_partial_twice")
    }

    // MARK: - Where a nested include is looked up (pinned as it is)

    /// A nested include path is resolved from the LAYOUTS ROOT, not from the
    /// including file's directory — measured across six faces as the form
    /// that resolves consumers' nested includes (measured 2026-09-25); the
    /// codegen's directory-relative lookup is the one being changed. Pinned
    /// so this runtime does not drift to the other rule.
    func testANestedIncludeIsResolvedFromTheLayoutsRoot() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("u8-path-\(UUID().uuidString)", isDirectory: true)
        let dir = root.appendingPathComponent("section", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        func write(_ json: [String: Any], _ url: URL) throws {
            try JSONSerialization.data(withJSONObject: json).write(to: url)
        }
        try write(["type": "Label", "id": "inner_label", "text": "i"], dir.appendingPathComponent("u8_inner.json"))
        try write(["type": "View", "id": "outer_view", "child": [["include": "section/u8_inner", "id": "from_root"]]],
                  dir.appendingPathComponent("u8_outer_root.json"))
        try write(["type": "View", "id": "outer_view", "child": [["include": "u8_inner", "id": "from_dir"]]],
                  dir.appendingPathComponent("u8_outer_dir.json"))

        func ids(of outer: String) -> [String] {
            let expanded = expander.processIncludes(["include": outer, "id": "top"], baseDir: root.path)
            var ids: [String] = [], data: [String] = [], bindings: [String] = []
            collect(expanded, ids: &ids, data: &data, bindings: &bindings)
            return ids
        }
        // Root-relative: found and expanded.
        XCTAssertEqual(ids(of: "section/u8_outer_root"), ["topOuterView", "topFromRootInnerLabel"])
        // Directory-relative: not found from the root, so the nested include
        // node is left exactly as written — its id unprefixed, nothing from
        // the partial. (The codegen raises on a missing include; there is no
        // codegen answer to compare this one with.)
        XCTAssertEqual(ids(of: "section/u8_outer_dir"), ["topOuterView", "from_dir"])
    }
}
#endif
