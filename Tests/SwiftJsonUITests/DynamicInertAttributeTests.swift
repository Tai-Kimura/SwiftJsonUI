//
//  DynamicInertAttributeTests.swift
//  SwiftJsonUITests
//
//  49-F: attributes codegen emits but the SwiftUI dynamic runtime never read.
//  Each of these was declarable in a layout, passed the validator, and
//  changed nothing on screen. These pin the read paths so a silent drop
//  cannot come back.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicInertAttributeTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    // MARK: - IconLabel.selected / selectedFontColor

    /// The canonical spelling. Previously the converter only read `isOn`, so
    /// this was inert — and with it, `selectedFontColor` and `icon_on`.
    func testIconLabelReadsCanonicalSelected() throws {
        let c = try component("""
        { "type": "IconLabel", "text": "Home", "selected": true,
          "icon_on": "system:house.fill", "selectedFontColor": "#FF0000" }
        """)

        XCTAssertEqual(IconLabelConverter.resolveSelected(component: c, data: [:]), true)
    }

    func testIconLabelSelectedFalseIsNotNil() throws {
        let c = try component("""
        { "type": "IconLabel", "text": "Home", "selected": false }
        """)

        // Distinct from "not declared" — a declared false still means the
        // ViewModel owns the state, so the button must not self-toggle.
        XCTAssertEqual(IconLabelConverter.resolveSelected(component: c, data: [:]), false)
    }

    func testIconLabelSelectedResolvesBinding() throws {
        let c = try component("""
        { "type": "IconLabel", "text": "Home", "selected": "@{isActive}" }
        """)

        XCTAssertEqual(
            IconLabelConverter.resolveSelected(component: c, data: ["isActive": true]),
            true
        )
        XCTAssertEqual(
            IconLabelConverter.resolveSelected(component: c, data: ["isActive": false]),
            false
        )
    }

    /// No declaration must stay `nil`, not `false` — that is what keeps
    /// IconLabelButton's own toggle state alive.
    func testIconLabelUndeclaredSelectedIsNil() throws {
        let c = try component("""
        { "type": "IconLabel", "text": "Home" }
        """)

        XCTAssertNil(IconLabelConverter.resolveSelected(component: c, data: [:]))
    }

    /// Pre-SSoT layouts spelled it `isOn`; the fallback keeps them working.
    func testIconLabelLegacyIsOnStillRead() throws {
        let c = try component("""
        { "type": "IconLabel", "text": "Home", "isOn": true }
        """)

        XCTAssertEqual(IconLabelConverter.resolveSelected(component: c, data: [:]), true)
    }

    // MARK: - TextField.hintFontSize / placeholderColor

    /// A field with no hint styling must keep the native placeholder — no
    /// overlay, no behaviour change for every existing screen.
    func testTextFieldWithoutHintStyleDeclaresNoStyle() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name" }
        """)

        XCTAssertTrue(TextFieldConverter.placeholderStyle(component: c, data: [:]).isEmpty)
    }

    func testTextFieldHintFontSizeProducesAFont() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "hintFontSize": 11 }
        """)

        let style = TextFieldConverter.placeholderStyle(component: c, data: [:])
        XCTAssertFalse(style.isEmpty)
        XCTAssertEqual(style.font, Font.system(size: 11))
        // Size alone must not repaint the placeholder.
        XCTAssertNil(style.color)
    }

    /// `hintFontSize` is independent of the field's own `fontSize` — the
    /// whole point of the attribute is that the placeholder can differ.
    func testTextFieldHintFontSizeIsIndependentOfFieldFontSize() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "fontSize": 20, "hintFontSize": 11 }
        """)

        XCTAssertEqual(
            TextFieldConverter.placeholderStyle(component: c, data: [:]).font,
            Font.system(size: 11)
        )
    }

    /// `hintFont` without a size inherits the field's size rather than
    /// silently resizing the placeholder to the global default.
    func testTextFieldHintFontAloneInheritsFieldSize() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "fontSize": 20, "hintFont": "Helvetica" }
        """)

        XCTAssertEqual(
            TextFieldConverter.placeholderStyle(component: c, data: [:]).font,
            Font.custom("Helvetica", size: 20)
        )
    }

    func testTextFieldPlaceholderColorProducesAColor() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "placeholderColor": "#FF0000" }
        """)

        let style = TextFieldConverter.placeholderStyle(component: c, data: [:])
        XCTAssertFalse(style.isEmpty)
        XCTAssertEqual(style.color, DynamicHelpers.getColor("#FF0000"))
        // Color alone must not resize the placeholder.
        XCTAssertNil(style.font)
    }

    /// `hintColor` is the other spelling and accepts the bound form.
    func testTextFieldHintColorResolvesBinding() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "hintColor": "@{hintTint}" }
        """)

        XCTAssertEqual(
            TextFieldConverter.placeholderStyle(component: c, data: ["hintTint": "#00FF00"]).color,
            DynamicHelpers.getColor("#00FF00")
        )
    }

    /// `hintColor` is canonical, `placeholderColor` the alias — an alias
    /// never overrides the canonical spelling.
    func testTextFieldHintColorWinsOverPlaceholderColorAlias() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name",
          "placeholderColor": "#FF0000", "hintColor": "#00FF00" }
        """)

        XCTAssertEqual(
            TextFieldConverter.placeholderStyle(component: c, data: [:]).color,
            DynamicHelpers.getColor("#00FF00")
        )
    }

    // MARK: - The rule shared with codegen

    /// `sjui_tools` emits code that builds the style through this same init,
    /// so these pin the contract both render paths depend on. If codegen and
    /// dynamic ever disagree about one layout, it starts here.
    func testSharedStyleRuleMatchesTextViewFontConvention() {
        // "bold" is the weight spelling, not a font family — same rule as
        // TextViewWithPlaceholder.
        XCTAssertEqual(
            TextFieldPlaceholderStyle(hintFont: "bold", hintFontSize: 12).font,
            Font.system(size: 12, weight: .bold)
        )
        XCTAssertEqual(
            TextFieldPlaceholderStyle(hintFont: "Helvetica", hintFontSize: 12).font,
            Font.custom("Helvetica", size: 12)
        )
        // hintFontSize alone: system font at that size.
        XCTAssertEqual(
            TextFieldPlaceholderStyle(hintFontSize: 12).font,
            Font.system(size: 12)
        )
        // Nothing declared: no font, so the field's own keeps applying.
        XCTAssertNil(TextFieldPlaceholderStyle(hintColor: .red).font)
        XCTAssertTrue(TextFieldPlaceholderStyle().isEmpty)
    }

    // MARK: - Overlay alignment

    /// The overlay has to follow `textAlign`, or the placeholder and the
    /// typed text would sit in different places.
    func testPlaceholderAlignmentFollowsTextAlign() {
        XCTAssertEqual(textFieldPlaceholderAlignment(for: .leading), .leading)
        XCTAssertEqual(textFieldPlaceholderAlignment(for: .center), .center)
        XCTAssertEqual(textFieldPlaceholderAlignment(for: .trailing), .trailing)
    }
}
#endif
