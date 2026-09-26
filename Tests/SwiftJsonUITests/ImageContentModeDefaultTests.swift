//
//  ImageContentModeDefaultTests.swift
//  SwiftJsonUITests
//
//  An image with no contentMode draws the declared default. The default is
//  declared once, in jsonui-cli's shared/core/attribute_semantics.json
//  (`semantics.image.defaultContentMode`, the 2026-08-03 user ruling),
//  copied byte-identical into Fixtures/ (CI's vendored-fixture step compares
//  the copy with the file at the pinned jsonui-cli ref). The value is READ
//  here, not written: a changed ruling moves the expectation and turns this
//  red until the seams follow. jsonui-cli's sjui / kjui / rjui codegen and
//  KotlinJsonUI's Dynamic runtime bind to the same value (4f ruling,
//  2026-09-26, jsonui-cli 1.9.0).
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class ImageContentModeDefaultTests: XCTestCase {

    private func declared() throws -> String {
        let data = try TestFixtures.loadJSON(named: "attribute_semantics")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let semantics = try XCTUnwrap(root["semantics"] as? [String: Any])
        let image = try XCTUnwrap(semantics["image"] as? [String: Any])
        return try XCTUnwrap(image["defaultContentMode"] as? String)
    }

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    /// Image and its CircleImage spelling: the seam, and the converter's own
    /// read of a node that declares no contentMode.
    func testImageWithNoContentModeDrawsTheDeclaredDefault() throws {
        let declared = try declared()
        XCTAssertEqual(ImageContentModeIntent.from(nil), ImageContentModeIntent.from(declared))
        for type in ["Image", "CircleImage"] {
            let c = try component(#"{"type": "\#(type)", "src": "probe_asset", "width": 40, "height": 40}"#)
            XCTAssertEqual(
                ImageViewConverter.contentModeIntent(for: c, data: [:]),
                ImageContentModeIntent.from(declared),
                type
            )
        }
    }

    /// NetworkImage: the seam, Dynamic's read, and the init's default — sjui
    /// codegen passes no contentMode argument for a node that declares none,
    /// so `NetworkImage.init`'s default is what that node draws.
    func testNetworkImageWithNoContentModeDrawsTheDeclaredDefault() throws {
        let declared = try declared()
        let expected = NetworkImage.ContentMode.from(declared)
        XCTAssertEqual(NetworkImage.ContentMode.from(nil), expected)
        let c = try component(#"{"type": "NetworkImage", "url": "https://example.invalid/a.png"}"#)
        XCTAssertEqual(DynamicHelpers.getNetworkImageContentMode(from: c), expected)
        XCTAssertEqual(NetworkImage(url: "https://example.invalid/a.png").contentMode, expected)
    }

    /// The control: each comparison above can tell two modes apart.
    func testAnotherModeDrawsOtherwise() throws {
        let declared = try declared()
        let other = declared.caseInsensitiveCompare("AspectFill") == .orderedSame ? "fit" : "AspectFill"
        XCTAssertNotEqual(ImageContentModeIntent.from(other), ImageContentModeIntent.from(nil))
        XCTAssertNotEqual(NetworkImage.ContentMode.from(other), NetworkImage.ContentMode.from(nil))
    }
}
#endif
