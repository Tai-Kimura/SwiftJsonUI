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
        XCTAssertEqual(component.leftMargin, 16)
        XCTAssertEqual(component.rightMargin, 16)
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
            "onclick": "handleClick"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.onclick, "handleClick")
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
}
#endif
