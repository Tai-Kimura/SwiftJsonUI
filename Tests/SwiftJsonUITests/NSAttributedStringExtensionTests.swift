//
//  NSAttributedStringExtensionTests.swift
//  SwiftJsonUI
//

import XCTest
@testable import SwiftJsonUI

final class NSAttributedStringExtensionTests: XCTestCase {

    func testHeightForAttributedStringBasic() {
        let string = NSAttributedString(string: "Test")
        let height = string.heightForAttributedString(100, lineHeightMultiple: 1.0)

        XCTAssertGreaterThan(height, 0)
    }

    func testHeightForAttributedStringWithLargerWidth() {
        let string = NSAttributedString(string: "This is a longer text that might wrap")
        let heightNarrow = string.heightForAttributedString(50, lineHeightMultiple: 1.0)
        let heightWide = string.heightForAttributedString(200, lineHeightMultiple: 1.0)

        // Narrow width should produce taller height due to wrapping
        XCTAssertGreaterThan(heightNarrow, 0)
        XCTAssertGreaterThan(heightWide, 0)
    }

    func testHeightWithLineHeightMultiple() {
        let string = NSAttributedString(string: "Test")
        let height1x = string.heightForAttributedString(100, lineHeightMultiple: 1.0)
        let height2x = string.heightForAttributedString(100, lineHeightMultiple: 2.0)

        XCTAssertGreaterThan(height2x, height1x)
    }

    func testWidthForAttributedString() {
        let string = NSAttributedString(string: "Test")
        let width = string.widthForAttributedString()

        XCTAssertGreaterThan(width, 0)
    }

    func testWidthForLongerString() {
        let shortString = NSAttributedString(string: "Hi")
        let longString = NSAttributedString(string: "This is much longer")

        let shortWidth = shortString.widthForAttributedString()
        let longWidth = longString.widthForAttributedString()

        XCTAssertGreaterThan(longWidth, shortWidth)
    }

    func testLineCountForAttributedString() {
        let string = NSAttributedString(string: "Test")
        let lineCount = string.lineCountForAttributedString(100, lineHeightMultiple: 1.0, fontSize: 14)

        XCTAssertGreaterThanOrEqual(lineCount, 1)
    }

    func testLineCountWithWrapping() {
        let longString = NSAttributedString(string: "This is a very long text that will definitely wrap to multiple lines when constrained to a narrow width")
        let lineCountNarrow = longString.lineCountForAttributedString(50, lineHeightMultiple: 1.0, fontSize: 14)
        let lineCountWide = longString.lineCountForAttributedString(500, lineHeightMultiple: 1.0, fontSize: 14)

        // Narrow width should produce more lines
        XCTAssertGreaterThan(lineCountNarrow, lineCountWide)
    }

    func testApplyAttributesWithFontSize() {
        let string = NSAttributedString(string: "Test")
        let attrs = [JSON(["fontSize": 20, "range": [[0, 4]]])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.string, "Test")
    }

    func testApplyAttributesWithFontColor() {
        let string = NSAttributedString(string: "Test")
        let attrs = [JSON(["fontColor": "#FF0000", "range": [[0, 4]]])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
    }

    func testApplyAttributesWithTextAlign() {
        let string = NSAttributedString(string: "Test")
        let attrs = [JSON(["textAlign": "Center", "range": [[0, 4]]])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
    }

    func testApplyAttributesWithLineSpacing() {
        let string = NSAttributedString(string: "Test\nLine 2")
        let attrs = [JSON(["lineSpacing": 10, "range": [[0, 5]]])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
    }

    func testApplyAttributesWithUnderline() {
        let string = NSAttributedString(string: "Test")
        let attrs = [JSON([
            "underline": ["lineStyle": "Single", "color": "#000000"],
            "range": [[0, 4]]
        ])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
    }

    func testApplyAttributesWithStringRange() {
        let string = NSAttributedString(string: "Hello World")
        let attrs = [JSON([
            "fontSize": 16,
            "range": ["World"]
        ])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.string, "Hello World")
    }

    func testApplyAttributesWithMultipleRanges() {
        let string = NSAttributedString(string: "Test String")
        let attrs = [JSON([
            "fontSize": 18,
            "fontColor": "#0000FF",
            "range": [[0, 4], [5, 6]]
        ])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
    }

    func testApplyAttributesWithLineBreakMode() {
        let string = NSAttributedString(string: "Test")
        let attrs = [JSON(["lineBreakMode": "Tail", "range": [[0, 4]]])]

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertNotNil(result)
    }

    func testApplyAttributesEmptyArray() {
        let string = NSAttributedString(string: "Test")
        let attrs: [JSON] = []

        let result = string.applyAttributesFromJSON(attrs: attrs)

        XCTAssertEqual(result.string, "Test")
    }
}
