//
//  AnyCodableTests.swift
//  SwiftJsonUITests
//
//  Tests for AnyCodable JSON type handling
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class AnyCodableTests: XCTestCase {

    // MARK: - String Decoding Tests

    func testDecodeString() throws {
        let json = """
        "Hello World"
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? String, "Hello World")
    }

    // MARK: - Number Decoding Tests

    func testDecodeInteger() throws {
        let json = """
        42
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Int, 42)
    }

    func testDecodeDouble() throws {
        let json = """
        3.14159
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        if let doubleValue = value.value as? Double {
            XCTAssertEqual(doubleValue, 3.14159, accuracy: 0.00001)
        } else {
            XCTFail("Expected Double value")
        }
    }

    // MARK: - Boolean Decoding Tests

    func testDecodeBoolTrue() throws {
        let json = """
        true
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Bool, true)
    }

    func testDecodeBoolFalse() throws {
        let json = """
        false
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        XCTAssertEqual(value.value as? Bool, false)
    }

    // MARK: - Array Decoding Tests

    func testDecodeArrayOfStrings() throws {
        let json = """
        ["one", "two", "three"]
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        let array = value.value as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 3)
        XCTAssertEqual(array?[0] as? String, "one")
        XCTAssertEqual(array?[1] as? String, "two")
        XCTAssertEqual(array?[2] as? String, "three")
    }

    func testDecodeArrayOfIntegers() throws {
        let json = """
        [1, 2, 3, 4, 5]
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        let array = value.value as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 5)
    }

    // MARK: - Dictionary Decoding Tests

    func testDecodeDictionary() throws {
        let json = """
        {"name": "John", "age": 30}
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        let dict = value.value as? [String: Any]
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["name"] as? String, "John")
        XCTAssertEqual(dict?["age"] as? Int, 30)
    }

    func testDecodeNestedDictionary() throws {
        let json = """
        {"user": {"name": "Jane", "email": "jane@example.com"}}
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        let dict = value.value as? [String: Any]
        XCTAssertNotNil(dict)

        let user = dict?["user"] as? [String: Any]
        XCTAssertNotNil(user)
        XCTAssertEqual(user?["name"] as? String, "Jane")
        XCTAssertEqual(user?["email"] as? String, "jane@example.com")
    }

    // MARK: - Encoding Tests

    func testEncodeString() throws {
        let value = AnyCodable("Hello World")
        let data = try JSONEncoder().encode(value)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "\"Hello World\"")
    }

    func testEncodeInteger() throws {
        let value = AnyCodable(42)
        let data = try JSONEncoder().encode(value)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "42")
    }

    func testEncodeBool() throws {
        let value = AnyCodable(true)
        let data = try JSONEncoder().encode(value)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, "true")
    }

    // MARK: - DynamicComponent Decoding Tests

    // Note: AnyCodable currently decodes DynamicComponents as generic arrays/dictionaries
    // This test validates the actual behavior where components become dictionaries
    func testDecodeArrayOfDynamicComponents() throws {
        let json = """
        [
            {"type": "Label", "text": "First"},
            {"type": "Label", "text": "Second"}
        ]
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        // AnyCodable decodes this as array of dictionaries, not DynamicComponent
        let array = value.value as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 2)

        // Verify first element is a dictionary with expected keys
        if let first = array?[0] as? [String: Any] {
            XCTAssertEqual(first["type"] as? String, "Label")
            XCTAssertEqual(first["text"] as? String, "First")
        } else {
            XCTFail("Expected dictionary")
        }
    }

    // MARK: - PartialAttributes Decoding Tests

    func testDecodePartialAttributes() throws {
        let json = """
        [
            {"start": 0, "end": 5, "fontColor": "#FF0000"},
            {"start": 5, "end": 10, "fontColor": "#00FF00"}
        ]
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        let array = value.value as? [[String: Any]]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 2)
        XCTAssertEqual(array?[0]["start"] as? Int, 0)
        XCTAssertEqual(array?[0]["end"] as? Int, 5)
        XCTAssertEqual(array?[0]["fontColor"] as? String, "#FF0000")
    }

    // MARK: - Complex JSON Structure Tests

    func testDecodeComplexStructure() throws {
        let json = """
        {
            "string": "value",
            "number": 42,
            "decimal": 3.14,
            "boolean": true,
            "array": [1, 2, 3],
            "nested": {
                "key": "value"
            }
        }
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AnyCodable.self, from: json)

        let dict = value.value as? [String: Any]
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["string"] as? String, "value")
        XCTAssertEqual(dict?["number"] as? Int, 42)
        XCTAssertEqual(dict?["boolean"] as? Bool, true)

        let array = dict?["array"] as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 3)

        let nested = dict?["nested"] as? [String: Any]
        XCTAssertNotNil(nested)
        XCTAssertEqual(nested?["key"] as? String, "value")
    }
}
#endif
