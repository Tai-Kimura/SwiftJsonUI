//
//  TypedAttributeConverterTests.swift
//  SwiftJsonUITests
//
//  Stage B (renderer SSoT): per-converter parse→apply coverage for the
//  typed-attribute bridge. Each test decodes a representative component
//  (canonical + alias + binding spellings), asserts the generated
//  extraction sees the right values, and smoke-applies the converter.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class TypedAttributeConverterTests: XCTestCase {

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        return try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    private func normalized(_ json: [String: Any]) -> [String: Any] {
        var out = json
        out["$jui"] = ["normalized": "L1", "schemaVersion": 1]
        return out
    }

    // MARK: - Bridge basics

    func testTypedAttributesResolveAliasOnRawLayouts() throws {
        let c = try component(["type": "Slider", "minimumValue": 5, "maximumValue": 50])
        let attrs = c.typedAttributes(SliderAttributes.self)
        XCTAssertEqual(attrs.minimum?.value, 5)
        XCTAssertEqual(attrs.maximum?.value, 50)
    }

    func testTypedAttributesIgnoreAliasOnNormalizedLayouts() throws {
        let c = try component(normalized(["type": "Slider", "minimumValue": 5]))
        XCTAssertTrue(c.isNormalized)
        XCTAssertNil(c.typedAttributes(SliderAttributes.self).minimum)
    }

    func testTypedAttributesPreferCanonicalSpelling() throws {
        let c = try component(["type": "Slider", "minimum": 3, "minValue": 9])
        XCTAssertEqual(c.typedAttributes(SliderAttributes.self).minimum?.value, 3)
    }

    func testBindingValuesSurfaceAsBindingExpressions() throws {
        let c = try component(["type": "Toggle", "isOn": "@{flag}"])
        let attrs = c.typedAttributes(ToggleAttributes.self)
        XCTAssertEqual(attrs.isOn?.bindingExpression, "flag")
        XCTAssertEqual(attrs.isOn?.bindingString, "@{flag}")
        XCTAssertNil(attrs.isOn?.value)
    }

    func testRawAttributePassthroughForUndeclaredKeys() throws {
        let c = try component(["type": "Toggle", "toggleStyle": "button"])
        XCTAssertEqual(c.rawAttribute("toggleStyle") as? String, "button")
        XCTAssertNil(c.rawAttribute("missing"))
    }

    // MARK: - Converter parse→apply smoke (typed path)

    func testToggleConverterAppliesTypedIsOn() throws {
        let c = try component([
            "type": "Toggle", "isOn": true, "label": "On?",
            "labelAttributes": ["fontSize": 20, "fontColor": "#FF0000"]
        ])
        let attrs = c.typedAttributes(ToggleAttributes.self)
        XCTAssertEqual(attrs.isOn?.value, true)
        XCTAssertEqual(attrs.labelAttributes?["fontSize"] as? Int, 20)
        _ = ToggleConverter.convert(component: c, data: [:])
    }

    func testCheckboxConverterHandlerCandidates() throws {
        let c = try component(["type": "CheckBox", "onValueChange": "@{changed}", "enabled": false])
        let attrs = c.typedAttributes(CheckBoxAttributes.self)
        XCTAssertEqual(attrs.onValueChange?.bindingString, "@{changed}")
        XCTAssertEqual(attrs.common.enabled?.value, false)
        _ = CheckboxConverter.convert(component: c, data: [:])
    }

    func testLabelConverterFontBinding() throws {
        let c = try component(["type": "Label", "text": "Hi", "font": "@{fontProp}"])
        XCTAssertEqual(c.typedAttributes(LabelAttributes.self).font?.bindingExpression, "fontProp")
        _ = LabelConverter.convert(component: c, data: ["fontProp": "bold"])
    }

    func testButtonConverterCommonStyle() throws {
        let c = try component(["type": "Button", "text": "Tap", "style": "bordered"])
        XCTAssertEqual(c.typedAttributes(ButtonAttributes.self).common.style, "bordered")
        _ = ButtonConverter.convert(component: c, data: [:])
    }

    func testTextFieldConverterTypedFields() throws {
        let c = try component([
            "type": "TextField", "hint": "Name", "contentType": "emailAddress",
            "textPaddingLeft": 12, "caretAttributes": ["fontColor": "#00FF00"],
            "nextFocus": "field2"
        ])
        let attrs = c.typedAttributes(TextFieldAttributes.self)
        XCTAssertEqual(attrs.contentType?.value, "emailAddress")
        XCTAssertEqual(attrs.textPaddingLeft, 12)
        XCTAssertEqual(attrs.caretAttributes?["fontColor"] as? String, "#00FF00")
        XCTAssertEqual(attrs.nextFocus, "field2")
        _ = TextFieldConverter.convert(component: c, data: [:])
    }

    func testImageConverterOnSrcPassthrough() throws {
        let c = try component(["type": "Image", "src": "photo", "onSrc": "@{loaded}"])
        XCTAssertEqual(c.rawAttribute("onSrc") as? String, "@{loaded}")
        _ = ImageViewConverter.convert(component: c, data: [:])
    }

    func testProgressConverterTypedTints() throws {
        let c = try component([
            "type": "Progress", "progress": "@{value}",
            "progressTintColor": "#112233", "trackTintColor": "#445566"
        ])
        let attrs = c.typedAttributes(ProgressAttributes.self)
        XCTAssertEqual(attrs.progress?.bindingExpression, "value")
        XCTAssertEqual(attrs.progressTintColor?.value, "#112233")
        XCTAssertEqual(attrs.trackTintColor?.value, "#445566")
        _ = ProgressConverter.convert(component: c, data: ["value": 0.4])
    }

    func testWebConverterUrlSpelling() throws {
        let c = try component(["type": "Web", "url": "https://example.com"])
        XCTAssertEqual(c.typedAttributes(WebAttributes.self).url?.rawString, "https://example.com")
        _ = WebConverter.convert(component: c, data: [:])
    }

    func testBlurConverterEffectStyleLenientEnum() throws {
        let c = try component(["type": "Blur", "effectStyle": "dark"])
        let attrs = c.typedAttributes(BlurAttributes.self)
        XCTAssertEqual(attrs.effectStyle?.rawStringValue, "Dark") // ci-matched
        _ = BlurConverter.convert(component: c, data: [:], viewId: nil)
    }

    func testSegmentConverterSelectionBinding() throws {
        let c = try component(["type": "Segment", "items": ["A", "B"], "selectedIndex": "@{seg}"])
        XCTAssertEqual(c.typedAttributes(SegmentAttributes.self).selectedIndex?.bindingExpression, "seg")
        _ = SegmentConverter.convert(component: c, data: [:])
    }

    func testTabViewConverterAliasHandlers() throws {
        // onPageChanged is the Collection/TabView definitions alias of onValueChange
        let c = try component(["type": "TabView", "tabs": [], "onPageChanged": "@{tabbed}"])
        XCTAssertEqual(
            c.typedAttributes(TabViewAttributes.self).onValueChange?.rawRepresentation as? String,
            "@{tabbed}"
        )
    }

    func testCollectionAttributesAliasAndBinding() throws {
        let c = try component([
            "type": "Collection", "items": "@{rows}",
            "cellIdProperty": "id", "onPageChanged": "@{paged}",
            "currentPage": "@{page}"
        ])
        let attrs = c.typedAttributes(CollectionAttributes.self)
        XCTAssertEqual(attrs.items?.bindingExpression, "rows")
        XCTAssertEqual(attrs.cellIdProperty, "id")
        XCTAssertEqual(attrs.onValueChange?.rawRepresentation as? String, "@{paged}")
        XCTAssertEqual(attrs.currentPage?.bindingString, "@{page}")
    }

    func testCollectionColumnsBindingResolution() throws {
        let c = try component([
            "type": "Collection", "items": "@{rows}", "columns": "@{gridColumnCount}"
        ])
        let attrs = c.typedAttributes(CollectionAttributes.self)
        XCTAssertEqual(attrs.columns?.bindingExpression, "gridColumnCount")

        // Literal number
        let literal = CollectionConverter.resolveGlobalColumns(
            .value(2), legacyColumns: nil, data: [:])
        XCTAssertEqual(literal.count, 2)
        XCTAssertFalse(literal.isBinding)

        // Binding resolved from data (Int / Double / SwiftUI.Binding<Int>)
        XCTAssertEqual(CollectionConverter.resolveGlobalColumns(
            attrs.columns, legacyColumns: nil, data: ["gridColumnCount": 3]).count, 3)
        XCTAssertEqual(CollectionConverter.resolveGlobalColumns(
            attrs.columns, legacyColumns: nil, data: ["gridColumnCount": 2.0]).count, 2)
        XCTAssertEqual(CollectionConverter.resolveGlobalColumns(
            attrs.columns, legacyColumns: nil,
            data: ["gridColumnCount": SwiftUI.Binding.constant(4)]).count, 4)
        XCTAssertTrue(CollectionConverter.resolveGlobalColumns(
            attrs.columns, legacyColumns: nil, data: ["gridColumnCount": 3]).isBinding)

        // Unresolved binding falls back to 1 but stays flagged as binding
        // (keeps the Collection on the grid path).
        let unresolved = CollectionConverter.resolveGlobalColumns(
            attrs.columns, legacyColumns: nil, data: [:])
        XCTAssertEqual(unresolved.count, 1)
        XCTAssertTrue(unresolved.isBinding)

        // No typed attribute → legacy decoded Int, clamped to >= 1
        XCTAssertEqual(CollectionConverter.resolveGlobalColumns(
            nil, legacyColumns: 4, data: [:]).count, 4)
        XCTAssertEqual(CollectionConverter.resolveGlobalColumns(
            nil, legacyColumns: nil, data: [:]).count, 1)
        XCTAssertEqual(CollectionConverter.resolveGlobalColumns(
            .value(0), legacyColumns: nil, data: [:]).count, 1)

        // Converter smoke: binding columns must not crash the convert path
        _ = CollectionConverter.convert(component: c, data: ["gridColumnCount": 2])
    }

    func testScrollViewConverterTypedKeyboardAvoidance() throws {
        let c = try component(["type": "ScrollView", "keyboardAvoidance": false, "scrollEnabled": "@{canScroll}"])
        let attrs = c.typedAttributes(ScrollViewAttributes.self)
        XCTAssertEqual(attrs.keyboardAvoidance, false)
        XCTAssertEqual(attrs.scrollEnabled?.bindingExpression, "canScroll")
    }

    func testIndicatorAndRadioAndPickerPassthroughKeys() throws {
        let ind = try component(["type": "Indicator", "animating": false])
        XCTAssertEqual(ind.rawAttribute("animating") as? Bool, false)
        _ = IndicatorConverter.convert(component: ind, data: [:])

        let radio = try component(["type": "Radio", "items": ["a"], "selectedValue": "@{sel}"])
        XCTAssertEqual(radio.rawAttribute("selectedValue") as? String, "@{sel}")

        let picker = try component(["type": "Picker", "items": ["a"], "selectedIndex": "@{idx}"])
        XCTAssertEqual(picker.rawAttribute("selectedIndex") as? String, "@{idx}")
    }

    func testSelectBoxConverterTypedSelection() throws {
        let c = try component(["type": "SelectBox", "items": ["a", "b"], "selectedIndex": "@{sel}"])
        let attrs = c.typedAttributes(SelectBoxAttributes.self)
        XCTAssertEqual(attrs.selectedIndex?.bindingString, "@{sel}")
        XCTAssertEqual(attrs.items?.bindingExpression, nil)
    }

    func testGradientViewObjectShapePassthrough() throws {
        let c = try component([
            "type": "GradientView",
            "gradient": ["colors": ["#000000", "#FFFFFF"], "locations": [0, 1]]
        ])
        let obj = c.rawAttribute("gradient") as? [String: Any]
        XCTAssertEqual((obj?["colors"] as? [String])?.count, 2)
        // the declared array form still comes through typed
        let arr = try component(["type": "GradientView", "gradient": ["#000000", "#FFFFFF"]])
        XCTAssertEqual((arr.typedAttributes(GradientViewAttributes.self).gradient as? [String])?.count, 2)
    }

    func testTableConverterLegacyKeys() throws {
        let c = try component(["type": "Table", "hideSeparator": true])
        XCTAssertEqual(c.rawAttribute("hideSeparator") as? Bool, true)
    }
}

// MARK: - Unapplied-attribute audit

final class JsonUIAttributeAuditTests: XCTestCase {

    override func tearDown() {
        JsonUIAttributeAudit.warningHandler = nil
        JsonUIAttributeAudit.reset()
        super.tearDown()
    }

    private func decode(_ json: [String: Any]) throws -> DynamicComponent {
        return try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    func testAuditFiresForUndeclaredAttribute() throws {
        var messages: [String] = []
        JsonUIAttributeAudit.warningHandler = { messages.append($0) }

        let c = try decode(["type": "Label", "text": "Hi", "fontSice": 20])
        JsonUIAttributeAudit.audit(component: c)

        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages[0].contains("fontSice"))
        XCTAssertTrue(messages[0].contains("Label"))
    }

    func testAuditReportsEachTypeKeyPairOnce() throws {
        var messages: [String] = []
        JsonUIAttributeAudit.warningHandler = { messages.append($0) }

        let c = try decode(["type": "Label", "text": "Hi", "fontSice": 20])
        JsonUIAttributeAudit.audit(component: c)
        JsonUIAttributeAudit.audit(component: c)

        XCTAssertEqual(messages.count, 1)
    }

    func testAuditStaysQuietForDeclaredAliasStructuralAndAllowlistedKeys() throws {
        var messages: [String] = []
        JsonUIAttributeAudit.warningHandler = { messages.append($0) }

        // declared + alias spelling + structural keys
        let slider = try decode([
            "type": "Slider", "id": "s", "minimumValue": 1, "maximum": 5,
            "style": "someStyle", "_meta": true
        ])
        JsonUIAttributeAudit.audit(component: slider)

        // consumed-undeclared allowlist
        let toggle = try decode(["type": "Toggle", "isOn": true, "toggleStyle": "button"])
        JsonUIAttributeAudit.audit(component: toggle)

        // unrouted types are skipped entirely
        let custom = try decode(["type": "MyCustomCard", "someProp": 1])
        JsonUIAttributeAudit.audit(component: custom)

        XCTAssertEqual(messages, [])
    }
}
#endif
