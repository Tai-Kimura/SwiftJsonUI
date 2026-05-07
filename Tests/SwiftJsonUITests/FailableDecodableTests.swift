//
//  FailableDecodableTests.swift
//  SwiftJsonUI
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class FailableDecodableTests: XCTestCase {

    struct TestStruct: Codable {
        let name: String
        let value: Int
    }

    func testSuccessfulDecoding() throws {
        let json = """
        {
            "name": "test",
            "value": 42
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let failable = try decoder.decode(FailableDecodable<TestStruct>.self, from: json)

        XCTAssertNotNil(failable.value)
        XCTAssertEqual(failable.value?.name, "test")
        XCTAssertEqual(failable.value?.value, 42)
    }

    func testFailedDecoding() throws {
        let json = """
        {
            "name": "test",
            "wrongField": "invalid"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let failable = try decoder.decode(FailableDecodable<TestStruct>.self, from: json)

        XCTAssertNil(failable.value)
    }

    func testArrayWithAllValidElements() throws {
        let json = """
        [
            {"name": "test1", "value": 1},
            {"name": "test2", "value": 2},
            {"name": "test3", "value": 3}
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let container = try decoder.decode([FailableDecodable<TestStruct>].self, from: json)
        let result = container.compactMap { $0.value }

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].name, "test1")
        XCTAssertEqual(result[1].name, "test2")
        XCTAssertEqual(result[2].name, "test3")
    }

    func testArrayWithSomeInvalidElements() throws {
        let json = """
        [
            {"name": "test1", "value": 1},
            {"invalid": "data"},
            {"name": "test3", "value": 3}
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let container = try decoder.decode([FailableDecodable<TestStruct>].self, from: json)
        let result = container.compactMap { $0.value }

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "test1")
        XCTAssertEqual(result[1].name, "test3")
    }

    func testArrayWithAllInvalidElements() throws {
        let json = """
        [
            {"invalid": "data1"},
            {"invalid": "data2"}
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let container = try decoder.decode([FailableDecodable<TestStruct>].self, from: json)
        let result = container.compactMap { $0.value }

        XCTAssertEqual(result.count, 0)
    }

    func testEmptyArray() throws {
        let json = "[]".data(using: .utf8)!

        let decoder = JSONDecoder()
        let container = try decoder.decode([FailableDecodable<TestStruct>].self, from: json)
        let result = container.compactMap { $0.value }

        XCTAssertEqual(result.count, 0)
    }

    func testNullValue() throws {
        let json = "null".data(using: .utf8)!

        let decoder = JSONDecoder()
        // FailableDecodable catches the error and sets value to nil
        let failable = try decoder.decode(FailableDecodable<TestStruct>.self, from: json)
        XCTAssertNil(failable.value)
    }

    func testIntegerDecoding() throws {
        let json = "42".data(using: .utf8)!

        let decoder = JSONDecoder()
        let failable = try decoder.decode(FailableDecodable<Int>.self, from: json)

        XCTAssertNotNil(failable.value)
        XCTAssertEqual(failable.value, 42)
    }

    func testStringDecoding() throws {
        let json = "\"test\"".data(using: .utf8)!

        let decoder = JSONDecoder()
        let failable = try decoder.decode(FailableDecodable<String>.self, from: json)

        XCTAssertNotNil(failable.value)
        XCTAssertEqual(failable.value, "test")
    }

    func testBoolDecoding() throws {
        let json = "true".data(using: .utf8)!

        let decoder = JSONDecoder()
        let failable = try decoder.decode(FailableDecodable<Bool>.self, from: json)

        XCTAssertNotNil(failable.value)
        XCTAssertEqual(failable.value, true)
    }
}
#endif
