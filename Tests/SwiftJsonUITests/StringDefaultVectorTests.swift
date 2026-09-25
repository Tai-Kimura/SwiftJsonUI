//
//  StringDefaultVectorTests.swift
//  SwiftJsonUITests
//
//  Drives the shared data-default vectors (jsonui-cli
//  shared/core/string_default_vectors.json, vendored byte-identical into
//  Fixtures/ and compared by the COPIES list in CI) through
//  DynamicView.mergeDataDefaults: dynamic mode must give each property the
//  value the code generators write for it. The same table measures sjui,
//  kjui and rjui in jsonui-cli, and KotlinJsonUI's DynamicView.
//

import XCTest
@testable import SwiftJsonUI

final class StringDefaultVectorTests: XCTestCase {

    private func loadVectors() throws -> [String: Any] {
        let data = try TestFixtures.loadJSON(named: "string_default_vectors")
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func merged(className: String, defaultValue: Any) throws -> [String: Any] {
        let node: [String: Any] = [
            "type": "View",
            "data": [["name": "probe", "class": className, "defaultValue": defaultValue]],
        ]
        let json = try JSONSerialization.data(withJSONObject: node)
        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        return DynamicView.mergeDataDefaults(component: component, externalData: [:])
    }

    /// A JSON value as the data map holds one, with its kind: numbers
    /// compared as Double, a Bool never equal to a number.
    private func plain(_ value: Any?) -> NSObject? {
        guard let value = value, !(value is NSNull) else { return nil }
        if let string = value as? String { return "string:\(string)" as NSString }
        if let list = value as? [Any] { return list.map { plain($0) ?? NSNull() } as NSArray }
        if let map = value as? [String: Any] { return map.mapValues { plain($0) ?? NSNull() } as NSDictionary }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return "bool:\(number.boolValue)" as NSString }
            return "number:\(number.doubleValue)" as NSString
        }
        return "other:\(value)" as NSString
    }

    // The code generators' sentence (jsonui-cli, measured 2026-09-26 on sjui),
    // less the layout: one wording for the notice on every face.
    func testTheWarningIsTheGeneratorsSentence() {
        XCTAssertEqual(
            DataDefaultValue.missingPlatformWarning(name: "mode", given: ["kotlin", "typescript"], className: "String"),
            "data 'mode' defaultValue is given for kotlin, typescript but not swift — swift gets the String default \"\""
        )
        XCTAssertEqual(
            DataDefaultValue.missingPlatformWarning(name: "n", given: ["kotlin"], className: "Int"),
            "data 'n' defaultValue is given for kotlin but not swift — swift gets the Int default 0"
        )
        XCTAssertEqual(
            DataDefaultValue.missingPlatformWarning(name: "o", given: ["kotlin"], className: "String?"),
            "data 'o' defaultValue is given for kotlin but not swift — swift gets nil"
        )
        XCTAssertEqual(
            DataDefaultValue.missingPlatformWarning(name: "c", given: ["kotlin"], className: "Color"),
            "data 'c' defaultValue is given for kotlin but not swift — swift gets no default (Color has no vocabulary value)"
        )
    }

    func testEverySpellingReadsAsItsText() throws {
        let rows = try XCTUnwrap(try loadVectors()["spellings"] as? [[String: Any]])
        XCTAssertGreaterThanOrEqual(rows.count, 20, "the table has spellings")
        for row in rows {
            let name = row["name"] as? String ?? "?"
            let spelling = try XCTUnwrap(row["spelling"] as? String, name)
            let text = try XCTUnwrap(row["text"] as? String, name)
            let got = try merged(className: "String", defaultValue: spelling)["probe"] as? String
            XCTAssertEqual(got.map { Array($0.unicodeScalars) }, Array(text.unicodeScalars),
                           "\(name): \(spelling) read as \(String(describing: got)), want \(text)")
        }
    }

    func testEveryValueWrittenPerPlatformGivesSwiftItsValue() throws {
        let rows = try XCTUnwrap(try loadVectors()["platforms"] as? [[String: Any]])
        XCTAssertFalse(rows.isEmpty, "the table has platform rows")
        for row in rows {
            let name = row["name"] as? String ?? "?"
            let className = try XCTUnwrap(row["class"] as? String, name)
            let declared = try XCTUnwrap(row["defaultValue"], name)
            let want = (row["expect"] as? [String: Any])?["swift"]
            let data = try merged(className: className, defaultValue: declared)
            if want == nil || want is NSNull {
                XCTAssertNil(data["probe"], "\(name): got \(String(describing: data["probe"])), want no value")
            } else {
                XCTAssertEqual(plain(data["probe"]), plain(want),
                               "\(name): got \(String(describing: data["probe"])), want \(String(describing: want))")
            }
        }
    }
}
