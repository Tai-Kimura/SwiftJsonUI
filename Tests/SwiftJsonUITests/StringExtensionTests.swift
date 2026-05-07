//
//  StringExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for String extension methods
//

import XCTest
@testable import SwiftJsonUI

final class StringExtensionTests: XCTestCase {

    // MARK: - Katakana Conversion Tests

    func testHiraganaToKatakana() {
        let hiragana = "あいうえお"
        let result = hiragana.katakana()
        XCTAssertEqual(result, "アイウエオ")
    }

    func testHiraganaToKatakanaFullRange() {
        let hiragana = "かきくけこ"
        let result = hiragana.katakana()
        XCTAssertEqual(result, "カキクケコ")
    }

    func testKatakanaPreserved() {
        let katakana = "アイウエオ"
        let result = katakana.katakana()
        XCTAssertEqual(result, "アイウエオ")
    }

    func testMixedKatakanaConversion() {
        let mixed = "あイうエお"
        let result = mixed.katakana()
        XCTAssertEqual(result, "アイウエオ")
    }

    // MARK: - Hiragana Conversion Tests

    func testKatakanaToHiragana() {
        let katakana = "アイウエオ"
        let result = katakana.hiragana()
        XCTAssertEqual(result, "あいうえお")
    }

    func testKatakanaToHiraganaFullRange() {
        let katakana = "カキクケコ"
        let result = katakana.hiragana()
        XCTAssertEqual(result, "かきくけこ")
    }

    func testHiraganaPreserved() {
        let hiragana = "あいうえお"
        let result = hiragana.hiragana()
        XCTAssertEqual(result, "あいうえお")
    }

    // MARK: - Regex Match Tests

    func testGetMatchCountWithMatches() {
        let text = "test123test456"
        let count = text.getMatchCount(pattern: "test")
        XCTAssertEqual(count, 2)
    }

    func testGetMatchCountNoMatches() {
        let text = "hello world"
        let count = text.getMatchCount(pattern: "xyz")
        XCTAssertEqual(count, 0)
    }

    func testGetMatchCountCaseInsensitive() {
        let text = "Test TEST test"
        let count = text.getMatchCount(pattern: "test")
        XCTAssertEqual(count, 3)
    }

    func testIsMatchTrue() {
        let text = "hello world"
        XCTAssertTrue(text.isMatch(pattern: "world"))
    }

    func testIsMatchFalse() {
        let text = "hello world"
        XCTAssertFalse(text.isMatch(pattern: "xyz"))
    }

    // MARK: - Zipcode Formatting Tests

    func testZipcodeFormattingWith7Digits() {
        let zipcode = "1234567"
        let result = zipcode.getFormattedZipcode()
        XCTAssertEqual(result, "123-4567")
    }

    func testZipcodeFormattingWith5Digits() {
        let zipcode = "12345"
        let result = zipcode.getFormattedZipcode()
        XCTAssertEqual(result, "123-45")
    }

    func testZipcodeFormattingWith3Digits() {
        let zipcode = "123"
        let result = zipcode.getFormattedZipcode()
        XCTAssertEqual(result, "123")
    }

    func testZipcodeFormattingWith2Digits() {
        let zipcode = "12"
        let result = zipcode.getFormattedZipcode()
        XCTAssertEqual(result, "12")
    }

    // MARK: - Date Conversion Tests

    func testToDateWithDefaultFormat() {
        let dateString = "2024/01/15 10:30:00"
        let date = dateString.toDate()
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date!)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 10)
        XCTAssertEqual(components.minute, 30)
    }

    func testToDateWithCustomFormat() {
        let dateString = "15-01-2024"
        let date = dateString.toDate(format: "dd-MM-yyyy")
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
    }

    func testToDateWithInvalidFormat() {
        let dateString = "invalid date"
        let date = dateString.toDate()
        XCTAssertNil(date)
    }

    // MARK: - Camel Case Conversion Tests

    func testToCamelLowerCase() {
        let snakeCase = "hello_world"
        let result = snakeCase.toCamel(lower: true)
        XCTAssertEqual(result, "helloWorld")
    }

    func testToCamelUpperCase() {
        let snakeCase = "hello_world"
        let result = snakeCase.toCamel(lower: false)
        XCTAssertEqual(result, "HelloWorld")
    }

    func testToCamelSingleWord() {
        let singleWord = "hello"
        let result = singleWord.toCamel(lower: true)
        XCTAssertEqual(result, "hello")
    }

    func testToCamelMultipleUnderscores() {
        let snakeCase = "hello_world_test"
        let result = snakeCase.toCamel(lower: true)
        XCTAssertEqual(result, "helloWorldTest")
    }

    func testToCamelEmpty() {
        let empty = ""
        let result = empty.toCamel()
        XCTAssertEqual(result, "")
    }

    // MARK: - Snake Case Conversion Tests

    func testToSnakeFromCamel() {
        let camelCase = "helloWorld"
        let result = camelCase.toSnake()
        XCTAssertEqual(result, "hello_world")
    }

    func testToSnakeFromPascal() {
        let pascalCase = "HelloWorld"
        let result = pascalCase.toSnake()
        XCTAssertEqual(result, "hello_world")
    }

    func testToSnakeSingleWord() {
        let singleWord = "hello"
        let result = singleWord.toSnake()
        XCTAssertEqual(result, "hello")
    }

    func testToSnakeMultipleWords() {
        let camelCase = "helloWorldTest"
        let result = camelCase.toSnake()
        XCTAssertEqual(result, "hello_world_test")
    }
}
