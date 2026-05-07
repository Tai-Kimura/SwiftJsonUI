//
//  DynamicDecodingHelperTests.swift
//  SwiftJsonUITests
//
//  Tests for DynamicDecodingHelper utilities
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicDecodingHelperTests: XCTestCase {

    // MARK: - AnyCodable to Float Array Tests

    func testAnyCodableToFloatArrayFromIntArray() {
        let value = AnyCodable([10, 20, 30, 40])
        let result = DynamicDecodingHelper.anyCodableToFloatArray(value)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 4)
        XCTAssertEqual(result?[0], 10)
        XCTAssertEqual(result?[1], 20)
        XCTAssertEqual(result?[2], 30)
        XCTAssertEqual(result?[3], 40)
    }

    func testAnyCodableToFloatArrayFromDoubleArray() {
        let value = AnyCodable([10.5, 20.5])
        let result = DynamicDecodingHelper.anyCodableToFloatArray(value)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(Double(result?[0] ?? 0), 10.5, accuracy: 0.01)
        XCTAssertEqual(Double(result?[1] ?? 0), 20.5, accuracy: 0.01)
    }

    func testAnyCodableToFloatArrayFromSingleValue() {
        let value = AnyCodable(15)
        let result = DynamicDecodingHelper.anyCodableToFloatArray(value)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[0], 15)
    }

    func testAnyCodableToFloatArrayNil() {
        let result = DynamicDecodingHelper.anyCodableToFloatArray(nil)
        XCTAssertNil(result)
    }

    // MARK: - EdgeInsets from Array Tests

    func testEdgeInsetsFromArraySingleValue() {
        let values: [CGFloat] = [10]
        let result = DynamicDecodingHelper.edgeInsetsFromArray(values)

        XCTAssertEqual(result.top, 10)
        XCTAssertEqual(result.leading, 10)
        XCTAssertEqual(result.bottom, 10)
        XCTAssertEqual(result.trailing, 10)
    }

    func testEdgeInsetsFromArrayTwoValues() {
        let values: [CGFloat] = [10, 20] // [Vertical, Horizontal]
        let result = DynamicDecodingHelper.edgeInsetsFromArray(values)

        XCTAssertEqual(result.top, 10)
        XCTAssertEqual(result.bottom, 10)
        XCTAssertEqual(result.leading, 20)
        XCTAssertEqual(result.trailing, 20)
    }

    func testEdgeInsetsFromArrayFourValues() {
        let values: [CGFloat] = [10, 20, 30, 40] // [Top, Right, Bottom, Left]
        let result = DynamicDecodingHelper.edgeInsetsFromArray(values)

        XCTAssertEqual(result.top, 10)
        XCTAssertEqual(result.trailing, 20)
        XCTAssertEqual(result.bottom, 30)
        XCTAssertEqual(result.leading, 40)
    }

    func testEdgeInsetsFromArrayEmptyReturnsZero() {
        let values: [CGFloat] = []
        let result = DynamicDecodingHelper.edgeInsetsFromArray(values)

        XCTAssertEqual(result.top, 0)
        XCTAssertEqual(result.leading, 0)
        XCTAssertEqual(result.bottom, 0)
        XCTAssertEqual(result.trailing, 0)
    }

    // MARK: - Gravity to Alignment Tests

    func testGravityToAlignmentCenter() {
        let result = DynamicDecodingHelper.gravityToAlignment(["center"])
        XCTAssertEqual(result, .center)
    }

    func testGravityToAlignmentTopLeft() {
        let result = DynamicDecodingHelper.gravityToAlignment(["top", "left"])
        XCTAssertEqual(result, .topLeading)
    }

    func testGravityToAlignmentTopRight() {
        let result = DynamicDecodingHelper.gravityToAlignment(["top", "right"])
        XCTAssertEqual(result, .topTrailing)
    }

    func testGravityToAlignmentBottomLeft() {
        let result = DynamicDecodingHelper.gravityToAlignment(["bottom", "left"])
        XCTAssertEqual(result, .bottomLeading)
    }

    func testGravityToAlignmentBottomRight() {
        let result = DynamicDecodingHelper.gravityToAlignment(["bottom", "right"])
        XCTAssertEqual(result, .bottomTrailing)
    }

    func testGravityToAlignmentTop() {
        let result = DynamicDecodingHelper.gravityToAlignment(["top"])
        XCTAssertEqual(result, .top)
    }

    func testGravityToAlignmentBottom() {
        let result = DynamicDecodingHelper.gravityToAlignment(["bottom"])
        XCTAssertEqual(result, .bottom)
    }

    func testGravityToAlignmentStart() {
        let result = DynamicDecodingHelper.gravityToAlignment(["start"])
        XCTAssertEqual(result, .leading)
    }

    func testGravityToAlignmentEnd() {
        let result = DynamicDecodingHelper.gravityToAlignment(["end"])
        XCTAssertEqual(result, .trailing)
    }

    func testGravityToAlignmentNil() {
        let result = DynamicDecodingHelper.gravityToAlignment(nil)
        XCTAssertNil(result)
    }

    func testGravityToAlignmentEmpty() {
        let result = DynamicDecodingHelper.gravityToAlignment([])
        XCTAssertNil(result)
    }

    func testGravityToAlignmentCenterHorizontal() {
        let result = DynamicDecodingHelper.gravityToAlignment(["top", "center_horizontal"])
        XCTAssertEqual(result, .top)
    }

    func testGravityToAlignmentCenterVertical() {
        let result = DynamicDecodingHelper.gravityToAlignment(["center_vertical", "left"])
        XCTAssertEqual(result, .leading)
    }

    // MARK: - Content Mode Tests

    func testToContentModeAspectFit() {
        XCTAssertEqual(DynamicDecodingHelper.toContentMode("AspectFit"), .fit)
        XCTAssertEqual(DynamicDecodingHelper.toContentMode("aspectFit"), .fit)
    }

    func testToContentModeAspectFill() {
        XCTAssertEqual(DynamicDecodingHelper.toContentMode("AspectFill"), .fill)
        XCTAssertEqual(DynamicDecodingHelper.toContentMode("aspectFill"), .fill)
    }

    func testToContentModeDefault() {
        XCTAssertEqual(DynamicDecodingHelper.toContentMode(nil), .fit)
        XCTAssertEqual(DynamicDecodingHelper.toContentMode("unknown"), .fit)
    }

    // MARK: - Rendering Mode Tests

    func testToRenderingModeTemplate() {
        XCTAssertEqual(DynamicDecodingHelper.toRenderingMode("template"), .template)
        XCTAssertEqual(DynamicDecodingHelper.toRenderingMode("Template"), .template)
    }

    func testToRenderingModeOriginal() {
        XCTAssertEqual(DynamicDecodingHelper.toRenderingMode("original"), .original)
        XCTAssertEqual(DynamicDecodingHelper.toRenderingMode("Original"), .original)
    }

    func testToRenderingModeDefault() {
        XCTAssertNil(DynamicDecodingHelper.toRenderingMode(nil))
        XCTAssertNil(DynamicDecodingHelper.toRenderingMode("unknown"))
    }

    // MARK: - Text Alignment Tests

    func testToTextAlignmentCenter() {
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment("Center"), .center)
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment("center"), .center)
    }

    func testToTextAlignmentLeft() {
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment("Left"), .leading)
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment("left"), .leading)
    }

    func testToTextAlignmentRight() {
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment("Right"), .trailing)
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment("right"), .trailing)
    }

    func testToTextAlignmentDefault() {
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment(nil), .leading)
        XCTAssertEqual(DynamicDecodingHelper.toTextAlignment("unknown"), .leading)
    }
}
#endif
