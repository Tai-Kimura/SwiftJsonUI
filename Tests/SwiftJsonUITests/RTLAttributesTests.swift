//
//  RTLAttributesTests.swift
//  SwiftJsonUITests
//
//  Tests for RTL-aware attributes (paddingStart, paddingEnd, startMargin, endMargin)
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class RTLAttributesTests: XCTestCase {

    // MARK: - DynamicComponent Decoding Tests

    func testDecodePaddingStartEnd() throws {
        let json = """
        {
            "type": "View",
            "paddingStart": 16,
            "paddingEnd": 24
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "View")
        XCTAssertEqual(component.paddingStart, 16)
        XCTAssertEqual(component.paddingEnd, 24)
    }

    func testDecodeStartEndMargin() throws {
        let json = """
        {
            "type": "Label",
            "text": "Test",
            "startMargin": 12,
            "endMargin": 18
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.type, "Label")
        XCTAssertEqual(component.startMargin, 12)
        XCTAssertEqual(component.endMargin, 18)
    }

    func testDecodeAllRTLAttributes() throws {
        let json = """
        {
            "type": "Button",
            "text": "RTL Button",
            "paddingStart": 8,
            "paddingEnd": 12,
            "paddingTop": 4,
            "paddingBottom": 4,
            "startMargin": 16,
            "endMargin": 20,
            "topMargin": 8,
            "bottomMargin": 8
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.paddingStart, 8)
        XCTAssertEqual(component.paddingEnd, 12)
        XCTAssertEqual(component.paddingTop, 4)
        XCTAssertEqual(component.paddingBottom, 4)
        XCTAssertEqual(component.startMargin, 16)
        XCTAssertEqual(component.endMargin, 20)
        XCTAssertEqual(component.topMargin, 8)
        XCTAssertEqual(component.bottomMargin, 8)
    }

    // MARK: - DynamicHelpers getPadding Tests

    func testGetPaddingWithStartEnd() throws {
        let json = """
        {
            "type": "View",
            "paddingStart": 16,
            "paddingEnd": 24
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let padding = DynamicHelpers.getPadding(from: component)

        XCTAssertEqual(padding.leading, 16, "paddingStart should map to leading")
        XCTAssertEqual(padding.trailing, 24, "paddingEnd should map to trailing")
        XCTAssertEqual(padding.top, 0)
        XCTAssertEqual(padding.bottom, 0)
    }

    func testGetPaddingRTLPrecedenceOverLeftRight() throws {
        // RTL attributes should take precedence over left/right
        let json = """
        {
            "type": "View",
            "paddingLeft": 10,
            "paddingRight": 20,
            "paddingStart": 30,
            "paddingEnd": 40
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let padding = DynamicHelpers.getPadding(from: component)

        XCTAssertEqual(padding.leading, 30, "paddingStart should take precedence over paddingLeft")
        XCTAssertEqual(padding.trailing, 40, "paddingEnd should take precedence over paddingRight")
    }

    func testGetPaddingFallbackToLeftRight() throws {
        // When RTL attributes are not present, fall back to left/right
        let json = """
        {
            "type": "View",
            "paddingLeft": 15,
            "paddingRight": 25
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let padding = DynamicHelpers.getPadding(from: component)

        XCTAssertEqual(padding.leading, 15, "Should fall back to paddingLeft")
        XCTAssertEqual(padding.trailing, 25, "Should fall back to paddingRight")
    }

    func testGetPaddingAllDirections() throws {
        let json = """
        {
            "type": "View",
            "paddingTop": 5,
            "paddingBottom": 10,
            "paddingStart": 15,
            "paddingEnd": 20
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let padding = DynamicHelpers.getPadding(from: component)

        XCTAssertEqual(padding.top, 5)
        XCTAssertEqual(padding.bottom, 10)
        XCTAssertEqual(padding.leading, 15)
        XCTAssertEqual(padding.trailing, 20)
    }

    // MARK: - DynamicHelpers getMargins Tests

    func testGetMarginsWithStartEnd() throws {
        let json = """
        {
            "type": "Label",
            "text": "Test",
            "startMargin": 12,
            "endMargin": 18
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let margins = DynamicHelpers.getMargins(from: component)

        XCTAssertEqual(margins.leading, 12, "startMargin should map to leading")
        XCTAssertEqual(margins.trailing, 18, "endMargin should map to trailing")
        XCTAssertEqual(margins.top, 0)
        XCTAssertEqual(margins.bottom, 0)
    }

    func testGetMarginsRTLPrecedenceOverLeftRight() throws {
        // RTL attributes should take precedence over left/right
        let json = """
        {
            "type": "View",
            "leftMargin": 8,
            "rightMargin": 16,
            "startMargin": 24,
            "endMargin": 32
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let margins = DynamicHelpers.getMargins(from: component)

        XCTAssertEqual(margins.leading, 24, "startMargin should take precedence over leftMargin")
        XCTAssertEqual(margins.trailing, 32, "endMargin should take precedence over rightMargin")
    }

    func testGetMarginsFallbackToLeftRight() throws {
        // When RTL attributes are not present, fall back to left/right
        let json = """
        {
            "type": "View",
            "leftMargin": 10,
            "rightMargin": 20
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let margins = DynamicHelpers.getMargins(from: component)

        XCTAssertEqual(margins.leading, 10, "Should fall back to leftMargin")
        XCTAssertEqual(margins.trailing, 20, "Should fall back to rightMargin")
    }

    func testGetMarginsAllDirections() throws {
        let json = """
        {
            "type": "View",
            "topMargin": 4,
            "bottomMargin": 8,
            "startMargin": 12,
            "endMargin": 16
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let margins = DynamicHelpers.getMargins(from: component)

        XCTAssertEqual(margins.top, 4)
        XCTAssertEqual(margins.bottom, 8)
        XCTAssertEqual(margins.leading, 12)
        XCTAssertEqual(margins.trailing, 16)
    }

    func testGetMarginsFromArray() throws {
        // When margins array is provided, individual RTL attributes should still work
        let json = """
        {
            "type": "View",
            "margins": [8, 12, 8, 12]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let margins = DynamicHelpers.getMargins(from: component)

        // margins array format: [top, trailing, bottom, leading] (CSS order)
        XCTAssertEqual(margins.top, 8)
        XCTAssertEqual(margins.trailing, 12)
        XCTAssertEqual(margins.bottom, 8)
        XCTAssertEqual(margins.leading, 12)
    }

    // MARK: - Integration Tests

    func testRTLAttributesInComplexLayout() throws {
        let json = """
        {
            "type": "View",
            "orientation": "vertical",
            "paddingStart": 20,
            "paddingEnd": 20,
            "child": [
                {
                    "type": "Label",
                    "text": "Title",
                    "startMargin": 0,
                    "endMargin": 0,
                    "paddingStart": 8,
                    "paddingEnd": 8
                },
                {
                    "type": "Button",
                    "text": "Action",
                    "startMargin": 16,
                    "endMargin": 16
                }
            ]
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        // Test parent
        XCTAssertEqual(component.paddingStart, 20)
        XCTAssertEqual(component.paddingEnd, 20)

        // Test children
        XCTAssertEqual(component.child?.count, 2)

        let label = component.child?[0]
        XCTAssertEqual(label?.type, "Label")
        XCTAssertEqual(label?.startMargin, 0)
        XCTAssertEqual(label?.endMargin, 0)
        XCTAssertEqual(label?.paddingStart, 8)
        XCTAssertEqual(label?.paddingEnd, 8)

        let button = component.child?[1]
        XCTAssertEqual(button?.type, "Button")
        XCTAssertEqual(button?.startMargin, 16)
        XCTAssertEqual(button?.endMargin, 16)
    }

    func testZeroPaddingAndMargin() throws {
        // Test that zero values are properly handled
        let json = """
        {
            "type": "View",
            "paddingStart": 0,
            "paddingEnd": 0,
            "startMargin": 0,
            "endMargin": 0
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)

        XCTAssertEqual(component.paddingStart, 0)
        XCTAssertEqual(component.paddingEnd, 0)
        XCTAssertEqual(component.startMargin, 0)
        XCTAssertEqual(component.endMargin, 0)

        let padding = DynamicHelpers.getPadding(from: component)
        XCTAssertEqual(padding.leading, 0)
        XCTAssertEqual(padding.trailing, 0)

        let margins = DynamicHelpers.getMargins(from: component)
        XCTAssertEqual(margins.leading, 0)
        XCTAssertEqual(margins.trailing, 0)
    }

    func testMixedPaddingFormats() throws {
        // Test that paddings array doesn't interfere with individual RTL properties
        let json = """
        {
            "type": "View",
            "paddings": [10],
            "paddingStart": 20,
            "paddingEnd": 30
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(DynamicComponent.self, from: json)
        let padding = DynamicHelpers.getPadding(from: component)

        // When paddings array is present, it takes precedence for the base values
        // But individual properties should still be available in the component
        XCTAssertEqual(component.paddingStart, 20)
        XCTAssertEqual(component.paddingEnd, 30)
    }
}
#endif
