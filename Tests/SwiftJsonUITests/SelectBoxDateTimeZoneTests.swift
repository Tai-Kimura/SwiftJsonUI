//
//  SelectBoxDateTimeZoneTests.swift
//  SwiftJsonUITests
//
//  A date SelectBox keeps its day in every time zone (ticket
//  2026-11-24-kjui-dateselectbox-calendar-shifts-the-day-by-the-time-zone:
//  KotlinJsonUI's calendar moved the day by the zone). On iOS the value string
//  is read, shown in the DatePicker, and written back in the one zone the
//  device is in — the Dynamic path reads it with
//  AppLanguageDateFormat.posixFormatter, generated code with String.toDate,
//  both write it with AppLanguageDateFormat.formatter, and SwiftUI's
//  DatePicker shows and picks days in Calendar.current. These arms pin that:
//  run them with the simulator's process in Asia/Tokyo and in
//  America/Los_Angeles (TEST_RUNNER_TZ; TEST_RUNNER_JUI_EXPECT_TZ makes the
//  run say which zone it was in, so a run that did not get the zone fails).
//

import XCTest
@testable import SwiftJsonUI

final class SelectBoxDateTimeZoneTests: XCTestCase {

    private let value = "2025-11-24"

    /// The day SwiftUI's DatePicker shows for a date: Calendar.current's.
    private func shownDay(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: date)
    }

    func testTheRunIsInTheZoneItWasAskedFor() {
        guard let expected = ProcessInfo.processInfo.environment["JUI_EXPECT_TZ"] else { return }
        XCTAssertEqual(TimeZone.current.identifier, expected)
    }

    func testTheDynamicPathShowsAndWritesBackTheSameDay() throws {
        let date = try XCTUnwrap(AppLanguageDateFormat.posixFormatter("yyyy-MM-dd").date(from: value))
        let day = shownDay(date)
        XCTAssertEqual([day.year, day.month, day.day], [2025, 11, 24], "zone \(TimeZone.current.identifier)")
        XCTAssertEqual(AppLanguageDateFormat.formatter("yyyy-MM-dd").string(from: date), value)
    }

    func testGeneratedCodeShowsAndWritesBackTheSameDay() throws {
        let date = try XCTUnwrap(value.toDate(format: "yyyy-MM-dd"))
        let day = shownDay(date)
        XCTAssertEqual([day.year, day.month, day.day], [2025, 11, 24], "zone \(TimeZone.current.identifier)")
        XCTAssertEqual(AppLanguageDateFormat.formatter("yyyy-MM-dd").string(from: date), value)
    }

    func testAPickedDayIsWrittenAsThatDay() throws {
        // What the DatePicker hands back for a pressed day: that day in Calendar.current, at the time of day the
        // selection had (00:00 here, as parsed).
        let opened = try XCTUnwrap(AppLanguageDateFormat.posixFormatter("yyyy-MM-dd").date(from: value))
        var parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: opened)
        parts.day = 12
        let picked = try XCTUnwrap(Calendar.current.date(from: parts))
        XCTAssertEqual(AppLanguageDateFormat.formatter("yyyy-MM-dd").string(from: picked), "2025-11-12")
    }
}
