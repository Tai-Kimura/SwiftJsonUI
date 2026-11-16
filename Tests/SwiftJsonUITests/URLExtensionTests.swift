//
//  URLExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for URL extension methods
//

import XCTest
@testable import SwiftJsonUI

final class URLExtensionTests: XCTestCase {

    // MARK: - Without Query Tests

    func testWithoutQuerySimple() {
        let url = URL(string: "https://example.com/path?key=value")!
        let result = url.withoutQuery()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://example.com/path")
    }

    func testWithoutQueryMultipleParams() {
        let url = URL(string: "https://example.com/path?key1=value1&key2=value2")!
        let result = url.withoutQuery()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://example.com/path")
    }

    func testWithoutQueryNoQuery() {
        let url = URL(string: "https://example.com/path")!
        let result = url.withoutQuery()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://example.com/path")
    }

    func testWithoutQueryOnlyDomain() {
        let url = URL(string: "https://example.com?key=value")!
        let result = url.withoutQuery()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://example.com")
    }

    func testWithoutQueryWithFragment() {
        let url = URL(string: "https://example.com/path?key=value#section")!
        let result = url.withoutQuery()

        XCTAssertNotNil(result)
        // Fragment should be preserved
        XCTAssertTrue(result?.absoluteString.contains("#section") ?? false)
        XCTAssertFalse(result?.absoluteString.contains("key=value") ?? true)
    }

    func testWithoutQueryEmptyQuery() {
        let url = URL(string: "https://example.com/path?")!
        let result = url.withoutQuery()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://example.com/path")
    }

    func testWithoutQueryResolvingBaseURL() {
        let baseURL = URL(string: "https://example.com/")!
        let url = URL(string: "path?key=value", relativeTo: baseURL)!
        let result = url.withoutQuery(resolvingAgainstBaseURL: true)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.absoluteString.contains("example.com") ?? false)
    }

    func testWithoutQueryComplexPath() {
        let url = URL(string: "https://example.com/path/to/resource?param1=value1&param2=value2")!
        let result = url.withoutQuery()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://example.com/path/to/resource")
    }
}
