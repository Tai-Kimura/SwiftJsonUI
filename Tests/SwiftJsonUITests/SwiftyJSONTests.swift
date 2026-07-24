//
//  SwiftyJSONTests.swift
//  SwiftJsonUITests
//
//  Tests for SwiftyJSON library integration
//

import XCTest
@testable import SwiftJsonUI

final class SwiftyJSONTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitWithValidJSONData() throws {
        let jsonString = """
        {"name": "John", "age": 30}
        """
        let data = jsonString.data(using: .utf8)!
        let json = try JSON(data: data)

        XCTAssertEqual(json["name"].string, "John")
        XCTAssertEqual(json["age"].int, 30)
    }

    func testInitWithInvalidJSONData() {
        let invalidData = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try JSON(data: invalidData))
    }

    func testInitWithObject() {
        let dict = ["key": "value", "number": 42] as [String : Any]
        let json = JSON(dict)

        XCTAssertEqual(json["key"].string, "value")
        XCTAssertEqual(json["number"].int, 42)
    }

    func testInitWithArray() {
        let array = [1, 2, 3, 4, 5]
        let json = JSON(array)

        XCTAssertEqual(json.arrayValue.count, 5)
        XCTAssertEqual(json[0].int, 1)
        XCTAssertEqual(json[4].int, 5)
    }

    func testInitWithString() {
        let json = JSON("Hello World")
        XCTAssertEqual(json.string, "Hello World")
    }

    func testInitWithInt() {
        let json = JSON(42)
        XCTAssertEqual(json.int, 42)
    }

    func testInitWithDouble() {
        let json = JSON(3.14)
        if let doubleVal = json.double {
            XCTAssertEqual(doubleVal, 3.14, accuracy: 0.001)
        } else {
            XCTFail("Expected double value")
        }
    }

    func testInitWithBool() {
        let trueJson = JSON(true)
        let falseJson = JSON(false)

        XCTAssertEqual(trueJson.bool, true)
        XCTAssertEqual(falseJson.bool, false)
    }

    func testInitWithNull() {
        let json = JSON(NSNull())
        XCTAssertEqual(json.type, .null)
        XCTAssertNil(json.string)
    }

    func testInitParseJSON() {
        let jsonString = """
        {"name": "Alice", "age": 25}
        """
        let json = JSON(parseJSON: jsonString)

        XCTAssertEqual(json["name"].string, "Alice")
        XCTAssertEqual(json["age"].int, 25)
    }

    func testInitParseJSONInvalid() {
        let invalidString = "not valid json"
        let json = JSON(parseJSON: invalidString)

        XCTAssertEqual(json.type, .null)
    }

    // MARK: - Type Tests

    func testTypeDetection() {
        XCTAssertEqual(JSON(42).type, .number)
        XCTAssertEqual(JSON("text").type, .string)
        XCTAssertEqual(JSON(true).type, .bool)
        XCTAssertEqual(JSON([1, 2, 3]).type, .array)
        XCTAssertEqual(JSON(["key": "value"]).type, .dictionary)
        XCTAssertEqual(JSON(NSNull()).type, .null)
    }

    // MARK: - Dictionary Access Tests

    func testDictionarySubscript() {
        let json = JSON(["name": "Bob", "age": 35])

        XCTAssertEqual(json["name"].string, "Bob")
        XCTAssertEqual(json["age"].int, 35)
    }

    func testDictionaryNestedAccess() {
        let json = JSON([
            "user": [
                "name": "Charlie",
                "address": [
                    "city": "Tokyo"
                ]
            ]
        ])

        XCTAssertEqual(json["user"]["name"].string, "Charlie")
        XCTAssertEqual(json["user"]["address"]["city"].string, "Tokyo")
    }

    func testDictionaryMissingKey() {
        let json = JSON(["key": "value"])
        let missing = json["nonexistent"]

        XCTAssertNil(missing.string)
        XCTAssertEqual(missing.type, .null)
    }

    // MARK: - Array Access Tests

    func testArraySubscript() {
        let json = JSON([10, 20, 30, 40])

        XCTAssertEqual(json[0].int, 10)
        XCTAssertEqual(json[1].int, 20)
        XCTAssertEqual(json[3].int, 40)
    }

    func testArrayOutOfBounds() {
        let json = JSON([1, 2, 3])
        let outOfBounds = json[10]

        XCTAssertNil(outOfBounds.int)
        XCTAssertEqual(outOfBounds.type, .null)
    }

    func testArrayNegativeIndex() {
        let json = JSON([1, 2, 3])
        let negative = json[-1]

        XCTAssertNil(negative.int)
        XCTAssertEqual(negative.type, .null)
    }

    // MARK: - Value Extraction Tests

    func testStringValue() {
        let json = JSON("Hello")
        XCTAssertEqual(json.string, "Hello")
        XCTAssertEqual(json.stringValue, "Hello")
    }

    func testStringValueFromNonString() {
        let json = JSON(42)
        XCTAssertNil(json.string)
        XCTAssertEqual(json.stringValue, "42") // stringValue converts to string
    }

    func testIntValue() {
        let json = JSON(42)
        XCTAssertEqual(json.int, 42)
        XCTAssertEqual(json.intValue, 42)
    }

    func testIntValueFromString() {
        let json = JSON("123")
        XCTAssertNil(json.int)
    }

    func testDoubleValue() {
        let json = JSON(3.14)
        if let doubleVal = json.double {
            XCTAssertEqual(doubleVal, 3.14, accuracy: 0.001)
        }
        XCTAssertEqual(json.doubleValue, 3.14, accuracy: 0.001)
    }

    func testDoubleValueFromInt() {
        let json = JSON(42)
        if let doubleVal = json.double {
            XCTAssertEqual(doubleVal, 42.0, accuracy: 0.001)
        }
    }

    func testBoolValue() {
        let trueJson = JSON(true)
        let falseJson = JSON(false)

        XCTAssertEqual(trueJson.bool, true)
        XCTAssertEqual(falseJson.bool, false)
        XCTAssertEqual(trueJson.boolValue, true)
        XCTAssertEqual(falseJson.boolValue, false)
    }

    func testBoolValueFromNumber() {
        let json = JSON(1)
        XCTAssertEqual(json.boolValue, true)

        let zeroJson = JSON(0)
        XCTAssertEqual(zeroJson.boolValue, false)
    }

    func testArrayValue() {
        let json = JSON([1, 2, 3])
        let array = json.arrayValue

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].int, 1)
        XCTAssertEqual(array[2].int, 3)
    }

    func testArrayValueFromNonArray() {
        let json = JSON("not an array")
        let array = json.arrayValue

        XCTAssertEqual(array.count, 0)
    }

    func testDictionaryValue() {
        let json = JSON(["key": "value"])
        let dict = json.dictionaryValue

        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict["key"]?.string, "value")
    }

    func testDictionaryValueFromNonDict() {
        let json = JSON("not a dict")
        let dict = json.dictionaryValue

        XCTAssertEqual(dict.count, 0)
    }

    // MARK: - Raw Value Tests

    func testRawString() {
        let json = JSON("test")
        // rawString returns the value without outer quotes in some implementations
        let raw = json.rawString()
        XCTAssertNotNil(raw)
        XCTAssertTrue(raw!.contains("test"))
    }

    func testRawStringWithOptions() {
        let json = JSON(["key": "value"])
        let raw = json.rawString()

        XCTAssertNotNil(raw)
        XCTAssertTrue(raw!.contains("key"))
        XCTAssertTrue(raw!.contains("value"))
    }

    func testRawStringPrettyPrinted() {
        let json = JSON(["a": 1, "b": 2])
        let raw = json.rawString()  // Default uses prettyPrinted

        XCTAssertNotNil(raw)
        XCTAssertTrue(raw!.contains("\n"))
    }

    // MARK: - Merge Tests

    func testMergeDictionaries() throws {
        var json1 = JSON(["a": 1, "b": 2])
        let json2 = JSON(["c": 3])

        try json1.merge(with: json2)

        XCTAssertEqual(json1["a"].int, 1)
        XCTAssertEqual(json1["b"].int, 2)
        XCTAssertEqual(json1["c"].int, 3)
    }

    func testMergeOverwriteValues() throws {
        var json1 = JSON(["a": 1, "b": 2])
        let json2 = JSON(["b": 99])

        try json1.merge(with: json2)

        XCTAssertEqual(json1["a"].int, 1)
        XCTAssertEqual(json1["b"].int, 99)
    }

    func testMergeArrays() throws {
        var json1 = JSON([1, 2, 3])
        let json2 = JSON([4, 5])

        try json1.merge(with: json2)

        let array = json1.arrayValue
        XCTAssertEqual(array.count, 5)
        XCTAssertEqual(array[0].int, 1)
        XCTAssertEqual(array[4].int, 5)
    }

    func testMergeDifferentTypesThrows() {
        var json1 = JSON(["key": "value"])
        let json2 = JSON([1, 2, 3])

        XCTAssertThrowsError(try json1.merge(with: json2)) { error in
            XCTAssertTrue(error is SwiftyJSONError)
            if let swiftyError = error as? SwiftyJSONError {
                XCTAssertEqual(swiftyError, .wrongType)
            }
        }
    }

    func testMergedReturnsNew() throws {
        let json1 = JSON(["a": 1])
        let json2 = JSON(["b": 2])

        let merged = try json1.merged(with: json2)

        XCTAssertEqual(merged["a"].int, 1)
        XCTAssertEqual(merged["b"].int, 2)
        // Original should be unchanged
        XCTAssertNil(json1["b"].int)
    }

    // MARK: - Error Tests

    func testErrorDomain() {
        XCTAssertEqual(SwiftyJSONError.errorDomain, "com.swiftyjson.SwiftyJSON")
    }

    func testErrorCodes() {
        XCTAssertEqual(SwiftyJSONError.unsupportedType.errorCode, 999)
        XCTAssertEqual(SwiftyJSONError.indexOutOfBounds.errorCode, 900)
        XCTAssertEqual(SwiftyJSONError.wrongType.errorCode, 901)
        XCTAssertEqual(SwiftyJSONError.notExist.errorCode, 500)
        XCTAssertEqual(SwiftyJSONError.invalidJSON.errorCode, 490)
    }

    func testErrorUserInfo() {
        let error = SwiftyJSONError.unsupportedType
        let userInfo = error.errorUserInfo

        XCTAssertTrue(userInfo[NSLocalizedDescriptionKey] is String)
    }

    // MARK: - Exists Tests

    func testExistsForValidPath() {
        let json = JSON(["user": ["name": "John"]])

        XCTAssertTrue(json["user"]["name"].exists())
        XCTAssertTrue(json["user"].exists())
    }

    func testExistsForInvalidPath() {
        let json = JSON(["user": ["name": "John"]])

        XCTAssertFalse(json["invalid"].exists())
        XCTAssertFalse(json["user"]["invalid"].exists())
    }

    // MARK: - Complex JSON Tests

    func testComplexNestedJSON() throws {
        let jsonString = """
        {
            "users": [
                {"name": "Alice", "age": 25},
                {"name": "Bob", "age": 30}
            ],
            "metadata": {
                "total": 2,
                "page": 1
            }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let json = try JSON(data: data)

        XCTAssertEqual(json["users"][0]["name"].string, "Alice")
        XCTAssertEqual(json["users"][1]["age"].int, 30)
        XCTAssertEqual(json["metadata"]["total"].int, 2)
    }

    func testRealWorldJSON() throws {
        let jsonString = """
        {
            "type": "VStack",
            "children": [
                {
                    "type": "Label",
                    "text": "Hello",
                    "fontSize": 16
                },
                {
                    "type": "Button",
                    "text": "Click Me",
                    "onClick": "handleClick"
                }
            ],
            "padding": [16, 8]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let json = try JSON(data: data)

        XCTAssertEqual(json["type"].string, "VStack")
        XCTAssertEqual(json["children"].arrayValue.count, 2)
        XCTAssertEqual(json["children"][0]["type"].string, "Label")
        XCTAssertEqual(json["padding"][0].int, 16)
        XCTAssertEqual(json["padding"][1].int, 8)
    }

    // MARK: - Dictionary Object Tests

    func testDictionaryObject() {
        let json = JSON(["key1": "value1", "key2": 123])
        let dict = json.dictionaryObject

        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["key1"] as? String, "value1")
        XCTAssertEqual(dict?["key2"] as? Int, 123)
    }

    func testArrayObject() {
        let json = JSON([1, "two", 3.0])
        let array = json.arrayObject

        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 3)
        XCTAssertEqual(array?[0] as? Int, 1)
        XCTAssertEqual(array?[1] as? String, "two")
    }
}
