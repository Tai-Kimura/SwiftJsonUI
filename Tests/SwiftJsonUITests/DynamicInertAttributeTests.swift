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
        XCTAssertEqual(attrs.font, "Helvetica")
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

        // The hand-decoded slot is deleted (50 §4). `commonBool` is the
        // literal reader that replaced it and is nil for a binding by
        // construction — which is why the call site has to resolve rather
        // than compare.
        XCTAssertNil(c.commonBool(\.clipToBounds))
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
                c.typedAttributes(CommonAttributes.self).clipToBounds, legacy: nil, data: [:]
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
        XCTAssertEqual(attrs.tintColor, "#00FF00", "the generic spelling is still there to fall back to")
    }

    /// `highlightBackground` is the UIKit-era spelling of the pressed-state
    /// background; `tapBackground` wins when both are declared.
    func testButtonTapBackgroundWinsOverHighlightBackground() throws {
        let c = try component("""
        { "type": "Button", "text": "x", "tapBackground": "#FF0000", "highlightBackground": "#00FF00" }
        """)
        XCTAssertEqual(c.typedAttributes(ButtonAttributes.self).tapBackground, "#FF0000")
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

    // MARK: - 部分ゴーサイン: the three that needed new machinery

    /// `labelAttributes` styles the closed-state label, and the nested keys
    /// win — the cascade adjudicated for hintAttributes, which rjui, kjui and
    /// selectbox_converter.rb all already implement.
    func testSelectBoxLabelAttributesWinOverComponentKeys() throws {
        let c = try component("""
        { "type": "SelectBox", "items": ["a"], "fontSize": 20, "fontColor": "#0000FF", "font": "Courier",
          "labelAttributes": { "fontSize": 12, "fontColor": "#FF0000", "font": "Helvetica" } }
        """)
        let nested = c.typedAttributes(SelectBoxAttributes.self).labelAttributes

        XCTAssertEqual(nested?["fontSize"] as? Int, 12)
        XCTAssertEqual(nested?["fontColor"] as? String, "#FF0000")
        XCTAssertEqual(nested?["font"] as? String, "Helvetica")
        // …and the component-level ones remain as the per-key fallback.
        XCTAssertEqual(c.typedAttributes(LabelAttributes.self).fontSize?.value.map { CGFloat($0) }, 20)
    }

    /// `trackTintColor` is the unfilled part of the track. SwiftUI exposes no
    /// modifier for it, so it goes through UISlider.appearance() — the route
    /// ToggleConverter already uses for thumbTintColor.
    func testSliderTrackTintColorIsDeclared() throws {
        let c = try component("""
        { "type": "Slider", "value": 0.5, "trackTintColor": "#FF0000" }
        """)
        XCTAssertEqual(c.typedAttributes(SliderAttributes.self).trackTintColor, "#FF0000")
    }

    /// `highlightSrc` was decoded by DynamicComponent all along and read by
    /// nobody.
    func testImageHighlightSrcIsDeclared() throws {
        let c = try component("""
        { "type": "Image", "src": "base", "highlightSrc": "pressed" }
        """)
        XCTAssertEqual(
            c.typedAttributes(ImageAttributes.self).highlightSrc?.rawRepresentation as? String,
            "pressed"
        )
    }

    /// The bound form has to survive too — `highlightSrc` is string|binding.
    func testImageHighlightSrcAcceptsBoundForm() throws {
        let c = try component("""
        { "type": "Image", "src": "base", "highlightSrc": "@{pressedAsset}" }
        """)
        let raw = c.typedAttributes(ImageAttributes.self).highlightSrc?.rawRepresentation as? String
        XCTAssertEqual(raw, "@{pressedAsset}")
        XCTAssertEqual(
            DynamicHelpers.processText(raw, data: ["pressedAsset": "from_data"]),
            "from_data"
        )
    }

    // MARK: - safeAreaInsetPositions (landed with 49-B)

    /// The vocabulary matches base_view_converter.rb SAFE_AREA_EDGES,
    /// including the left/right spellings it accepts beyond the enum.
    func testSafeAreaEdgeSetVocabulary() {
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["top"]), .top)
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["left"]), .leading)
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["right"]), .trailing)
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["vertical"]), .vertical)
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["horizontal"]), .horizontal)
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["all"]), .all)
        XCTAssertEqual(
            DynamicModifierHelper.safeAreaEdgeSet(["top", "bottom"]),
            Edge.Set([.top, .bottom])
        )
    }

    /// `all` anywhere in the list wins; `none` alone selects nothing; an
    /// unrecognised list selects nothing rather than guessing.
    func testSafeAreaEdgeSetDegenerateCases() {
        XCTAssertEqual(DynamicModifierHelper.safeAreaEdgeSet(["top", "all"]), .all)
        XCTAssertNil(DynamicModifierHelper.safeAreaEdgeSet(["none"]))
        XCTAssertNil(DynamicModifierHelper.safeAreaEdgeSet([]))
        XCTAssertNil(DynamicModifierHelper.safeAreaEdgeSet(["sideways"]))
    }

    /// A PLAIN View carries the attribute too — the SSoT says so explicitly,
    /// and codegen applies it to every component.
    func testSafeAreaInsetPositionsIsReadOnAPlainView() throws {
        let c = try component("""
        { "type": "View", "id": "t", "safeAreaInsetPositions": ["top", "bottom"] }
        """)
        let positions = c.typedAttributes(ViewAttributes.self).safeAreaInsetPositions
        XCTAssertEqual(positions?.compactMap { $0 as? String }, ["top", "bottom"])
    }

    /// SafeAreaView accepts `edges` as an alias for the same thing.
    func testSafeAreaViewEdgesAliasResolves() throws {
        let c = try component("""
        { "type": "SafeAreaView", "id": "t", "edges": ["top"] }
        """)
        XCTAssertEqual(
            c.typedAttributes(SafeAreaViewAttributes.self)
                .safeAreaInsetPositions?.compactMap { $0 as? String },
            ["top"]
        )
    }

    // MARK: - bound dimensions and flags the runtime was dropping

    /// min/max are number|binding, and applyFrameConstraints took no `data`
    /// at all — it could not have resolved a binding even in principle.
    func testBoundFrameConstraintsResolve() throws {
        let c = try component("""
        { "type": "View", "id": "t", "minWidth": "@{w}", "minHeight": "@{h}", "maxWidth": "@{mw}" }
        """)
        let common = c.typedAttributes(CommonAttributes.self)
        let data: [String: Any] = ["w": 50, "h": 60, "mw": 150]

        // the hand-decoded `minWidth`/`maxWidth` slots are deleted (plan 50 §4).
        XCTAssertEqual(DynamicHelpers.resolveNumber(common.minWidth, legacy: nil, data: data), 50)
        XCTAssertEqual(DynamicHelpers.resolveNumber(common.minHeight, legacy: nil, data: data), 60)
        XCTAssertEqual(DynamicHelpers.resolveNumber(common.maxWidth, legacy: nil, data: data), 150)
    }

    /// The seven parent-alignment flags are boolean|binding too.
    func testBoundAlignmentFlagsResolve() throws {
        let c = try component("""
        { "type": "View", "id": "t", "alignTop": "@{top}", "centerInParent": "@{mid}" }
        """)
        let common = c.typedAttributes(CommonAttributes.self)

        XCTAssertNil(c.commonBool(\.alignTop))
        XCTAssertEqual(
            DynamicHelpers.resolveBool(common.alignTop, legacy: nil, data: ["top": true]), true
        )
        XCTAssertEqual(
            DynamicHelpers.resolveBool(common.centerInParent, legacy: nil, data: ["mid": false]), false
        )
    }

    /// Routing runs before `data` exists, so a BOUND flag has to count as
    /// declared — otherwise the container never routes to the relative
    /// positioning path and the resolved constraint has nowhere to land.
    /// A literal `false` must still not route, which is what it did before.
    func testBoundAlignmentRoutesToRelativePositioning() throws {
        let bound = try component("""
        { "type": "View", "id": "t", "centerInParent": "@{mid}" }
        """)
        XCTAssertTrue(RelativePositionConverter.needsRelativePositioning(bound))

        let literalTrue = try component("""
        { "type": "View", "id": "t", "centerInParent": true }
        """)
        XCTAssertTrue(RelativePositionConverter.needsRelativePositioning(literalTrue))

        let literalFalse = try component("""
        { "type": "View", "id": "t", "centerInParent": false }
        """)
        XCTAssertFalse(RelativePositionConverter.needsRelativePositioning(literalFalse))

        let undeclared = try component("""
        { "type": "View", "id": "t" }
        """)
        XCTAssertFalse(RelativePositionConverter.needsRelativePositioning(undeclared))
    }

    /// `hidden` is `boolean|binding` too, and `resolveVisibility` compared the
    /// hand-decoded slot with `== true` — nil for `@{expr}`, so a bound
    /// `hidden` resolved to "visible" whatever the data said.
    func testBoundHiddenResolvesThroughVisibility() throws {
        let c = try component("""
        { "type": "View", "id": "t", "hidden": "@{isGone}" }
        """)

        XCTAssertEqual(
            DynamicDecodingHelper.resolveVisibility(component: c, data: ["isGone": true]), "gone"
        )
        XCTAssertEqual(
            DynamicDecodingHelper.resolveVisibility(component: c, data: ["isGone": false]), "visible"
        )

        // The literal form keeps its answer.
        let literal = try component("""
        { "type": "View", "id": "t", "hidden": true }
        """)
        XCTAssertEqual(DynamicDecodingHelper.resolveVisibility(component: literal), "gone")
    }

    /// Conflict detection runs on the same pre-`data` footing as routing: a
    /// bound flag counts as declared, a literal `false` does not. Reading the
    /// slots with `== true` made two bound-but-conflicting children look like
    /// no conflict at all, so the parent laid them out as a plain stack.
    func testBoundAlignmentsCountAsConflicting() throws {
        let boundPair = [
            try component("""
                { "type": "View", "alignTop": "@{a}" }
            """),
            try component("""
                { "type": "View", "alignBottom": "@{b}" }
            """)
        ]
        XCTAssertTrue(
            RelativePositionConverter.childrenHaveConflictingAlignments(
                boundPair, parentOrientation: "vertical"
            )
        )

        // Perpendicular to the orientation is still not a conflict.
        let perpendicular = [
            try component("""
                { "type": "View", "alignLeft": "@{a}" }
            """),
            try component("""
                { "type": "View", "alignRight": "@{b}" }
            """)
        ]
        XCTAssertFalse(
            RelativePositionConverter.childrenHaveConflictingAlignments(
                perpendicular, parentOrientation: "vertical"
            )
        )
    }

    // MARK: - 50 §4 group B: the ten string slots

    /// The ten string slots (`text` `font` `fontColor` `fontFamily` `label`
    /// `src` `tapBackground` `tint` `tintColor` `disabledFontColor`) are gone.
    ///
    /// Unlike the boolean group, these did NOT drop bindings: a `String?`
    /// slot holds `"@{expr}"` verbatim, so the spelling always reached the
    /// converter. The retirement is a read-discipline change, and what has to
    /// be pinned is exactly that: **both forms still come through, byte for
    /// byte, off the generated table.** If they did not, every screen would
    /// change at once.
    func testGroupBSpellingsSurviveTheRetirement() throws {
        let literal = try component("""
        { "type": "Label", "text": "Hi", "font": "Helvetica",
          "fontColor": "#111111", "fontFamily": "Noto Sans JP" }
        """)
        XCTAssertEqual(literal.string(LabelAttributes.self, \.text), "Hi")
        XCTAssertEqual(literal.string(LabelAttributes.self, \.font), "Helvetica")
        XCTAssertEqual(literal.string(LabelAttributes.self, \.fontColor), "#111111")
        XCTAssertEqual(literal.string(LabelAttributes.self, \.fontFamily), "Noto Sans JP")

        let bound = try component("""
        { "type": "Label", "text": "@{title}", "fontColor": "@{titleColor}" }
        """)
        XCTAssertEqual(bound.string(LabelAttributes.self, \.text), "@{title}")
        XCTAssertEqual(bound.string(LabelAttributes.self, \.fontColor), "@{titleColor}")
        XCTAssertEqual(
            DynamicHelpers.processText(
                bound.string(LabelAttributes.self, \.text), data: ["title": "Resolved"]
            ),
            "Resolved"
        )

        // The other six, on the components that declare them.
        let check = try component("""
        { "type": "CheckBox", "label": "Agree", "src": "box" }
        """)
        XCTAssertEqual(check.string(CheckBoxAttributes.self, \.label), "Agree")
        XCTAssertEqual(check.typedAttributes(CheckBoxAttributes.self).src, "box")

        let button = try component("""
        { "type": "Button", "text": "Go", "tapBackground": "@{pressed}",
          "disabledFontColor": "#999999" }
        """)
        let buttonAttrs = button.typedAttributes(ButtonAttributes.self)
        XCTAssertEqual(button.string(ButtonAttributes.self, \.text), "Go")
        XCTAssertEqual(buttonAttrs.tapBackground, "@{pressed}")
        XCTAssertEqual(
            button.string(ButtonAttributes.self, \.disabledFontColor), "#999999"
        )

        let toggle = try component("""
        { "type": "Switch", "tint": "#00FF00", "tintColor": "#0000FF" }
        """)
        XCTAssertEqual(toggle.string(SwitchAttributes.self, \.tint), "#00FF00")
        XCTAssertEqual(toggle.commonString(\.tintColor), "#0000FF")
    }

    /// One thing the retirement DOES widen: the generated extraction reaches
    /// declared aliases, and the hand-decoded slot only ever read the
    /// canonical key. `Segment.fontColor` is the single alias among the ten
    /// (`normalColor`), so it is the whole of the widening — recorded here so
    /// the claim is a measurement rather than an assumption.
    func testGroupBAliasReachIsExactlyOneSpelling() throws {
        let c = try component("""
        { "type": "Segment", "normalColor": "#123456" }
        """)
        XCTAssertEqual(c.typedAttributes(SegmentAttributes.self).fontColor, "#123456")
    }

    /// `tapBackground` split by route: ButtonConverter always resolved it,
    /// the container did not.
    func testBoundTapBackgroundResolves() throws {
        let c = try component("""
        { "type": "View", "id": "t", "tapBackground": "@{pressed}" }
        """)
        XCTAssertEqual(
            DynamicHelpers.getColor(c.commonString(\.tapBackground), data: ["pressed": "#FF0000"]),
            DynamicHelpers.getColor("#FF0000")
        )
        XCTAssertNil(DynamicHelpers.getColor(c.commonString(\.tapBackground)), "without data it cannot resolve")
    }

    // MARK: - bound fontSize and the vocabulary spellings

    /// `fontSize` is number|binding on exactly the components whose SSoT says
    /// so — CheckBox, Label, Radio, TextField, TextView. Button, IconLabel and
    /// SelectBox declare it `number`, and have no bound form to resolve.
    func testBoundFontSizeResolvesWhereDeclared() throws {
        let label = try component("""
        { "type": "Label", "text": "Sample", "fontSize": "@{size}" }
        """)
        // the hand-decoded `fontSize` slot is deleted (plan 50 §4) — it threw on
        // the bound spelling and FailableDecodable turned that into a missing node.
        XCTAssertEqual(
            DynamicHelpers.resolveNumber(
                label.typedAttributes(LabelAttributes.self).fontSize, legacy: nil, data: ["size": 20]
            ),
            20
        )
    }

    /// `CheckBox.spacing` fell to the default 8, which is the control's value
    /// — so the bound face rendered exactly the control and looked "inert".
    func testBoundCheckBoxSpacingResolves() throws {
        let c = try component("""
        { "type": "CheckBox", "text": "x", "spacing": "@{gap}" }
        """)
        XCTAssertNil(c.typedAttributes(ViewAttributes.self).spacing?.value.map { CGFloat($0) })
        XCTAssertEqual(
            DynamicHelpers.resolveNumber(
                c.typedAttributes(CheckBoxAttributes.self).spacing, legacy: nil, data: ["gap": 24]
            ),
            24
        )
    }

    /// `font` and `fontWeight` are looked up in a weight vocabulary. The bound
    /// spelling arrives as the literal "@{expr}", which matches no entry — so
    /// it fell through as "no weight" instead of failing loudly.
    func testBoundWeightSpellingsResolveBeforeVocabularyLookup() throws {
        let cb = try component("""
        { "type": "CheckBox", "text": "x", "font": "@{w}" }
        """)
        let raw = cb.typedAttributes(CheckBoxAttributes.self).font?.rawRepresentation as? String
        XCTAssertEqual(raw, "@{w}")
        XCTAssertEqual(DynamicHelpers.processText(raw, data: ["w": "bold"]), "bold")
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("bold"), .bold)
        // The unresolved spelling matches no entry and falls to the default
        // weight — silently "no weight declared", which is why it looked inert.
        XCTAssertEqual(DynamicHelpers.fontWeightFromString("@{w}"), .regular)
    }

    /// `selectedValue` is declared "binding for two-way"; the converter used
    /// to exclude the bound form outright.
    func testBoundSelectBoxSelectedValueResolves() throws {
        let c = try component("""
        { "type": "SelectBox", "items": ["Alpha", "Beta"], "selectedValue": "@{pick}" }
        """)
        let raw = c.typedAttributes(SelectBoxAttributes.self).selectedValue?.rawRepresentation as? String
        XCTAssertEqual(DynamicHelpers.processText(raw, data: ["pick": "Beta"]), "Beta")
    }

    // MARK: - codegen-parity: Label's hint

    /// Both keys are required. A bare `hint` with no `hintAttributes` is not
    /// a placeholder — the rule label_converter.rb and UIKit's SJUILabel use.
    func testLabelHintNeedsBothKeys() throws {
        let bare = try component("""
        { "type": "Label", "id": "t", "hint": "Conformance Hint" }
        """)
        XCTAssertNil(LabelConverter.labelHint(
            component: bare, attrs: bare.typedAttributes(LabelAttributes.self), data: [:]
        ))

        let both = try component("""
        { "type": "Label", "id": "t", "hint": "Conformance Hint",
          "hintAttributes": { "fontSize": 12 } }
        """)
        let hint = LabelConverter.labelHint(
            component: both, attrs: both.typedAttributes(LabelAttributes.self), data: [:]
        )
        XCTAssertEqual(hint?.text, "Conformance Hint")
        XCTAssertEqual(hint?.size, 12)
    }

    /// `placeholder` is the declared alias of `hint`.
    func testLabelPlaceholderIsTheHintAlias() throws {
        let c = try component("""
        { "type": "Label", "id": "t", "placeholder": "Conformance Hint",
          "hintAttributes": { "fontSize": 12 } }
        """)
        XCTAssertEqual(
            LabelConverter.labelHint(
                component: c, attrs: c.typedAttributes(LabelAttributes.self), data: [:]
            )?.text,
            "Conformance Hint"
        )
    }

    /// The nested colour wins over the flat spelling — the same cascade
    /// adjudicated for TextField's hintAttributes.
    func testLabelHintNestedColourWinsOverFlat() throws {
        let c = try component("""
        { "type": "Label", "id": "t", "hint": "x", "hintColor": "#0000FF",
          "hintAttributes": { "fontSize": 12, "fontColor": "#FF0000" } }
        """)
        XCTAssertEqual(
            LabelConverter.labelHint(
                component: c, attrs: c.typedAttributes(LabelAttributes.self), data: [:]
            )?.color,
            DynamicHelpers.getColor("#FF0000")
        )
    }

    /// The flat `hintColor` accepts the bound form.
    func testLabelHintColorResolvesBinding() throws {
        let c = try component("""
        { "type": "Label", "id": "t", "hint": "x", "hintColor": "@{tint}",
          "hintAttributes": { "fontSize": 12 } }
        """)
        XCTAssertEqual(
            LabelConverter.labelHint(
                component: c, attrs: c.typedAttributes(LabelAttributes.self), data: ["tint": "#00FF00"]
            )?.color,
            DynamicHelpers.getColor("#00FF00")
        )
    }

    // MARK: - codegen-parity: Label's bound line metrics

    /// All five read hand-decoded slots that are nil for `@{expr}`.
    func testBoundLabelLineMetricsResolve() throws {
        let c = try component("""
        { "type": "Label", "id": "t", "text": "x", "lines": "@{n}",
          "lineSpacing": "@{gap}", "minimumScaleFactor": "@{f}", "linkable": "@{on}" }
        """)
        let attrs = c.typedAttributes(LabelAttributes.self)
        let data: [String: Any] = ["n": 3, "gap": 8, "f": 0.5, "on": true]

        XCTAssertNil(c.int(LabelAttributes.self, \.lines), "the hand-decoded slot is what used to drop it")
        XCTAssertEqual(DynamicHelpers.resolveNumber(attrs.lines, legacy: nil, data: data), 3)
        XCTAssertEqual(DynamicHelpers.resolveNumber(attrs.lineSpacing, legacy: nil, data: data), 8)
        XCTAssertEqual(DynamicHelpers.resolveNumber(attrs.minimumScaleFactor, legacy: nil, data: data), 0.5)
        XCTAssertEqual(DynamicHelpers.resolveBool(attrs.linkable, legacy: nil, data: data), true)
    }

    /// `lineSpacing = (lineHeightMultiple - 1) * fontSize`, and BOTH operands
    /// can be bound. A bound fontSize used to fall back to 17 and skew the
    /// arithmetic even when the multiple was a literal.
    func testBoundLineHeightMultipleUsesTheResolvedFontSize() throws {
        let c = try component("""
        { "type": "Label", "id": "t", "text": "x",
          "lineHeightMultiple": "@{m}", "fontSize": "@{size}" }
        """)
        let attrs = c.typedAttributes(LabelAttributes.self)
        let data: [String: Any] = ["m": 2.0, "size": 20]

        let multiple = DynamicHelpers.resolveNumber(attrs.lineHeightMultiple, legacy: nil, data: data)
        let size = DynamicHelpers.resolveNumber(attrs.fontSize, legacy: nil, data: data)
        XCTAssertEqual(multiple, 2.0)
        XCTAssertEqual(size, 20)
        // (2 - 1) * 20 = 20, not (2 - 1) * 17.
        XCTAssertEqual((multiple! - 1) * (size ?? 17), 20)
    }

    // MARK: - codegen-parity: Radio's label, Image's fallback chain

    /// `label` is the Radio-specific spelling and wins over `text` — the same
    /// order CheckBox uses. Nothing read it, so a Radio carrying only a label
    /// rendered no text.
    func testRadioLabelWinsOverText() throws {
        let c = try component("""
        { "type": "Radio", "id": "t", "label": "sample", "text": "generic" }
        """)
        XCTAssertEqual(
            c.typedAttributes(RadioAttributes.self).label?.rawRepresentation as? String,
            "sample"
        )
    }

    /// …and the bound form interpolates rather than printing itself.
    func testRadioLabelResolvesBinding() throws {
        let c = try component("""
        { "type": "Radio", "id": "t", "label": "@{boundLabel}" }
        """)
        let raw = c.typedAttributes(RadioAttributes.self).label?.rawRepresentation as? String
        XCTAssertEqual(DynamicHelpers.processText(raw, data: ["boundLabel": "sample"]), "sample")
    }

    /// A static Image never loads over the network, so errorImage and
    /// loadingImage cannot mean in-flight states — they join the fallback
    /// chain behind defaultImage instead of leaving the photo glyph.
    func testImageFallsBackThroughErrorAndLoadingImage() throws {
        let error = try component("""
        { "type": "Image", "id": "t", "errorImage": "conformance_sample" }
        """)
        XCTAssertNil(error.string(ImageAttributes.self, \.src))
        XCTAssertNil(error.defaultImage)
        XCTAssertEqual(error.errorImage, "conformance_sample")

        let loading = try component("""
        { "type": "Image", "id": "t", "loadingImage": "conformance_sample" }
        """)
        XCTAssertEqual(loading.loadingImage, "conformance_sample")

        // defaultImage stays ahead of both.
        let all = try component("""
        { "type": "Image", "id": "t", "defaultImage": "d",
          "errorImage": "e", "loadingImage": "l" }
        """)
        XCTAssertEqual(all.defaultImage ?? all.errorImage ?? all.loadingImage, "d")
    }

    // MARK: - codegen-parity: the anchor's own position

    /// A child that declares no positioning still has to honour its margins.
    /// The container's default corner does not add them — only an explicit
    /// parent constraint does — so a constraint-less sibling sat at the very
    /// corner and everything anchored to it inherited the error.
    func testConstraintlessChildGetsParentTopLeft() throws {
        let c = try component("""
        { "type": "View", "id": "anchor", "width": 50, "height": 50,
          "topMargin": 60, "leftMargin": 60 }
        """)
        let config = RelativePositionConverter.convert(
            component: c, index: 0, viewBuilder: { _ in AnyView(EmptyView()) }, data: [:]
        )
        XCTAssertEqual(config.constraints.count, 2)
        XCTAssertTrue(config.constraints.contains { $0.type == .parentTop })
        XCTAssertTrue(config.constraints.contains { $0.type == .parentLeft })
        XCTAssertEqual(config.margins.top, 60)
        XCTAssertEqual(config.margins.leading, 60)
    }

    /// A child that DOES declare positioning keeps exactly what it declared —
    /// the synthesis must not stack on top of a real constraint.
    func testDeclaredConstraintIsNotSupplemented() throws {
        let c = try component("""
        { "type": "View", "id": "t", "width": 40, "height": 40, "alignRightOfView": "anchor" }
        """)
        let config = RelativePositionConverter.convert(
            component: c, index: 0, viewBuilder: { _ in AnyView(EmptyView()) }, data: [:]
        )
        XCTAssertEqual(config.constraints.count, 1)
        XCTAssertEqual(config.constraints.first?.type, .rightOf)
        XCTAssertEqual(config.constraints.first?.targetId, "anchor")
    }

    // MARK: - codegen-parity: Progress size vs shape, TabView labels

    /// The declared vocabulary is medium/large — a SIZE. Reading it as the
    /// shape sent both declared values to CircularProgressViewStyle, so the
    /// attribute emitted one constant whatever the layout wrote.
    func testProgressIndicatorStyleIsASizeVocabulary() throws {
        for value in ["medium", "large"] {
            let c = try component("""
            { "type": "Progress", "id": "t", "progress": 0.5, "indicatorStyle": "\(value)" }
            """)
            XCTAssertEqual(c.indicatorStyle, value)
        }
    }

    /// `style` is the separate spelling that carries linear/circular, and it
    /// stays on the shape reading.
    func testProgressStyleStillCarriesTheShape() throws {
        let c = try component("""
        { "type": "Progress", "id": "t", "progress": 0.5, "style": "linear" }
        """)
        XCTAssertEqual(c.rawAttribute("style") as? String, "linear")
        XCTAssertNil(c.indicatorStyle, "the size vocabulary is a different attribute")
    }

    /// `showLabels: false` leaves the icon and drops the text.
    func testTabViewShowLabelsIsRead() throws {
        let off = try component("""
        { "type": "TabView", "id": "t", "showLabels": false }
        """)
        XCTAssertEqual(off.typedAttributes(TabViewAttributes.self).showLabels, false)

        // Undeclared defaults to showing them.
        let undeclared = try component("""
        { "type": "TabView", "id": "t" }
        """)
        XCTAssertNil(undeclared.typedAttributes(TabViewAttributes.self).showLabels)
    }

    /// `hasMatchParentCrossAxis` is about the CONTAINER's cross axis, not its
    /// children's. view_converter.rb sets it from the container's own height;
    /// reading the children answered a different question, so a matchParent
    /// stack holding fixed-height children came out false.
    func testWeightedStackCrossAxisReadsTheContainer() throws {
        let container = try component("""
        { "type": "View", "id": "root", "width": "matchParent", "height": "matchParent",
          "orientation": "horizontal",
          "child": [{ "type": "View", "id": "t", "width": 200, "height": 200, "weight": 1 }] }
        """)
        XCTAssertEqual(container.heightRaw, "matchParent")

        let child = container.childComponents?.first
        XCTAssertEqual(child?.height, 200, "the child is fixed — reading it would give false")
    }

    // MARK: - Collection.scrollTo (the withdrawn Combine transport)

    /// `cellIdProperty` decides which spelling the layout sends: a String cell
    /// id when it is declared, an Int index when it is not.
    func testScrollToSpellingFollowsCellIdProperty() throws {
        let withCellId = try component("""
        { "type": "Collection", "id": "t", "cellIdProperty": "rowId", "scrollTo": "@{target}" }
        """)
        XCTAssertEqual(withCellId.typedAttributes(CollectionAttributes.self).cellIdProperty, "rowId")

        let withoutCellId = try component("""
        { "type": "Collection", "id": "t", "scrollTo": "@{target}" }
        """)
        XCTAssertNil(withoutCellId.typedAttributes(CollectionAttributes.self).cellIdProperty)
    }

    /// The declaration is a plain value — no PassthroughSubject required.
    func testScrollToIsAPlainValue() throws {
        let c = try component("""
        { "type": "Collection", "id": "t", "scrollTo": "@{target}" }
        """)
        let raw = c.typedAttributes(CollectionAttributes.self).scrollTo?.rawRepresentation as? String
        XCTAssertEqual(raw, "@{target}")
        XCTAssertEqual(DynamicBindingResolver.inner(of: raw ?? ""), "target")
        // A plain Int in the data dictionary is enough to address a row.
        XCTAssertEqual(
            DynamicBindingResolver.lookupRaw(path: "target", in: ["target": 7]) as? Int, 7
        )
    }

    /// Equatable, because `.onChange(of:)` fires on a CHANGE — re-sending the
    /// same value must not re-scroll. That is publisher behaviour the plain
    /// value deliberately gave up.
    func testScrollTargetEqualityIsWhatSuppressesARepeatScroll() {
        XCTAssertEqual(CollectionScrollTarget.index(3), .index(3))
        XCTAssertNotEqual(CollectionScrollTarget.index(3), .index(4))
        XCTAssertEqual(CollectionScrollTarget.cellId("a"), .cellId("a"))
        XCTAssertNotEqual(CollectionScrollTarget.cellId("a"), .cellId("b"))
        // The two spellings are distinct even when they look alike.
        XCTAssertNotEqual(CollectionScrollTarget.cellId("3"), .index(3))
    }

    // MARK: - the spacer gating is asymmetric on purpose

    /// The gravity extractors DEFAULT to left/top, so an undeclared gravity
    /// reads as "left" and the trailing-spacer condition is true for every
    /// plain horizontal stack. Only the size gate keeps that from firing
    /// everywhere — which is why view_converter.rb gates the trailing spacer
    /// and not the leading one, and why removing all three put
    /// paddingRight/paddingEnd/rightPadding inert.
    func testTrailingSpacerNeedsAnExpandingContainer() throws {
        let wrapContent = try component("""
        { "type": "View", "id": "t", "width": "wrapContent", "height": 200,
          "orientation": "horizontal", "paddingRight": 8 }
        """)
        XCTAssertEqual(wrapContent.widthRaw, "wrapContent")
        XCTAssertNil(wrapContent.gravity, "no gravity — yet the extractor answers \"left\"")

        let matchParent = try component("""
        { "type": "View", "id": "t", "width": "matchParent", "height": 200,
          "orientation": "horizontal" }
        """)
        XCTAssertEqual(matchParent.widthRaw, "matchParent")
    }

    // MARK: - contentMode: the spelling that is an ABSENCE

    /// All fifteen declared spellings, including the aliases. `fill` and
    /// `scaleToFill` are the STRETCH — resizable with no aspectRatio — which
    /// is why the intent has to be a value rather than a ternary.
    func testContentModeVocabularyCoversEveryDeclaredSpelling() {
        let expected: [String: ImageContentModeIntent] = [
            "fill": .stretch, "ScaleToFill": .stretch, "scaleToFill": .stretch,
            "fit": .fit, "AspectFit": .fit,
            "AspectFill": .aspectFill,
            "top": .positional(.top), "Top": .positional(.top),
            "bottom": .positional(.bottom), "Bottom": .positional(.bottom),
            "left": .positional(.leading), "Left": .positional(.leading),
            "right": .positional(.trailing), "Right": .positional(.trailing),
            "center": .positional(.center), "Center": .positional(.center),
        ]
        for (spelling, intent) in expected {
            XCTAssertEqual(
                ImageContentModeIntent.from(spelling), intent,
                "contentMode '\(spelling)' resolved to the wrong intent"
            )
        }
    }

    /// Anything unrecognised falls back to `.fit`, which is what both render
    /// paths already did — the seam must not change that.
    func testUnknownContentModeFallsBackToFit() {
        XCTAssertEqual(ImageContentModeIntent.from("sideways"), .fit)
        XCTAssertEqual(ImageContentModeIntent.from(nil), .fit)
        // An unresolved binding is exactly this case: it matched nothing
        // before, and it still does — but now it CAN be resolved first.
        XCTAssertEqual(ImageContentModeIntent.from("@{mode}"), .fit)
    }

    /// The bound spelling resolves through the data dictionary, so every
    /// intent including `.stretch` is reachable at runtime.
    func testBoundContentModeReachesTheStretch() throws {
        let c = try component("""
        { "type": "Image", "id": "t", "src": "x", "contentMode": "@{mode}" }
        """)
        let raw = c.typedAttributes(ImageAttributes.self)
            .contentMode?.rawRepresentation as? String
        XCTAssertEqual(raw, "@{mode}")
        XCTAssertEqual(
            ImageContentModeIntent.from(DynamicHelpers.processText(raw, data: ["mode": "fill"])),
            .stretch
        )
        XCTAssertEqual(
            ImageContentModeIntent.from(DynamicHelpers.processText(raw, data: ["mode": "AspectFill"])),
            .aspectFill
        )
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
