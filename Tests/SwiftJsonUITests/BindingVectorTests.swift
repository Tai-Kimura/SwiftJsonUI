//
//  BindingVectorTests.swift
//  SwiftJsonUITests
//
//  Drives the shared cross-platform binding-resolution vectors
//  (jsonui-cli shared/core/binding_vectors.json, vendored byte-identical
//  into Fixtures/) against the SwiftUI Dynamic runtime:
//    - "text"        → DynamicHelpers.processText
//    - "value"       → DynamicBindingResolver typed resolution per valueType
//    - "embedParams" → EmbedConverter.resolveParams
//  "validation"-kind cases are authoring-time validator contracts and are
//  skipped here (they are enforced by the CLI validators, not the runtime).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class BindingVectorTests: XCTestCase {

    // MARK: - Vector loading

    private struct VectorFile {
        let version: Int
        let cases: [[String: Any]]
    }

    private func loadVectors() throws -> VectorFile {
        let data = try TestFixtures.loadJSON(named: "binding_vectors")
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let root = try XCTUnwrap(json, "binding_vectors.json root is not an object")
        let version = try XCTUnwrap(root["version"] as? Int, "missing vectors version")
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]], "missing cases array")
        return VectorFile(version: version, cases: cases)
    }

    /// The runtime implements semantics version 1 — a version bump in the
    /// shared vectors must be a conscious re-vendor + review, not a drift.
    func testVectorsVersionIsOne() throws {
        let vectors = try loadVectors()
        XCTAssertEqual(vectors.version, 1)
    }

    // MARK: - All runtime cases

    func testAllRuntimeVectors() throws {
        let vectors = try loadVectors()
        var runCount = 0
        for vectorCase in vectors.cases {
            let id = vectorCase["id"] as? String ?? "(no id)"
            let kind = vectorCase["kind"] as? String ?? "runtime"
            guard kind != "validation" else { continue }
            runCount += 1
            let context = vectorCase["context"] as? String ?? ""
            switch context {
            case "text":
                runTextCase(vectorCase, id: id)
            case "value":
                runValueCase(vectorCase, id: id)
            case "embedParams":
                runEmbedParamsCase(vectorCase, id: id)
            default:
                XCTFail("[\(id)] unknown runtime context '\(context)'")
            }
        }
        // 89 total cases, 9 of them validation-kind at semantics v1
        XCTAssertEqual(runCount, 80, "unexpected number of runtime vector cases")
    }

    // MARK: - Case runners

    /// Data map for a case: data-section defaults fill absent keys only
    /// (canonical fallback precedence step 1), then the runtime data wins.
    private func effectiveData(_ vectorCase: [String: Any], dataKey: String) -> [String: Any] {
        let data = vectorCase[dataKey] as? [String: Any] ?? [:]
        var merged = vectorCase["dataDefaults"] as? [String: Any] ?? [:]
        for (key, value) in data {
            merged[key] = value
        }
        return merged
    }

    private func runTextCase(_ vectorCase: [String: Any], id: String) {
        guard let template = vectorCase["template"] as? String,
              let expect = vectorCase["expect"] as? [String: Any],
              let expectedText = expect["text"] as? String else {
            XCTFail("[\(id)] malformed text case")
            return
        }
        let data = effectiveData(vectorCase, dataKey: "data")
        let result = DynamicHelpers.processText(template, data: data)
        XCTAssertEqual(result, expectedText, "[\(id)]")
    }

    private func runValueCase(_ vectorCase: [String: Any], id: String) {
        guard let expr = vectorCase["expr"] as? String,
              let valueType = vectorCase["valueType"] as? String,
              let expect = vectorCase["expect"] as? [String: Any] else {
            XCTFail("[\(id)] malformed value case")
            return
        }
        let data = effectiveData(vectorCase, dataKey: "data")
        let expectUnresolved = (expect["outcome"] as? String) == "unresolved"

        switch valueType {
        case "string":
            let resolved = DynamicBindingResolver.resolveString(expression: expr, data: data)
            if expectUnresolved {
                XCTAssertNil(resolved, "[\(id)] expected unresolved (nil)")
            } else {
                XCTAssertEqual(resolved, expect["value"] as? String, "[\(id)]")
            }
        case "bool":
            let resolved = DynamicBindingResolver.resolveBool(expression: expr, data: data)
            if expectUnresolved {
                XCTAssertNil(resolved, "[\(id)] expected unresolved (nil)")
            } else {
                XCTAssertEqual(resolved, expect["value"] as? Bool, "[\(id)]")
            }
        case "number":
            let resolved = DynamicBindingResolver.resolveDouble(expression: expr, data: data)
            if expectUnresolved {
                XCTAssertNil(resolved, "[\(id)] expected unresolved (nil)")
            } else if let expected = (expect["value"] as? NSNumber)?.doubleValue {
                XCTAssertNotNil(resolved, "[\(id)] expected \(expected), got nil")
                if let resolved = resolved {
                    XCTAssertEqual(resolved, expected, accuracy: 1e-9, "[\(id)]")
                }
            } else {
                XCTFail("[\(id)] malformed expected number value")
            }
        default:
            XCTFail("[\(id)] unknown valueType '\(valueType)'")
        }
    }

    private func runEmbedParamsCase(_ vectorCase: [String: Any], id: String) {
        guard let params = vectorCase["params"] as? [String: Any],
              let expect = vectorCase["expect"] as? [String: Any],
              let expectedParams = expect["params"] as? [String: Any] else {
            XCTFail("[\(id)] malformed embedParams case")
            return
        }
        let parentData = effectiveData(vectorCase, dataKey: "parentData")
        let resolved = EmbedConverter.resolveParams(params, parentData: parentData)
        XCTAssertEqual(
            NSDictionary(dictionary: resolved),
            NSDictionary(dictionary: expectedParams),
            "[\(id)]"
        )
    }
}
#endif
