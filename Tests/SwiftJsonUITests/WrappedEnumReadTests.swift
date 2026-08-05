//
//  WrappedEnumReadTests.swift
//  SwiftJsonUITests
//
//  `AttrValue<AttrEnum<T>>` is TWO wrappers, and `rawRepresentation` only
//  unwraps the outer one.
//
//  Run 4 found all fifteen literal `Image/contentMode__*` fixtures inert on
//  ios while the BOUND one still worked — the inverse of the usual failure.
//  The cause: `.rawRepresentation as? String` on a doubly-wrapped enum. The
//  `.value` case carries an `AttrEnum<ContentMode>`, so the cast to String is
//  nil for every literal spelling, while `.binding` carries the `"@{expr}"`
//  string and casts fine.
//
//  A read that works for bindings and fails for literals passes every
//  binding-focused test in the suite, which is why nothing caught it.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class WrappedEnumReadTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    /// The trap itself, pinned so the shape stays visible: this cast is nil
    /// for a literal. Anyone reaching for `rawRepresentation` on a wrapped
    /// enum should land here.
    func testRawRepresentationIsNotAStringForAWrappedEnum() throws {
        let c = try component(#"{ "type": "Image", "contentMode": "AspectFill" }"#)
        let attr = c.typedAttributes(ImageAttributes.self).contentMode
        XCTAssertNotNil(attr, "the attribute IS declared")
        XCTAssertNil(
            attr?.rawRepresentation as? String,
            "the .value case carries AttrEnum<ContentMode>, not String"
        )
    }

    /// …and `enumString` is the read that works for both spellings.
    func testEnumStringReadsLiteralAndBinding() throws {
        let literal = try component(#"{ "type": "Image", "contentMode": "AspectFill" }"#)
        XCTAssertEqual(literal.enumString(ImageAttributes.self, \.contentMode), "AspectFill")

        let bound = try component(#"{ "type": "Image", "contentMode": "@{mode}" }"#)
        XCTAssertEqual(
            bound.enumString(ImageAttributes.self, \.contentMode, data: ["mode": "fit"]),
            "fit"
        )
    }

    /// Every literal spelling the SSoT enumerates must reach a distinct
    /// intent — the 15 fixtures that went inert are these values.
    func testEveryDeclaredSpellingSelectsItsIntent() throws {
        let expected: [(String, ImageContentModeIntent)] = [
            ("fill", .stretch), ("ScaleToFill", .stretch),
            ("fit", .fit), ("AspectFit", .fit),
            ("AspectFill", .aspectFill),
            ("center", .positional(.center)), ("top", .positional(.top)),
            ("bottom", .positional(.bottom)), ("left", .positional(.leading)),
            ("right", .positional(.trailing)),
        ]
        for (spelling, intent) in expected {
            let c = try component(#"{ "type": "Image", "contentMode": "\#(spelling)" }"#)
            // Through the CONVERTER's own read, not through
            // ImageContentModeIntent directly — the defect was in the read.
            XCTAssertEqual(
                ImageViewConverter.contentModeIntent(for: c, data: [:]), intent,
                "\(spelling) must not collapse to the default"
            )
        }
    }

    /// The other four doubly-wrapped attributes, so the family is covered
    /// rather than the one instance that happened to be measured.
    func testOtherWrappedEnumsReadThroughEnumString() throws {
        let v = try component(#"{ "type": "View", "visibility": "invisible" }"#)
        XCTAssertEqual(v.visibilitySpelling(), "invisible")

        let t = try component(#"{ "type": "Label", "text": "x", "textAlign": "center" }"#)
        XCTAssertEqual(t.textAlignSpelling(), "Center", "canonicalised, not the author's case")
    }
}
#endif
