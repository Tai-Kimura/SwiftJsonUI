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

    // MARK: - TextField.contentType (49-E enum migration)

    /// The alias spellings canonicalise. `tel` and `phone` both mean
    /// `.telephoneNumber` — before the enum landed the converter matched the
    /// literal string "tel", so canonicalisation would have silently stopped
    /// it working.
    func testTextFieldContentTypeAliasesCanonicalise() throws {
        for spelling in ["tel", "phone", "telephoneNumber"] {
            let c = try component("""
            { "type": "TextField", "hint": "Name", "contentType": "\(spelling)" }
            """)
            XCTAssertEqual(
                c.typedAttributes(TextFieldAttributes.self).contentType?.value?.knownValue,
                .telephoneNumber,
                "contentType '\(spelling)' should canonicalise to .telephoneNumber"
            )
        }
    }

    /// An undeclared spelling passes through as `.unknown` rather than
    /// crashing or guessing — and the converter then applies nothing.
    func testTextFieldUnknownContentTypeStaysUnknown() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "contentType": "sample" }
        """)
        let value = c.typedAttributes(TextFieldAttributes.self).contentType?.value
        XCTAssertNil(value?.knownValue)
        XCTAssertNotNil(value?.unknownValue)
    }

    // MARK: - SelectBox.font

    /// SelectBoxView hard-wired `.font(.system(size:))` *inside* itself, so an
    /// outer `.font()` was always overridden and a declared `font` did
    /// nothing. Codegen (B) emits `fontName:`, so the dynamic path has to
    /// resolve it from the same place or the two render differently.
    func testSelectBoxViewHonoursFontName() {
        XCTAssertEqual(
            SelectBoxView(fontSize: 20, fontName: "Helvetica").labelFont,
            Font.custom("Helvetica", size: 20)
        )
        // "bold" is the weight spelling, not a family.
        XCTAssertEqual(
            SelectBoxView(fontSize: 20, fontName: "bold").labelFont,
            Font.system(size: 20, weight: .bold)
        )
        // Undeclared keeps the previous appearance exactly.
        XCTAssertEqual(
            SelectBoxView(fontSize: 20).labelFont,
            Font.system(size: 20)
        )
    }

    /// `labelAttributes.font` wins over the component-level spelling — the
    /// precedence `selectbox_converter.rb` already applies to fontSize and
    /// fontColor.
    func testSelectBoxLabelAttributesFontWinsOverComponentFont() throws {
        let c = try component("""
        { "type": "SelectBox", "font": "Helvetica",
          "labelAttributes": { "font": "Courier" } }
        """)
        let attrs = c.typedAttributes(SelectBoxAttributes.self)

        XCTAssertEqual(attrs.labelAttributes?["font"] as? String, "Courier")
        XCTAssertEqual(c.font, "Helvetica")
    }

    /// `hintAttributes` is the nested spelling of the same three keys.
    /// `textfield_converter.rb` merges it into the flat ones, so dynamic has
    /// to as well — otherwise one layout draws two different pictures.
    func testTextFieldHintAttributesFeedsThePlaceholderStyle() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name",
          "hintAttributes": { "fontSize": 12, "fontColor": "#FF0000" } }
        """)

        let style = TextFieldConverter.placeholderStyle(component: c, data: [:])
        XCTAssertEqual(style.font, Font.system(size: 12))
        XCTAssertEqual(style.color, DynamicHelpers.getColor("#FF0000"))
    }

    /// The nested keys win. A bag scoped to one sub-element is the more
    /// specific declaration, so it beats the flat spelling — the precedence
    /// rjui, kjui and sjui's own Label/SelectBox converters all use.
    func testTextFieldNestedHintAttributesWinOverFlatKeys() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "hintFontSize": 20, "hintColor": "#0000FF",
          "hintAttributes": { "fontSize": 12, "fontColor": "#FF0000" } }
        """)

        let style = TextFieldConverter.placeholderStyle(component: c, data: [:])
        XCTAssertEqual(style.font, Font.system(size: 12))
        XCTAssertEqual(style.color, DynamicHelpers.getColor("#FF0000"))
    }

    /// A nested bag that declares only one key leaves the others to the flat
    /// spellings — winning is per-key, not all-or-nothing.
    func testTextFieldNestedHintAttributesFallBackPerKey() throws {
        let c = try component("""
        { "type": "TextField", "hint": "Name", "hintFontSize": 20, "hintColor": "#0000FF",
          "hintAttributes": { "fontColor": "#FF0000" } }
        """)

        let style = TextFieldConverter.placeholderStyle(component: c, data: [:])
        XCTAssertEqual(style.font, Font.system(size: 20), "no nested fontSize, so the flat one stands")
        XCTAssertEqual(style.color, DynamicHelpers.getColor("#FF0000"))
    }

    // MARK: - 49-B handoff: bound forms the raw cast dropped

    /// `checked` is boolean|binding. `rawAttribute("checked") as? Bool` is nil
    /// for `@{expr}`, so a bound declaration seeded no selection at all.
    func testRadioCheckedResolvesBoundForm() throws {
        let c = try component("""
        { "type": "Radio", "id": "target", "group": "g", "checked": "@{isPicked}" }
        """)
        let attrs = c.typedAttributes(RadioAttributes.self)

        XCTAssertNil(c.rawAttribute("checked") as? Bool, "the raw cast is what used to drop it")
        XCTAssertEqual(
            DynamicHelpers.resolveBool(attrs.checked, legacy: nil, data: ["isPicked": true]),
            true
        )
        XCTAssertEqual(
            DynamicHelpers.resolveBool(attrs.checked, legacy: nil, data: ["isPicked": false]),
            false
        )
    }

    /// The literal form has to keep working unchanged.
    func testRadioCheckedLiteralStillRead() throws {
        let c = try component("""
        { "type": "Radio", "id": "target", "group": "g", "checked": true }
        """)
        XCTAssertEqual(
            DynamicHelpers.resolveBool(
                c.typedAttributes(RadioAttributes.self).checked, legacy: nil, data: [:]
            ),
            true
        )
    }

    /// `clipToBounds` is boolean|binding too, and had the same hole: the
    /// hand-decoded slot is nil for `@{expr}`, so a bound declaration never
    /// clipped. `View.clipToBounds(_:)` is the public seam codegen calls.
    func testClipToBoundsResolvesBoundForm() throws {
        let c = try component("""
        { "type": "View", "id": "target", "clipToBounds": "@{shouldClip}" }
        """)
        let attrs = c.typedAttributes(CommonAttributes.self)

        XCTAssertNil(c.clipToBounds, "the hand-decoded slot is what used to drop it")
        XCTAssertEqual(
            DynamicHelpers.resolveBool(attrs.clipToBounds, legacy: nil, data: ["shouldClip": true]),
            true
        )
        XCTAssertEqual(
            DynamicHelpers.resolveBool(attrs.clipToBounds, legacy: nil, data: ["shouldClip": false]),
            false
        )
    }

    func testClipToBoundsLiteralStillRead() throws {
        let c = try component("""
        { "type": "View", "id": "target", "clipToBounds": true }
        """)
        XCTAssertEqual(
            DynamicHelpers.resolveBool(
                c.typedAttributes(CommonAttributes.self).clipToBounds, legacy: c.clipToBounds, data: [:]
            ),
            true
        )
    }

    // MARK: - 部分ゴーサイン: the SILENT group

    /// `hint` is canonical, `placeholder` the alias — the converter read them
    /// the other way round, so the canonical spelling was the one dropped.
    func testNetworkImageHintWinsOverPlaceholderAlias() throws {
        let c = try component("""
        { "type": "NetworkImage", "hint": "from_hint", "placeholder": "from_alias" }
        """)
        XCTAssertEqual(c.typedAttributes(NetworkImageAttributes.self).hint, "from_hint")
    }

    /// `trackTintColor` is the third spelling of the ON-state track. The
    /// converter's fallback chain knew only `onTintColor` / `tint`.
    func testSwitchTrackTintColorIsDeclared() throws {
        let c = try component("""
        { "type": "Switch", "trackTintColor": "#FF0000" }
        """)
        XCTAssertEqual(c.typedAttributes(SwitchAttributes.self).trackTintColor, "#FF0000")
    }

    /// `progressTintColor` names the filled part of the track specifically, so
    /// it beats the generic `tintColor` — progress_converter.rb's precedence.
    func testSliderProgressTintColorWinsOverGenericTint() throws {
        let c = try component("""
        { "type": "Slider", "value": 0.5, "progressTintColor": "#FF0000", "tintColor": "#00FF00" }
        """)
        let attrs = c.typedAttributes(SliderAttributes.self)
        XCTAssertEqual(attrs.progressTintColor, "#FF0000")
        XCTAssertEqual(c.tintColor, "#00FF00", "the generic spelling is still there to fall back to")
    }

    /// `highlightBackground` is the UIKit-era spelling of the pressed-state
    /// background; `tapBackground` wins when both are declared.
    func testButtonTapBackgroundWinsOverHighlightBackground() throws {
        let c = try component("""
        { "type": "Button", "text": "x", "tapBackground": "#FF0000", "highlightBackground": "#00FF00" }
        """)
        XCTAssertEqual(c.tapBackground, "#FF0000")
        XCTAssertEqual(
            c.typedAttributes(ButtonAttributes.self).highlightBackground, "#00FF00",
            "and highlightBackground is what fills in when tapBackground is absent"
        )
    }

    /// `hilightColor` is a typo alias of `highlightColor`. It used to be
    /// declared as its own attribute too, which cancelled the alias; 49-E
    /// folded it, so the generated lookup now resolves the spelling.
    func testButtonHilightColorTypoAliasResolves() throws {
        let c = try component("""
        { "type": "Button", "text": "x", "hilightColor": "#FF0000" }
        """)
        XCTAssertEqual(
            c.typedAttributes(ButtonAttributes.self).highlightColor?.rawRepresentation as? String,
            "#FF0000"
        )
    }

    /// `highlighted` and `highlightBackground` are a pair: the flag with no
    /// colour, or the colour with no flag, describes nothing to draw.
    func testHighlightedPairIsRequiredTogether() throws {
        let both = try component("""
        { "type": "View", "id": "t", "highlighted": true, "highlightBackground": "#FF0000" }
        """)
        XCTAssertEqual(
            both.typedAttributes(CommonAttributes.self).highlightBackground?.rawRepresentation as? String,
            "#FF0000"
        )
        XCTAssertEqual(both.rawAttribute("highlighted") as? Bool, true)

        // The flag also accepts the bound form, which is why it is read raw
        // rather than through the hand-decoded Bool? slot.
        let bound = try component("""
        { "type": "View", "id": "t", "highlighted": "@{isOn}", "highlightBackground": "#FF0000" }
        """)
        XCTAssertNil(bound.highlighted, "the hand-decoded slot is nil for a binding")
        XCTAssertTrue(
            DynamicBindingHelper.resolveBool(
                bound.rawAttribute("highlighted"), data: ["isOn": true], fallback: false
            )
        )
    }

    /// `editable: false` is the second way to say read-only; only `enabled`
    /// was read here.
    func testTextViewEditableIsDeclared() throws {
        let c = try component("""
        { "type": "TextView", "id": "t", "editable": false }
        """)
        XCTAssertEqual(c.typedAttributes(TextViewAttributes.self).editable, false)
    }

    /// On a determinate ProgressView "stopped" is progress == 0.
    func testProgressHidesWhenStoppedIsDeclared() throws {
        let c = try component("""
        { "type": "Progress", "id": "t", "progress": 0, "hidesWhenStopped": true }
        """)
        XCTAssertEqual(c.typedAttributes(ProgressAttributes.self).hidesWhenStopped, true)
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
