//
//  AppLanguageDateFormatTests.swift
//  SwiftJsonUITests
//
//  A SelectBox draws and reads its date text in the app's language on the
//  Gregorian calendar, not in the device locale (ticket
//  selectbox-date-text-formatted-in-the-device-locale). The device locale is
//  stood in for by `fallback` / an explicit Locale: ja_JP@calendar=japanese,
//  a device that draws the imperial year.
//

import XCTest
@testable import SwiftJsonUI

final class AppLanguageDateFormatTests: XCTestCase {

    private let japaneseDevice = Locale(identifier: "ja_JP@calendar=japanese")

    // 2026-10-04 12:00 UTC
    private let date = Date(timeIntervalSince1970: 1_791_115_200)

    private func utc(_ formatter: DateFormatter) -> DateFormatter {
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    // MARK: - which language

    func testTheInAppLanguageWinsOverTheDeviceLocale() {
        let locale = AppLanguageDateFormat.resolve(
            currentLanguage: "en", hasLproj: { $0 == "en" }, preferred: "ja", fallback: japaneseDevice)
        XCTAssertEqual(locale.identifier, "en")
    }

    func testAnInAppLanguageWithoutItsLprojFallsToTheMainBundlesLanguage() {
        // .localized() falls back the same way when the .lproj is missing.
        let locale = AppLanguageDateFormat.resolve(
            currentLanguage: "fr", hasLproj: { _ in false }, preferred: "en", fallback: japaneseDevice)
        XCTAssertEqual(locale.identifier, "en")
    }

    func testTheDeviceLocaleIsTheLastResort() {
        let locale = AppLanguageDateFormat.resolve(
            currentLanguage: nil, hasLproj: { _ in true }, preferred: nil, fallback: japaneseDevice)
        XCTAssertEqual(locale.identifier, japaneseDevice.identifier)
    }

    // MARK: - what it draws

    func testAppEnOnAJapaneseCalendarDeviceDrawsAnEnglishMonthAndTheGregorianYear() {
        let en = AppLanguageDateFormat.resolve(
            currentLanguage: "en", hasLproj: { _ in true }, preferred: "ja", fallback: japaneseDevice)
        let text = utc(AppLanguageDateFormat.formatter("MMM d, yyyy", locale: en)).string(from: date)
        XCTAssertEqual(text, "Oct 4, 2026")

        // Control: the 10.29.4 formatter (no locale) on this device draws
        // a Japanese month and the imperial year.
        let old = DateFormatter()
        old.locale = japaneseDevice
        old.dateFormat = "MMM d, yyyy"
        XCTAssertNotEqual(utc(old).string(from: date), text)
    }

    func testTheCalendarIsGregorianEvenWhenTheDeviceIsTheLastResort() {
        // A numeric pattern on a Japanese-calendar device: the stored value
        // must still read 2026.
        let formatter = utc(AppLanguageDateFormat.formatter("yyyy/MM/dd", locale: japaneseDevice))
        XCTAssertEqual(formatter.string(from: date), "2026/10/04")
        XCTAssertEqual(formatter.calendar.identifier, .gregorian)
    }

    func testTheInternalShapeIsPosixAndGregorian() {
        let formatter = utc(AppLanguageDateFormat.posixFormatter("yyyy-MM-dd"))
        XCTAssertEqual(formatter.locale.identifier, "en_US_POSIX")
        XCTAssertEqual(formatter.calendar.identifier, .gregorian)
        XCTAssertEqual(formatter.date(from: "2026-10-04").map { utc(AppLanguageDateFormat.posixFormatter("yyyy")).string(from: $0) }, "2026")
    }

    // MARK: - the round trip the generated code makes

    func testWhatTheSelectBoxWritesToDateReadsBack() {
        // SelectBoxView writes its text to the bound String; the generated
        // code reads it back with `toDate(format:)`. Both use the app's
        // language now — a month name drawn in one language and parsed in
        // another would come back nil.
        let pattern = "MMM d, yyyy"
        let text = AppLanguageDateFormat.formatter(pattern).string(from: date)
        let back = text.toDate(format: pattern)
        XCTAssertNotNil(back)
        XCTAssertEqual(back.map { AppLanguageDateFormat.formatter(pattern).string(from: $0) }, text)
    }

    // MARK: - every SelectBox formatter goes through the helper

    func testSelectBoxViewAndTheDynamicConverterBuildNoBareDateFormatter() throws {
        var root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while !FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path) {
            let parent = root.deletingLastPathComponent()
            guard parent != root else { throw XCTSkip("the package root is not reachable from #filePath") }
            root = parent
        }
        let files = [
            "Sources/SwiftJsonUI/Classes/SwiftUI/SelectBoxView.swift",
            "Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Converters/SelectBoxConverter.swift",
        ]
        for file in files {
            let source = try String(contentsOf: root.appendingPathComponent(file), encoding: .utf8)
            XCTAssertFalse(source.contains("DateFormatter()"),
                           "\(file) builds a DateFormatter in the device locale — use AppLanguageDateFormat")
        }
    }
}
