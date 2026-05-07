//
//  DoubleExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for Double extension methods
//

import XCTest
@testable import SwiftJsonUI

final class DoubleExtensionTests: XCTestCase {

    // MARK: - Date Conversion Tests

    func testToDate() {
        let timestamp: Double = 1609459200 // 2021-01-01 00:00:00 UTC
        let date = timestamp.toDate

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        XCTAssertEqual(components.year, 2021)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
    }

    func testToDateWithZeroTimestamp() {
        let timestamp: Double = 0
        let date = timestamp.toDate

        XCTAssertNotNil(date)
        XCTAssertEqual(date.timeIntervalSince1970, 0)
    }

    func testToDateWithNegativeTimestamp() {
        let timestamp: Double = -86400 // One day before epoch
        let date = timestamp.toDate

        XCTAssertNotNil(date)
        XCTAssertEqual(date.timeIntervalSince1970, -86400)
    }

    // MARK: - Byte Conversion Tests

    func testKiloByte() {
        let bytes: Double = 1024
        XCTAssertEqual(bytes.kiloByte, 1.0)
    }

    func testKiloByteWithDecimal() {
        let bytes: Double = 2048
        XCTAssertEqual(bytes.kiloByte, 2.0)
    }

    func testKiloByteSmallValue() {
        let bytes: Double = 512
        XCTAssertEqual(bytes.kiloByte, 0.5)
    }

    func testMegaByte() {
        let bytes: Double = 1048576 // 1024 * 1024
        XCTAssertEqual(bytes.megaByte, 1.0)
    }

    func testMegaByteWithDecimal() {
        let bytes: Double = 2097152 // 2 * 1024 * 1024
        XCTAssertEqual(bytes.megaByte, 2.0)
    }

    func testMegaByteSmallValue() {
        let bytes: Double = 524288 // 0.5 * 1024 * 1024
        XCTAssertEqual(bytes.megaByte, 0.5)
    }

    func testGigaByte() {
        let bytes: Double = 1073741824 // 1024 * 1024 * 1024
        XCTAssertEqual(bytes.gigaByte, 1.0)
    }

    func testGigaByteWithDecimal() {
        let bytes: Double = 2147483648 // 2 * 1024 * 1024 * 1024
        XCTAssertEqual(bytes.gigaByte, 2.0)
    }

    func testGigaByteSmallValue() {
        let bytes: Double = 536870912 // 0.5 * 1024 * 1024 * 1024
        XCTAssertEqual(bytes.gigaByte, 0.5)
    }

    func testZeroBytes() {
        let bytes: Double = 0
        XCTAssertEqual(bytes.kiloByte, 0)
        XCTAssertEqual(bytes.megaByte, 0)
        XCTAssertEqual(bytes.gigaByte, 0)
    }

    // MARK: - Date String Formatting Tests

    func testToDateStringDefaultFormat() {
        let timestamp: Double = 1609459200 // 2021-01-01 00:00:00 UTC
        let dateString = timestamp.toDateString()

        // The exact string depends on timezone, but should contain year/month/day
        XCTAssertTrue(dateString.contains("2021") || dateString.contains("2020"))
    }

    func testToDateStringCustomFormat() {
        let timestamp: Double = 1609459200
        let dateString = timestamp.toDateString(format: "dd-MM-yyyy")

        // Should match custom format pattern
        XCTAssertTrue(dateString.contains("-"))
        XCTAssertTrue(dateString.contains("2021") || dateString.contains("2020"))
    }

    func testToDateStringWithLocale() {
        let timestamp: Double = 1609459200
        let locale = Locale(identifier: "en_US")
        let dateString = timestamp.toDateString(locale: locale)

        XCTAssertFalse(dateString.isEmpty)
    }

    func testToDateTimeStringDefaultFormat() {
        let timestamp: Double = 1609459200
        let dateTimeString = timestamp.toDateTimeString()

        XCTAssertFalse(dateTimeString.isEmpty)
        XCTAssertTrue(dateTimeString.contains("2021") || dateTimeString.contains("2020"))
    }

    func testToDateTimeStringCustomFormat() {
        let timestamp: Double = 1609459200
        let dateTimeString = timestamp.toDateTimeString(format: "yyyy-MM-dd HH:mm:ss")

        XCTAssertTrue(dateTimeString.contains(":"))
        XCTAssertTrue(dateTimeString.contains("-"))
    }

    func testToDateTimeStringWithLocale() {
        let timestamp: Double = 1609459200
        let locale = Locale(identifier: "ja_JP")
        let dateTimeString = timestamp.toDateTimeString(locale: locale)

        XCTAssertFalse(dateTimeString.isEmpty)
    }

    func testZeroTimestampToString() {
        let timestamp: Double = 0
        let dateString = timestamp.toDateString()

        XCTAssertFalse(dateString.isEmpty)
    }
}
