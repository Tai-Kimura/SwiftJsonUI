//
//  ImageAccessibilityVectorsTests.swift
//  SwiftJsonUITests
//
//  The role each image gets from its alt and the tappable around it, run
//  against jsonui-cli's shared table (shared/core/image_accessibility_vectors
//  .json, copied byte-identical into Fixtures/; CI's vendored-attr-guard
//  compares the copy with the file at the pinned jsonui-cli ref). jsonui-cli's
//  sjui / kjui codegen and KotlinJsonUI's Dynamic runtime run the same table.
//
//  The walk hands each node the nearest tappable above it, the way
//  DynamicComponentBuilder's ImageTappableMark sets `jsonuiImageTappable` on
//  everything rendered inside a component with a tap handler.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ImageAccessibilityVectorsTests: XCTestCase {

    private func roles(_ node: [String: Any], nearest: [String: Any]?, into out: inout [String: String]) {
        if ImageAccessibility.isImage(node), let id = node["id"] as? String {
            out[id] = ImageAccessibility.role(node, nearestTappable: nearest).rawValue
        }
        let inner = ImageAccessibility.isTappable(node) ? node : nearest
        for child in ImageAccessibility.children(node) {
            roles(child, nearest: inner, into: &out)
        }
    }

    func testEveryCaseGetsTheRolesTheTableGives() throws {
        let data = try TestFixtures.loadJSON(named: "image_accessibility_vectors")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty, "the table has no cases")
        var seen = Set<String>()
        for vector in cases {
            let name = vector["name"] as? String ?? "?"
            let layout = try XCTUnwrap(vector["layout"] as? [String: Any], name)
            let expected = try XCTUnwrap(vector["roles"] as? [String: String], name)
            var got: [String: String] = [:]
            roles(layout, nearest: nil, into: &got)
            XCTAssertEqual(got, expected, name)
            seen.formUnion(expected.values)
        }
        XCTAssertEqual(seen, ["label", "decorative", "control"])
    }

    func testEachRoleSaysWhatVoiceOverGets() {
        XCTAssertEqual(ImageAccessibility.spoken(role: .label, resolvedAlt: { "Logo" }), .label("Logo"))
        // A bound alt that resolves to "" is decorative.
        XCTAssertEqual(ImageAccessibility.spoken(role: .label, resolvedAlt: { "" }), .hidden)
        XCTAssertEqual(ImageAccessibility.spoken(role: .decorative, resolvedAlt: { "unused" }), .hidden)
        XCTAssertEqual(ImageAccessibility.spoken(role: .control, resolvedAlt: { "unused" }), .unchanged)
    }

    // MARK: - The dynamic path

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    private func dumped<V>(_ view: V) -> String {
        var out = ""
        dump(view, to: &out)
        return out
    }

    /// Image's declared type aliases draw an image: they used to fall to
    /// `default:` and draw the red "Unknown component type" box.
    func testImageTypeAliasesDrawTheImage() throws {
        for type in ["Image", "CircleImage", "CircleImageView", "ImageView", "Img"] {
            let c = try component(#"{"type": "\#(type)", "id": "probe", "src": "probe_asset", "width": 40, "height": 40}"#)
            let text = dumped(DynamicComponentBuilder(component: c, data: [:]).buildView(from: c))
            XCTAssertFalse(text.contains("Unknown component type"), type)
            XCTAssertTrue(text.contains("probe_asset"), type)
        }
        // Control: the same probe on a type nothing routes reads as unknown.
        let unknown = try component(#"{"type": "NotAComponent", "id": "probe", "src": "probe_asset"}"#)
        XCTAssertTrue(dumped(DynamicComponentBuilder(component: unknown, data: [:]).buildView(from: unknown))
            .contains("Unknown component type"))
    }

    func testBothImageConvertersApplyTheRole() throws {
        let image = try component(#"{"type": "Image", "src": "probe_asset", "alt": "probe_label"}"#)
        XCTAssertTrue(dumped(ImageViewConverter.convert(component: image, data: [:])).contains("ImageAccessibilityModifier"))
        let network = try component(#"{"type": "NetworkImage", "url": "https://example.com/a.png", "alt": "probe_label"}"#)
        XCTAssertTrue(dumped(NetworkImageConverter.convert(component: network, data: [:])).contains("ImageAccessibilityModifier"))
    }

    func testATappableMarksItselfAndANonTappableDoesNot() throws {
        let tappable = try component(#"{"type": "View", "onClick": "@{onMenu}", "child": []}"#)
        let plain = try component(#"{"type": "View", "child": []}"#)
        let marked = dumped(DynamicComponentBuilder(component: tappable, data: [:]).body)
        let unmarked = dumped(DynamicComponentBuilder(component: plain, data: [:]).body)
        XCTAssertTrue(marked.contains("ImageTappableMark"))
        XCTAssertTrue(marked.contains("onMenu"), "the mark carries the tappable's own JSON")
        XCTAssertTrue(unmarked.contains("ImageTappableMark"))
        XCTAssertFalse(unmarked.contains("onMenu"))
    }

    /// Re-vendored with jsonui-cli's alt declaration: the aliases fold onto
    /// the one declared attribute.
    func testTheVendoredTablesReadAltUnderItsAliases() throws {
        let described = try component(#"{"type": "Image", "contentDescription": "described"}"#)
        XCTAssertEqual(described.typedAttributes(ImageAttributes.self).alt?.rawRepresentation as? String, "described")
        let labelled = try component(#"{"type": "NetworkImage", "accessibilityLabel": "labelled"}"#)
        XCTAssertEqual(labelled.typedAttributes(NetworkImageAttributes.self).alt?.rawRepresentation as? String, "labelled")
    }
}
#endif
