//
//  DynamicPaddingTests.swift
//  SwiftJsonUI
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicPaddingTests: XCTestCase {

    // MARK: - Single Value Tests

    func testSingleCGFloatValue() throws {
        let json = """
        10.0
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 10.0)
        XCTAssertEqual(insets.leading, 10.0)
        XCTAssertEqual(insets.bottom, 10.0)
        XCTAssertEqual(insets.trailing, 10.0)
    }

    func testSingleIntValue() throws {
        let json = """
        12
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 12.0)
        XCTAssertEqual(insets.leading, 12.0)
        XCTAssertEqual(insets.bottom, 12.0)
        XCTAssertEqual(insets.trailing, 12.0)
    }

    func testSingleStringValue() throws {
        let json = """
        "15.5"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 15.5)
        XCTAssertEqual(insets.leading, 15.5)
        XCTAssertEqual(insets.bottom, 15.5)
        XCTAssertEqual(insets.trailing, 15.5)
    }

    // MARK: - Array Value Tests

    func testArrayWithOneValue() throws {
        let json = """
        [8]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 8.0)
        XCTAssertEqual(insets.leading, 8.0)
        XCTAssertEqual(insets.bottom, 8.0)
        XCTAssertEqual(insets.trailing, 8.0)
    }

    func testArrayWithTwoValues() throws {
        let json = """
        [10, 20]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 10.0)
        XCTAssertEqual(insets.leading, 20.0)
        XCTAssertEqual(insets.bottom, 10.0)
        XCTAssertEqual(insets.trailing, 20.0)
    }

    func testArrayWithThreeValues() throws {
        let json = """
        [5, 10, 15]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 5.0)
        XCTAssertEqual(insets.leading, 10.0)
        XCTAssertEqual(insets.bottom, 15.0)
        XCTAssertEqual(insets.trailing, 10.0)
    }

    func testArrayWithFourValues() throws {
        let json = """
        [5, 10, 15, 20]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 5.0)
        XCTAssertEqual(insets.leading, 20.0)
        XCTAssertEqual(insets.bottom, 15.0)
        XCTAssertEqual(insets.trailing, 10.0)
    }

    func testArrayWithMoreThanFourValues() throws {
        let json = """
        [1, 2, 3, 4, 5]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        // Should return empty EdgeInsets for arrays with more than 4 values
        XCTAssertEqual(insets.top, 0.0)
        XCTAssertEqual(insets.leading, 0.0)
        XCTAssertEqual(insets.bottom, 0.0)
        XCTAssertEqual(insets.trailing, 0.0)
    }

    // MARK: - asArray Tests

    func testAsArrayFromSingle() throws {
        let json = """
        10
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let array = padding.asArray
        XCTAssertEqual(array, [10.0, 10.0, 10.0, 10.0])
    }

    func testAsArrayFromArray() throws {
        let json = """
        [5, 10, 15, 20]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let array = padding.asArray
        XCTAssertEqual(array, [5.0, 10.0, 15.0, 20.0])
    }

    // MARK: - Error Cases

    func testInvalidStringValue() {
        let json = """
        "not a number"
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(DynamicPadding.self, from: json))
    }

    func testEmptyArray() throws {
        let json = """
        []
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 0.0)
        XCTAssertEqual(insets.leading, 0.0)
        XCTAssertEqual(insets.bottom, 0.0)
        XCTAssertEqual(insets.trailing, 0.0)
    }

    func testNegativeValues() throws {
        let json = """
        [-5, -10]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, -5.0)
        XCTAssertEqual(insets.leading, -10.0)
    }

    func testZeroValue() throws {
        let json = """
        0
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let padding = try decoder.decode(DynamicPadding.self, from: json)

        let insets = padding.edgeInsets
        XCTAssertEqual(insets.top, 0.0)
        XCTAssertEqual(insets.leading, 0.0)
        XCTAssertEqual(insets.bottom, 0.0)
        XCTAssertEqual(insets.trailing, 0.0)
    }
}
#endif
