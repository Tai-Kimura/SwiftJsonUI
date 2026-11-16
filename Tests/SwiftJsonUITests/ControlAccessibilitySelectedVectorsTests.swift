//
//  ControlAccessibilitySelectedVectorsTests.swift
//  SwiftJsonUITests
//
//  accessibilitySelected, run against jsonui-cli's shared table
//  (shared/core/control_accessibility_vectors.json, copied byte-identical into
//  Fixtures/; CI's vendored-attr-guard compares the copy with the file at the
//  pinned jsonui-cli ref). Each layout is decoded the way the Dynamic runtime
//  decodes it (JSONLayoutLoader.decodeComponent): where a vector tells (true,
//  or a binding), VoiceOver is told `.isSelected` — a binding only while it
//  resolves true; where it tells nothing, nothing is told whatever the data.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class ControlAccessibilitySelectedVectorsTests: XCTestCase {

    /// Every bound name in the layout set to `value`.
    private func data(for layout: [String: Any], _ value: Bool) throws -> [String: Any] {
        let text = String(decoding: try JSONSerialization.data(withJSONObject: layout), as: UTF8.self)
        let regex = try NSRegularExpression(pattern: #"@\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}"#)
        var out: [String: Any] = [:]
        for m in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let r = Range(m.range(at: 1), in: text) { out[String(text[r])] = value }
        }
        return out
    }

    func testEveryVector() throws {
        let raw = try TestFixtures.loadJSON(named: "control_accessibility_vectors")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: raw) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        XCTAssertGreaterThanOrEqual(cases.count, 10)
        for c in cases {
            let name = try XCTUnwrap(c["name"] as? String)
            let layout = try XCTUnwrap(c["layout"] as? [String: Any])
            let component = try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: layout), "\(name): did not decode")
            let on = ControlAccessibility.selected(component, data: try data(for: layout, true))
            let off = ControlAccessibility.selected(component, data: try data(for: layout, false))
            switch c["selected"] {
            case is NSNull, nil:
                XCTAssertFalse(on, "\(name): tells nothing (data true)")
                XCTAssertFalse(off, "\(name): tells nothing (data false)")
            case let flag as Bool where flag:
                XCTAssertTrue(ControlAccessibility.selected(component, data: [:]), "\(name): told")
            default:
                XCTAssertTrue(on, "\(name): told while the binding is true")
                XCTAssertFalse(off, "\(name): nothing while it is false")
            }
        }
    }
}
#endif
