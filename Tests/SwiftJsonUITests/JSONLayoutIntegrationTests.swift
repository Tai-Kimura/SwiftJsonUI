//
//  JSONLayoutIntegrationTests.swift
//  SwiftJsonUITests
//
//  Integration tests for JSON layout parsing
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class JSONLayoutIntegrationTests: XCTestCase {

    // MARK: - Simple Label Layout Tests

    func testParseSimpleLabelLayout() throws {
        let json = """
        {
            "type": "Label",
            "id": "titleLabel",
            "text": "Hello World",
            "fontSize": 18,
            "fontColor": "#333333",
            "font": "Helvetica",
            "fontWeight": "bold",
            "textAlign": "center"
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "Label")
        XCTAssertEqual(component.id, "titleLabel")
        XCTAssertEqual(component.text, "Hello World")
        XCTAssertEqual(component.fontSize, 18)
        XCTAssertEqual(component.fontColor, "#333333")
        XCTAssertEqual(component.font, "Helvetica")
        XCTAssertEqual(component.fontWeight, "bold")
        XCTAssertEqual(component.textAlign, "center")
    }

    // MARK: - Nested View Layout Tests

    func testParseNestedViewLayout() throws {
        let json = """
        {
            "type": "View",
            "id": "container",
            "width": "matchParent",
            "height": "wrapContent",
            "background": "#FFFFFF",
            "paddings": [16, 16, 16, 16],
            "child": [
                {
                    "type": "Label",
                    "id": "header",
                    "text": "Header",
                    "fontSize": 24,
                    "fontColor": "#000000"
                },
                {
                    "type": "Button",
                    "id": "actionButton",
                    "text": "Click Me",
                    "onClick": "handleButtonClick"
                }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "View")
        XCTAssertEqual(component.id, "container")
        XCTAssertEqual(component.width, .infinity)
        XCTAssertNil(component.height) // wrapContent
        XCTAssertEqual(component.background, "#FFFFFF")

        // Check children
        XCTAssertEqual(component.child?.count, 2)

        let header = component.child?[0]
        XCTAssertEqual(header?.type, "Label")
        XCTAssertEqual(header?.id, "header")
        XCTAssertEqual(header?.text, "Header")

        let button = component.child?[1]
        XCTAssertEqual(button?.type, "Button")
        XCTAssertEqual(button?.id, "actionButton")
        XCTAssertEqual(button?.onClick, "handleButtonClick")
    }

    // MARK: - Form Layout Tests

    func testParseFormLayout() throws {
        let json = """
        {
            "type": "View",
            "child": [
                {
                    "type": "TextField",
                    "id": "nameField",
                    "hint": "Enter your name",
                    "hintColor": "#999999",
                    "borderStyle": "roundedRect",
                    "returnKeyType": "next"
                },
                {
                    "type": "TextField",
                    "id": "passwordField",
                    "hint": "Enter password",
                    "secure": true
                },
                {
                    "type": "SelectBox",
                    "id": "countrySelect",
                    "prompt": "Select Country",
                    "items": ["Japan", "USA", "UK"]
                },
                {
                    "type": "Switch",
                    "id": "agreeSwitch",
                    "isOn": false
                }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.child?.count, 4)

        // TextField
        let nameField = component.child?[0]
        XCTAssertEqual(nameField?.type, "TextField")
        XCTAssertEqual(nameField?.hint, "Enter your name")
        XCTAssertEqual(nameField?.hintColor, "#999999")
        XCTAssertEqual(nameField?.borderStyle, "roundedRect")

        // Secure TextField
        let passwordField = component.child?[1]
        XCTAssertEqual(passwordField?.secure, true)

        // SelectBox
        let selectBox = component.child?[2]
        XCTAssertEqual(selectBox?.type, "SelectBox")
        XCTAssertEqual(selectBox?.prompt, "Select Country")
        XCTAssertEqual(selectBox?.items?.count, 3)

        // Switch
        let switchComponent = component.child?[3]
        XCTAssertEqual(switchComponent?.type, "Switch")
        XCTAssertEqual(switchComponent?.isOn, false)
    }

    // MARK: - Relative Positioning Tests

    func testParseRelativeLayout() throws {
        let json = """
        {
            "type": "View",
            "id": "relativeContainer",
            "width": "matchParent",
            "height": 200,
            "child": [
                {
                    "type": "Label",
                    "id": "topLeftLabel",
                    "text": "Top Left",
                    "alignTop": true,
                    "alignLeft": true
                },
                {
                    "type": "Label",
                    "id": "centerLabel",
                    "text": "Center",
                    "centerHorizontal": true,
                    "centerVertical": true
                },
                {
                    "type": "View",
                    "id": "belowCenter",
                    "alignBottomOfView": "centerLabel"
                }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.height, 200)

        let topLeft = component.child?[0]
        XCTAssertEqual(topLeft?.alignTop, true)
        XCTAssertEqual(topLeft?.alignLeft, true)

        let center = component.child?[1]
        XCTAssertEqual(center?.centerHorizontal, true)
        XCTAssertEqual(center?.centerVertical, true)

        let below = component.child?[2]
        XCTAssertEqual(below?.alignBottomOfView, "centerLabel")
    }

    // MARK: - Include Component Tests

    func testParseIncludeComponent() throws {
        let json = """
        {
            "type": "View",
            "child": [
                {
                    "include": "common_header",
                    "variables": {
                        "title": "Main Page",
                        "showBackButton": true
                    }
                },
                {
                    "type": "Label",
                    "text": "Content"
                },
                {
                    "include": "common_footer",
                    "data": {
                        "copyright": "2024"
                    },
                    "shared_data": {
                        "theme": "light"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.child?.count, 3)

        // Include with variables
        let header = component.child?[0]
        XCTAssertEqual(header?.include, "common_header")
        XCTAssertNotNil(header?.variables)
        XCTAssertFalse(header?.isValid ?? true) // No type, so not valid

        // Regular component
        let content = component.child?[1]
        XCTAssertEqual(content?.type, "Label")
        XCTAssertTrue(content?.isValid ?? false)

        // Include with data and shared_data
        let footer = component.child?[2]
        XCTAssertEqual(footer?.include, "common_footer")
        XCTAssertNotNil(footer?.includeData)
        XCTAssertNotNil(footer?.sharedData)
    }

    // MARK: - Complex Nested Structure Tests

    func testParseDeepNestedStructure() throws {
        let json = """
        {
            "type": "ScrollView",
            "child": [
                {
                    "type": "View",
                    "orientation": "vertical",
                    "child": [
                        {
                            "type": "View",
                            "orientation": "horizontal",
                            "child": [
                                {
                                    "type": "Image",
                                    "src": "avatar"
                                },
                                {
                                    "type": "View",
                                    "child": [
                                        {
                                            "type": "Label",
                                            "text": "Level 4"
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        // Navigate through the structure
        let scrollContent = component.child?[0]
        XCTAssertEqual(scrollContent?.type, "View")
        XCTAssertEqual(scrollContent?.orientation, "vertical")

        let horizontalView = scrollContent?.child?[0]
        XCTAssertEqual(horizontalView?.orientation, "horizontal")
        XCTAssertEqual(horizontalView?.child?.count, 2)

        let image = horizontalView?.child?[0]
        XCTAssertEqual(image?.type, "Image")
        XCTAssertEqual(image?.src, "avatar")

        let nestedView = horizontalView?.child?[1]
        let deepLabel = nestedView?.child?[0]
        XCTAssertEqual(deepLabel?.type, "Label")
        XCTAssertEqual(deepLabel?.text, "Level 4")
    }

    // MARK: - EdgeInsets Parsing Tests

    func testEdgeInsetsFromPaddingsArray() throws {
        let json = """
        {
            "type": "View",
            "paddings": [10, 20, 30, 40]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        let edgeInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.paddings)
        XCTAssertNotNil(edgeInsets)
        XCTAssertEqual(edgeInsets?.top, 10)
        XCTAssertEqual(edgeInsets?.trailing, 20)
        XCTAssertEqual(edgeInsets?.bottom, 30)
        XCTAssertEqual(edgeInsets?.leading, 40)
    }

    func testEdgeInsetsFromSingleValue() throws {
        let json = """
        {
            "type": "View",
            "paddings": 16
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        let edgeInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.paddings)
        XCTAssertNotNil(edgeInsets)
        XCTAssertEqual(edgeInsets?.top, 16)
        XCTAssertEqual(edgeInsets?.leading, 16)
        XCTAssertEqual(edgeInsets?.bottom, 16)
        XCTAssertEqual(edgeInsets?.trailing, 16)
    }

    func testEdgeInsetsFromTwoValues() throws {
        let json = """
        {
            "type": "View",
            "margins": [10, 20]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        let edgeInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.margins)
        XCTAssertNotNil(edgeInsets)
        XCTAssertEqual(edgeInsets?.top, 10) // Vertical
        XCTAssertEqual(edgeInsets?.bottom, 10)
        XCTAssertEqual(edgeInsets?.leading, 20) // Horizontal
        XCTAssertEqual(edgeInsets?.trailing, 20)
    }
}
#endif
