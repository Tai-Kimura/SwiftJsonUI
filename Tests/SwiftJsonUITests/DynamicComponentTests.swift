//
//  DynamicComponentTests.swift
//  SwiftJsonUITests
//
//  Tests for DynamicComponent JSON parsing
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class DynamicComponentTests: XCTestCase {

    // MARK: - Basic Type Parsing Tests

    func testDecodeBasicLabel() throws {
        let json = """
        {
            "type": "Label",
            "text": "Hello World",
            "fontSize": 16,
            "fontColor": "#000000"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "Label")
        XCTAssertEqual(component.text, "Hello World")
        XCTAssertEqual(component.fontSize, 16)
        XCTAssertEqual(component.fontColor, "#000000")
        XCTAssertTrue(component.isValid)
    }

    func testDecodeButton() throws {
        let json = """
        {
            "type": "Button",
            "text": "Click Me",
            "onClick": "handleClick",
            "background": "#FF0000",
            "cornerRadius": 8
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "Button")
        XCTAssertEqual(component.text, "Click Me")
        XCTAssertEqual(component.onClick, "handleClick")
        XCTAssertEqual(component.background, "#FF0000")
        XCTAssertEqual(component.cornerRadius, 8)
    }

    func testDecodeTextField() throws {
        let json = """
        {
            "type": "TextField",
            "hint": "Enter text",
            "hintColor": "#888888",
            "secure": true,
            "returnKeyType": "done"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "TextField")
        XCTAssertEqual(component.hint, "Enter text")
        XCTAssertEqual(component.hintColor, "#888888")
        XCTAssertEqual(component.secure, true)
        XCTAssertEqual(component.returnKeyType, "done")
    }

    func testDecodeImage() throws {
        let json = """
        {
            "type": "Image",
            "src": "icon_home",
            "contentMode": "AspectFit",
            "width": 100,
            "height": 100
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "Image")
        XCTAssertEqual(component.src, "icon_home")
        XCTAssertEqual(component.contentMode, "AspectFit")
        XCTAssertEqual(component.width, 100)
        XCTAssertEqual(component.height, 100)
    }

    // MARK: - Size Value Tests

    func testDecodeSizeMatchParent() throws {
        let json = """
        {
            "type": "View",
            "width": "matchParent",
            "height": "match_parent"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.width, .infinity)
        XCTAssertEqual(component.height, .infinity)
        XCTAssertEqual(component.widthRaw, "matchParent")
        XCTAssertEqual(component.heightRaw, "match_parent")
    }

    func testDecodeSizeWrapContent() throws {
        let json = """
        {
            "type": "View",
            "width": "wrapContent",
            "height": "wrap_content"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNil(component.width)
        XCTAssertNil(component.height)
        XCTAssertEqual(component.widthRaw, "wrapContent")
        XCTAssertEqual(component.heightRaw, "wrap_content")
    }

    func testDecodeSizeNumeric() throws {
        let json = """
        {
            "type": "View",
            "width": 200,
            "height": 150.5
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.width, 200)
        XCTAssertEqual(component.height, 150.5)
    }

    // MARK: - Padding and Margin Tests

    func testDecodePaddings() throws {
        let json = """
        {
            "type": "View",
            "paddings": [10, 20, 30, 40],
            "paddingTop": 5,
            "paddingLeft": 15
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNotNil(component.paddings)
        XCTAssertEqual(component.paddingTop, 5)
        XCTAssertEqual(component.paddingLeft, 15)
    }

    func testDecodeMargins() throws {
        let json = """
        {
            "type": "View",
            "margins": [8],
            "leftMargin": 16,
            "rightMargin": 16
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNotNil(component.margins)
        XCTAssertEqual(component.leftMargin?.value as? Int, 16)
        XCTAssertEqual(component.rightMargin?.value as? Int, 16)
    }

    // MARK: - Child Components Tests

    func testDecodeChildArray() throws {
        let json = """
        {
            "type": "View",
            "child": [
                {"type": "Label", "text": "First"},
                {"type": "Label", "text": "Second"}
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNotNil(component.child)
        XCTAssertEqual(component.child?.count, 2)
        XCTAssertEqual(component.childComponents?.count, 2)
        XCTAssertEqual(component.child?[0].text, "First")
        XCTAssertEqual(component.child?[1].text, "Second")
    }

    func testDecodeChildrenAlias() throws {
        let json = """
        {
            "type": "View",
            "children": [
                {"type": "Button", "text": "OK"}
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNotNil(component.children)
        XCTAssertEqual(component.children?.count, 1)
        XCTAssertEqual(component.childComponents?.count, 1)
    }

    // MARK: - Style Properties Tests

    func testDecodeStyleProperties() throws {
        let json = """
        {
            "type": "View",
            "cornerRadius": 12,
            "borderWidth": 2,
            "borderColor": "#CCCCCC",
            "alpha": 0.8,
            "hidden": false,
            "clipToBounds": true
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.cornerRadius, 12)
        XCTAssertEqual(component.borderWidth, 2)
        XCTAssertEqual(component.borderColor, "#CCCCCC")
        XCTAssertEqual(component.alpha, 0.8)
        XCTAssertEqual(component.hidden, false)
        XCTAssertEqual(component.clipToBounds, true)
    }

    // MARK: - Event Handler Tests

    func testDecodeEventHandlers() throws {
        let json = """
        {
            "type": "Button",
            "onClick": "handleTap",
            "onLongPress": "handleLongPress",
            "onAppear": "onViewAppear",
            "onDisappear": "onViewDisappear"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.onClick, "handleTap")
        XCTAssertEqual(component.onLongPress, "handleLongPress")
        XCTAssertEqual(component.onAppear, "onViewAppear")
        XCTAssertEqual(component.onDisappear, "onViewDisappear")
    }

    func testDecodeOnclickLowercase() throws {
        let json = """
        {
            "type": "Button",
            "onClick": "handleClick"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.onClick, "handleClick")
    }

    // MARK: - Gravity Tests

    func testDecodeGravityArray() throws {
        let json = """
        {
            "type": "View",
            "gravity": ["top", "left"]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.gravity, ["top", "left"])
    }

    func testDecodeGravityPipeSeparated() throws {
        let json = """
        {
            "type": "View",
            "gravity": "top|center"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.gravity, ["top", "center"])
    }

    func testDecodeGravitySingleValue() throws {
        let json = """
        {
            "type": "View",
            "gravity": "center"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.gravity, ["center"])
    }

    // MARK: - Include Support Tests

    func testDecodeIncludeComponent() throws {
        let json = """
        {
            "include": "common_header",
            "variables": {
                "title": "My Title"
            }
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.include, "common_header")
        XCTAssertNotNil(component.variables)
        XCTAssertNil(component.type)
        XCTAssertFalse(component.isValid)
    }

    func testDecodeIncludeWithData() throws {
        let json = """
        {
            "include": "user_card",
            "data": {
                "name": "John",
                "age": 30
            }
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.include, "user_card")
        XCTAssertNotNil(component.includeData)
    }

    // MARK: - Relative Positioning Tests

    func testDecodeRelativePositioning() throws {
        let json = """
        {
            "type": "Label",
            "alignTop": true,
            "alignLeft": true,
            "centerHorizontal": false,
            "alignBottomOfView": "targetView"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.alignTop, true)
        XCTAssertEqual(component.alignLeft, true)
        XCTAssertEqual(component.centerHorizontal, false)
        XCTAssertEqual(component.alignBottomOfView, "targetView")
    }

    // MARK: - ScrollView Properties Tests

    func testDecodeScrollViewProperties() throws {
        let json = """
        {
            "type": "ScrollView",
            "horizontalScroll": true,
            "paging": true,
            "bounces": false,
            "scrollEnabled": true,
            "showsHorizontalScrollIndicator": false,
            "showsVerticalScrollIndicator": true
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.horizontalScroll, true)
        XCTAssertEqual(component.paging, true)
        XCTAssertEqual(component.bounces, false)
        XCTAssertEqual(component.scrollEnabled, true)
        XCTAssertEqual(component.showsHorizontalScrollIndicator, false)
        XCTAssertEqual(component.showsVerticalScrollIndicator, true)
    }

    // MARK: - DatePicker Properties Tests

    func testDecodeDatePickerProperties() throws {
        let json = """
        {
            "type": "SelectBox",
            "selectItemType": "date",
            "datePickerMode": "date",
            "dateStringFormat": "yyyy/MM/dd",
            "minimumDate": "2020/01/01",
            "maximumDate": "2030/12/31",
            "selectedDate": "2024/06/15"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.selectItemType, "date")
        XCTAssertEqual(component.datePickerMode, "date")
        XCTAssertEqual(component.dateStringFormat, "yyyy/MM/dd")
        XCTAssertEqual(component.minimumDate, "2020/01/01")
        XCTAssertEqual(component.maximumDate, "2030/12/31")
        XCTAssertEqual(component.selectedDate, "2024/06/15")
    }

    // MARK: - Collection Properties Tests

    func testDecodeCollectionProperties() throws {
        let json = """
        {
            "type": "Collection",
            "columns": 3,
            "spacing": 8,
            "layout": "grid",
            "items": ["Item1", "Item2", "Item3"]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.columns, 3)
        XCTAssertEqual(component.spacing, 8)
        XCTAssertEqual(component.layout, "grid")
        XCTAssertEqual(component.items, ["Item1", "Item2", "Item3"])
    }

    func testDecodeCollectionColumnsBindingDoesNotThrow() throws {
        // `columns` is declared `["number", "binding"]` in the shared
        // attribute catalog — a `@{binding}` string must decode without
        // failing the whole component (value-or-binding, like width/height).
        let json = """
        {
            "type": "Collection",
            "id": "grid_collection",
            "columns": "@{gridColumnCount}",
            "items": "@{gridItems}"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "Collection")
        // The legacy Int slot stays nil for the binding spelling …
        XCTAssertNil(component.columns)
        // … while the binding survives via rawData / typed attributes.
        XCTAssertEqual(component.rawData["columns"] as? String, "@{gridColumnCount}")
        XCTAssertEqual(
            component.typedAttributes(CollectionAttributes.self).columns?.bindingExpression,
            "gridColumnCount"
        )
    }

    func testCollectionWithBindingColumnsSurvivesAsChild() throws {
        // Regression: a binding `columns` used to throw inside
        // DynamicComponent.init(from:), and the failing Collection node was
        // silently dropped from the parent's children, collapsing the
        // surrounding weighted layout.
        let json = """
        {
            "type": "View",
            "orientation": "vertical",
            "child": [
                { "type": "Label", "text": "header" },
                {
                    "type": "Collection",
                    "id": "grid_collection",
                    "width": "matchParent",
                    "weight": 1,
                    "columns": "@{gridColumnCount}",
                    "items": "@{gridItems}"
                },
                { "type": "Label", "text": "footer" }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let children = try XCTUnwrap(component.childComponents)

        XCTAssertEqual(children.count, 3)
        XCTAssertEqual(children[1].type, "Collection")
        XCTAssertEqual(children[1].id, "grid_collection")
        XCTAssertEqual(children[1].weight, 1)
    }

    // MARK: - Size Constraints Tests

    func testDecodeSizeConstraints() throws {
        let json = """
        {
            "type": "View",
            "minWidth": 100,
            "maxWidth": 300,
            "minHeight": 50,
            "maxHeight": 200,
            "idealWidth": 200,
            "idealHeight": 100
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.minWidth, 100)
        XCTAssertEqual(component.maxWidth, 300)
        XCTAssertEqual(component.minHeight, 50)
        XCTAssertEqual(component.maxHeight, 200)
        XCTAssertEqual(component.idealWidth, 200)
        XCTAssertEqual(component.idealHeight, 100)
    }

    // MARK: - Z-Order Tests

    func testDecodeZOrder() throws {
        let json = """
        {
            "type": "View",
            "id": "overlay",
            "indexAbove": "baseView",
            "indexBelow": "topView"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.id, "overlay")
        XCTAssertEqual(component.indexAbove, "baseView")
        XCTAssertEqual(component.indexBelow, "topView")
    }

    // MARK: - RawData Access Tests

    func testRawDataContainsAllProperties() throws {
        let json = """
        {
            "type": "Label",
            "text": "Test",
            "customProperty": "customValue"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.rawData["type"] as? String, "Label")
        XCTAssertEqual(component.rawData["text"] as? String, "Test")
        XCTAssertEqual(component.rawData["customProperty"] as? String, "customValue")
    }

    // MARK: - Font Properties Tests

    func testDecodeFontProperties() throws {
        let json = """
        {
            "type": "Label",
            "text": "Styled Text",
            "font": "Helvetica",
            "fontWeight": "bold",
            "underline": true,
            "strikethrough": false,
            "lineHeightMultiple": 1.5
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.font, "Helvetica")
        XCTAssertEqual(component.fontWeight, "bold")
        XCTAssertEqual(component.underline, true)
        XCTAssertEqual(component.strikethrough, false)
        XCTAssertEqual(component.lineHeightMultiple, 1.5)
    }

    // MARK: - Image Properties Tests

    func testDecodeNetworkImageProperties() throws {
        let json = """
        {
            "type": "NetworkImage",
            "src": "https://example.com/image.png",
            "defaultImage": "placeholder",
            "errorImage": "error_icon",
            "loadingImage": "loading",
            "headers": {
                "Authorization": "Bearer token"
            }
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.src, "https://example.com/image.png")
        XCTAssertEqual(component.defaultImage, "placeholder")
        XCTAssertEqual(component.errorImage, "error_icon")
        XCTAssertEqual(component.loadingImage, "loading")
        XCTAssertEqual(component.headers?["Authorization"], "Bearer token")
    }

    // MARK: - Binding-capable Common Attribute Tolerance (Part 1)
    //
    // Common attrs declared `["number","binding"]` / `["boolean","binding"]`
    // in the shared catalog must decode a `@{binding}` string WITHOUT throwing
    // (the throw used to drop the node into the error placeholder and never
    // resolve the value). The typed slot becomes nil for the binding spelling;
    // the binding survives via rawData / typedAttributes(CommonAttributes).

    func testCornerRadiusBindingDoesNotThrow() throws {
        let json = """
        {
            "type": "View",
            "id": "card",
            "cornerRadius": "@{cardRadius}"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        // Legacy typed slot stays nil for a binding spelling …
        XCTAssertNil(component.cornerRadius)
        // … but the binding survives raw and via typed CommonAttributes.
        XCTAssertEqual(component.rawData["cornerRadius"] as? String, "@{cardRadius}")
        XCTAssertEqual(
            component.typedAttributes(CommonAttributes.self).cornerRadius?.bindingExpression,
            "cardRadius"
        )
    }

    func testWeightBindingDoesNotThrow() throws {
        let json = """
        {
            "type": "Label",
            "text": "flex",
            "weight": "@{rowWeight}"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNil(component.weight)
        XCTAssertEqual(component.rawData["weight"] as? String, "@{rowWeight}")
    }

    func testPaddingBindingDoesNotThrow() throws {
        let json = """
        {
            "type": "View",
            "paddingTop": "@{topPad}",
            "paddingLeft": "@{leftPad}"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNil(component.paddingTop)
        XCTAssertNil(component.paddingLeft)
        XCTAssertEqual(
            component.typedAttributes(CommonAttributes.self).paddingTop?.bindingExpression,
            "topPad"
        )
    }

    func testCanTapBindingDoesNotThrow() throws {
        let json = """
        {
            "type": "View",
            "canTap": "@{isTappable}"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertNil(component.canTap)
        XCTAssertEqual(
            component.typedAttributes(CommonAttributes.self).canTap?.bindingExpression,
            "isTappable"
        )
    }

    func testBoundBindingChildSurvivesInsteadOfErrorPlaceholder() throws {
        // Regression: a binding on a binding-capable common attr used to throw
        // inside DynamicComponent.init(from:), degrading the child into the
        // decode-error placeholder (or, pre-10.2.1, dropping it entirely).
        let json = """
        {
            "type": "View",
            "orientation": "vertical",
            "child": [
                { "type": "Label", "text": "header" },
                {
                    "type": "View",
                    "id": "styled",
                    "cornerRadius": "@{r}",
                    "borderWidth": "@{bw}",
                    "canTap": "@{tap}",
                    "weight": "@{w}"
                },
                { "type": "Label", "text": "footer" }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let children = try XCTUnwrap(component.childComponents)

        XCTAssertEqual(children.count, 3)
        XCTAssertEqual(children[1].type, "View")
        XCTAssertEqual(children[1].id, "styled")
        XCTAssertNotEqual(children[1].type, DynamicDecodingHelper.decodeErrorType)
    }

    func testLiteralCommonAttrsUnchangedByToleranceChange() throws {
        // The `try?` success path must return the same literal a plain typed
        // decode did — non-binding layouts are byte-identical in behavior.
        let json = """
        {
            "type": "View",
            "cornerRadius": 12,
            "borderWidth": 2,
            "canTap": true,
            "weight": 3,
            "paddingTop": 8,
            "minWidth": 100,
            "aspectWidth": 16,
            "widthWeight": 0.5,
            "alignTop": true,
            "centerInParent": false,
            "lines": 2,
            "spacing": 4
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.cornerRadius, 12)
        XCTAssertEqual(component.borderWidth, 2)
        XCTAssertEqual(component.canTap, true)
        XCTAssertEqual(component.weight, 3)
        XCTAssertEqual(component.paddingTop, 8)
        XCTAssertEqual(component.minWidth, 100)
        XCTAssertEqual(component.aspectWidth, 16)
        XCTAssertEqual(component.widthWeight, 0.5)
        XCTAssertEqual(component.alignTop, true)
        XCTAssertEqual(component.centerInParent, false)
        XCTAssertEqual(component.lines, 2)
        XCTAssertEqual(component.spacing, 4)
    }

    // MARK: - Binding-capable Common Attribute Resolution (Part 2)
    //
    // For attrs with a concrete dynamic render helper, a bound value must
    // actually resolve against `data` (not merely "not crash"). These exercise
    // the DynamicHelpers resolvers the render helpers route through.

    func testResolveNumberResolvesCornerRadiusBindingFromData() throws {
        let json = """
        { "type": "View", "cornerRadius": "@{cardRadius}" }
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        let common = component.typedAttributes(CommonAttributes.self)
        let data: [String: Any] = ["cardRadius": 16.0]

        let resolved = DynamicHelpers.resolveNumber(common.cornerRadius, legacy: component.cornerRadius, data: data)
        XCTAssertEqual(resolved, 16)
    }

    func testResolveNumberResolvesPaddingBindingFromData() throws {
        let json = """
        { "type": "View", "paddingTop": "@{topPad}" }
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        let common = component.typedAttributes(CommonAttributes.self)
        // Int in data (layouts often store Ints) must resolve to CGFloat.
        let data: [String: Any] = ["topPad": 24]

        let resolved = DynamicHelpers.resolveNumber(common.paddingTop, legacy: component.paddingTop, data: data)
        XCTAssertEqual(resolved, 24)
    }

    func testResolveNumberFallsBackToLiteralAndLegacy() throws {
        // Literal: typed slot has the value, no binding.
        let litJson = """
        { "type": "View", "cornerRadius": 10 }
        """.data(using: .utf8)!
        let lit = try JSONDecoder().decode(DynamicComponent.self, from: litJson)
        let litCommon = lit.typedAttributes(CommonAttributes.self)
        XCTAssertEqual(DynamicHelpers.resolveNumber(litCommon.cornerRadius, legacy: lit.cornerRadius, data: [:]), 10)

        // Binding but unresolved (key absent) → legacy (nil here).
        let bindJson = """
        { "type": "View", "cornerRadius": "@{missing}" }
        """.data(using: .utf8)!
        let bind = try JSONDecoder().decode(DynamicComponent.self, from: bindJson)
        let bindCommon = bind.typedAttributes(CommonAttributes.self)
        XCTAssertNil(DynamicHelpers.resolveNumber(bindCommon.cornerRadius, legacy: bind.cornerRadius, data: [:]))
    }

    func testResolveBoolResolvesCanTapBindingFromData() throws {
        let json = """
        { "type": "View", "canTap": "@{isTappable}" }
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        let common = component.typedAttributes(CommonAttributes.self)

        XCTAssertEqual(
            DynamicHelpers.resolveBool(common.canTap, legacy: component.canTap, data: ["isTappable": true]),
            true
        )
        XCTAssertEqual(
            DynamicHelpers.resolveBool(common.canTap, legacy: component.canTap, data: ["isTappable": false]),
            false
        )
    }

    func testResolveWeightResolvesBindingAndLiteral() throws {
        // Binding resolves from data.
        let bindJson = """
        { "type": "Label", "text": "x", "weight": "@{rowWeight}" }
        """.data(using: .utf8)!
        let bind = try JSONDecoder().decode(DynamicComponent.self, from: bindJson)
        XCTAssertEqual(DynamicHelpers.resolveWeight(from: bind, data: ["rowWeight": 2]), 2)
        // Unresolved binding → legacy (nil).
        XCTAssertNil(DynamicHelpers.resolveWeight(from: bind, data: [:]))

        // Literal weight resolves to the same value with no binding.
        let litJson = """
        { "type": "Label", "text": "x", "weight": 5 }
        """.data(using: .utf8)!
        let lit = try JSONDecoder().decode(DynamicComponent.self, from: litJson)
        XCTAssertEqual(DynamicHelpers.resolveWeight(from: lit, data: [:]), 5)
    }
}
#endif
