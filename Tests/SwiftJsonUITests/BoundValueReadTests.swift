//
//  BoundValueReadTests.swift
//  SwiftJsonUITests
//
//  The `?.value` family: reads that went through the typed extraction but
//  read only the LITERAL half of an AttrValue, so every bound spelling
//  silently rendered the default.
//
//  Found by sweeping `Dynamic/` for `?.value` direct reads after ad603b0
//  fixed the same shape in SliderConverter. Seventeen sites; twelve were
//  deliberate (a binding branch or a documented static-only contract sat
//  next to them); these pin the five that were not: Progress tint/track,
//  TabView unselectedColor, Web background, TextField contentType.
//
//  "Goes through the typed extraction" and "resolves the binding" are
//  different properties — `.value` is proof of the first and a denial of
//  the second. Neither ledger gate (raw-read / binding-slot) can see this
//  shape, which is why it is pinned here instead.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class BoundValueReadTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    // MARK: - resolveColor (the seam all four colour sites go through)

    func testBoundColourResolvesFromData() throws {
        let c = try component(#"{ "type": "Progress", "progressTintColor": "@{accent}" }"#)
        let attr = c.typedAttributes(ProgressAttributes.self).progressTintColor
        XCTAssertNil(attr?.value, "the literal half is empty — this is what the old read returned")
        XCTAssertEqual(
            DynamicHelpers.resolveColor(attr, data: ["accent": "#FF0000"]),
            DynamicHelpers.getColor("#FF0000"),
            "the bound half must reach the colour resolver"
        )
    }

    func testLiteralColourStillResolves() throws {
        let c = try component(##"{ "type": "Progress", "trackTintColor": "#00FF00" }"##)
        XCTAssertEqual(
            DynamicHelpers.resolveColor(
                c.typedAttributes(ProgressAttributes.self).trackTintColor, data: [:]
            ),
            DynamicHelpers.getColor("#00FF00")
        )
    }

    func testUnresolvedBindingIsNoColourNotBlack() throws {
        let c = try component(#"{ "type": "TabView", "unselectedColor": "@{missing}" }"#)
        XCTAssertNil(
            DynamicHelpers.resolveColor(
                c.typedAttributes(TabViewAttributes.self).unselectedColor, data: [:]
            )
        )
    }

    // MARK: - contentType (through the converter's own read)

    func testBoundContentTypeResolves() throws {
        let c = try component(#"{ "type": "TextField", "contentType": "@{kind}" }"#)
        XCTAssertEqual(
            TextFieldConverter.declaredContentType(
                c.typedAttributes(TextFieldAttributes.self).contentType,
                data: ["kind": "password"]
            ),
            .password
        )
    }

    func testLiteralContentTypeStillResolves() throws {
        let c = try component(#"{ "type": "TextField", "contentType": "username" }"#)
        XCTAssertEqual(
            TextFieldConverter.declaredContentType(
                c.typedAttributes(TextFieldAttributes.self).contentType, data: [:]
            ),
            .username
        )
    }

    func testUnknownResolvedMemberAppliesNothing() throws {
        let c = try component(#"{ "type": "TextField", "contentType": "@{kind}" }"#)
        XCTAssertNil(
            TextFieldConverter.declaredContentType(
                c.typedAttributes(TextFieldAttributes.self).contentType,
                data: ["kind": "carrier-pigeon"]
            )
        )
    }
}
#endif
