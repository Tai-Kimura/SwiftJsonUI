//
//  JsonUINormalizationTests.swift
//  SwiftJsonUITests
//
//  Stage A (renderer SSoT): `$jui` L1 normalization marker handling —
//  detection, stripping, and propagation of `isNormalized` to every
//  decoded DynamicComponent.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class JsonUINormalizationTests: XCTestCase {

    // MARK: - Marker detection

    func testIsCanonicalizedDetectsL1() {
        let layout: [String: Any] = [
            "$jui": ["normalized": "L1", "schemaVersion": 1],
            "type": "View"
        ]
        XCTAssertTrue(JsonUINormalization.isCanonicalized(layout))
    }

    func testIsCanonicalizedAcceptsL2() {
        let layout: [String: Any] = ["$jui": ["normalized": "L2"]]
        XCTAssertTrue(JsonUINormalization.isCanonicalized(layout))
    }

    func testIsCanonicalizedRejectsRawAndMalformed() {
        XCTAssertFalse(JsonUINormalization.isCanonicalized(["type": "View"]))
        XCTAssertFalse(JsonUINormalization.isCanonicalized(["$jui": "L1"]))
        XCTAssertFalse(JsonUINormalization.isCanonicalized(nil))
    }

    func testConsumeMarkerStripsKeyAndReportsLevel() {
        var layout: [String: Any] = [
            "$jui": ["normalized": "L1", "schemaVersion": 1],
            "type": "View"
        ]
        XCTAssertTrue(JsonUINormalization.consumeMarker(&layout))
        XCTAssertNil(layout["$jui"])

        var raw: [String: Any] = ["type": "View"]
        XCTAssertFalse(JsonUINormalization.consumeMarker(&raw))
    }

    // MARK: - decodeComponent threading

    func testDecodeComponentPropagatesNormalizedFlagToChildren() throws {
        let layout: [String: Any] = [
            "$jui": ["normalized": "L1", "schemaVersion": 1],
            "type": "View",
            "child": [
                ["type": "Label", "text": "Nested"]
            ]
        ]
        let component = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: layout))
        XCTAssertTrue(component.isNormalized)
        let child = try XCTUnwrap(component.childComponents?.first)
        XCTAssertTrue(child.isNormalized)
        // The marker never surfaces as an attribute
        XCTAssertNil(component.rawData["$jui"])
    }

    func testDecodeComponentDefaultsToRawLayout() throws {
        let layout: [String: Any] = [
            "type": "View",
            "child": [["type": "Label", "text": "Nested"]]
        ]
        let component = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: layout))
        XCTAssertFalse(component.isNormalized)
        XCTAssertFalse(component.childComponents?.first?.isNormalized ?? true)
    }

    func testPlainDecoderDefaultsToRawLayout() throws {
        let json = """
        { "type": "Label", "text": "Hello" }
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        XCTAssertFalse(component.isNormalized)
    }

    func testMarkerInsideDecodedTreeIsStrippedFromRawData() throws {
        // Include expansion can inline a normalized file root (which
        // carries its own marker) into a larger tree — the marker must
        // not leak into rawData even when the decoder-level flag is off.
        let layout: [String: Any] = [
            "type": "View",
            "child": [
                [
                    "$jui": ["normalized": "L1", "schemaVersion": 1],
                    "type": "Label",
                    "text": "Included"
                ]
            ]
        ]
        let component = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: layout))
        let child = try XCTUnwrap(component.childComponents?.first)
        XCTAssertNil(child.rawData["$jui"])
        XCTAssertEqual(child.text, "Included")
    }
}
#endif
