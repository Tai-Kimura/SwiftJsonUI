//
//  LabelHintWithoutAttributesTests.swift
//  SwiftJsonUITests
//
//  A Label's `hint` shows without `hintAttributes`, in a light default colour
//  — the configuration's placeholder colour (2026-10-05 user ruling 3). It
//  needed hintAttributes beside it, so a Label with only a hint drew nothing;
//  and a hint with hintAttributes but no colour drew in the text colour
//  (conformance host pixels: no ink / (0, 0, 0); ticket
//  sjui-label-hint-needs-hint-attributes-to-show). Read where Dynamic reads
//  it, LabelConverter.labelHint; sjui_tools' label_hint_config is its twin,
//  with its own spec.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class LabelHintWithoutAttributesTests: XCTestCase {

    private func hint(_ json: String) throws -> (text: String, color: Color?, size: CGFloat?)? {
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        return LabelConverter.labelHint(component: component,
                                        attrs: component.typedAttributes(LabelAttributes.self),
                                        data: [:])
    }

    private var placeholder: Color { Color(SwiftJsonUIConfiguration.shared.colors.placeholder) }

    func testAHintShowsWithoutHintAttributes() throws {
        let h = try XCTUnwrap(hint(#"{"type": "Label", "id": "l", "text": "", "hint": "Conformance Hint"}"#),
                              "a hint with no hintAttributes is not shown")
        XCTAssertEqual(h.text, "Conformance Hint")
        XCTAssertEqual(h.color, placeholder, "a hint with no colour is not in the placeholder colour")
    }

    func testAHintWithAttributesButNoColourIsLight() throws {
        let h = try XCTUnwrap(hint(#"{"type": "Label", "id": "l", "hint": "H", "hintAttributes": {"fontSize": 12}}"#))
        XCTAssertEqual(h.color, placeholder)
        XCTAssertEqual(h.size, 12)
    }

    func testADeclaredColourStillWins() throws {
        let h = try XCTUnwrap(hint(##"{"type": "Label", "id": "l", "hint": "H", "hintColor": "#FF0000"}"##))
        XCTAssertNotEqual(h.color, placeholder)
    }
}
#endif // DEBUG
