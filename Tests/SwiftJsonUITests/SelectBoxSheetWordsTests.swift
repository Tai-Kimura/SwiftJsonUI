//
//  SelectBoxSheetWordsTests.swift
//  The word on SelectBoxView's Done button (jsonui-cli ticket kjui-selectbox-hardcoded-japanese-strings).
//

import XCTest
@testable import SwiftJsonUI

final class SelectBoxSheetWordsTests: XCTestCase {

    private func word(given: String? = nil, appWord: String = "Done", _ language: String) -> String {
        SelectBoxSheetWords.done(given: given, appWord: appWord, language: language)
    }

    func testTheLayoutsWordComesFirst() {
        XCTAssertEqual(word(given: "Apply", appWord: "完了(上書き)", "ja"), "Apply")
    }

    func testAnEmptyLayoutWordIsNoWord() {
        XCTAssertEqual(word(given: "", "ja"), "完了")
    }

    /// Button("Done") looked this key up: an app that set it keeps its word.
    func testTheAppsOwnDoneComesBeforeTheTable() {
        XCTAssertEqual(word(appWord: "完了(上書き)", "ja"), "完了(上書き)")
    }

    func testTheTableFollowsTheAppsLanguage() {
        XCTAssertEqual(word("en"), "Done")
        XCTAssertEqual(word("ja"), "完了")
        XCTAssertEqual(word("de"), "Fertig")
        XCTAssertEqual(word("ko"), "완료")
        XCTAssertEqual(word("cs"), "Hotovo")
    }

    func testAScriptOrARegionFindsItsSpelling() {
        for traditional in ["zh-Hant", "zh-TW", "zh_TW", "zh-HK", "zh-MO", "zh-Hant-HK"] {
            XCTAssertEqual(SelectBoxSheetWords.tableKey(traditional), "zh-Hant", traditional)
        }
        for simplified in ["zh-Hans", "zh-CN", "zh", "zh-SG", "zh-Hans-CN"] {
            XCTAssertEqual(SelectBoxSheetWords.tableKey(simplified), "zh-Hans", simplified)
        }
        XCTAssertEqual(SelectBoxSheetWords.tableKey("es-419"), "es-419")
        XCTAssertEqual(SelectBoxSheetWords.tableKey("es-MX"), "es-419")
        XCTAssertEqual(SelectBoxSheetWords.tableKey("es-ES"), "es")
        XCTAssertEqual(SelectBoxSheetWords.tableKey("es"), "es")
        XCTAssertEqual(SelectBoxSheetWords.tableKey("pt-PT"), "pt-PT")
        XCTAssertEqual(SelectBoxSheetWords.tableKey("pt-BR"), "pt")
        XCTAssertEqual(SelectBoxSheetWords.tableKey("en-GB"), "en")
        XCTAssertEqual(word("es-MX"), "Listo")
    }

    func testALanguageTheTableLacksIsEnglish() {
        XCTAssertEqual(word("th"), "Done")
    }

    func testTheFifteenLanguagesAreThere() {
        XCTAssertEqual(Set(SelectBoxSheetWords.done.keys), [
            "en", "ja", "de", "fr", "nl", "da", "pl", "cs", "es-419", "es", "pt", "pt-PT", "zh-Hant", "zh-Hans", "ko",
        ])
    }
}
