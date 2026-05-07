//
//  IntExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for Int extension methods
//

import XCTest
@testable import SwiftJsonUI

final class IntExtensionTests: XCTestCase {

    // MARK: - Price String Tests

    func testPriceStringSimple() {
        let price = 1000
        XCTAssertEqual(price.priceString, "1,000")
    }

    func testPriceStringLarge() {
        let price = 1000000
        XCTAssertEqual(price.priceString, "1,000,000")
    }

    func testPriceStringZero() {
        let price = 0
        XCTAssertEqual(price.priceString, "0")
    }

    func testPriceStringSmall() {
        let price = 100
        XCTAssertEqual(price.priceString, "100")
    }

    func testPriceStringNegative() {
        let price = -1000
        XCTAssertEqual(price.priceString, "-1,000")
    }

    func testPriceStringVeryLarge() {
        let price = 1234567890
        XCTAssertEqual(price.priceString, "1,234,567,890")
    }

    func testPriceStringSingleDigit() {
        let price = 5
        XCTAssertEqual(price.priceString, "5")
    }

    func testPriceStringThousand() {
        let price = 1000
        let formatted = price.priceString
        XCTAssertTrue(formatted.contains(","))
        XCTAssertEqual(formatted, "1,000")
    }

    func testPriceStringMillion() {
        let price = 999999
        XCTAssertEqual(price.priceString, "999,999")
    }
}
