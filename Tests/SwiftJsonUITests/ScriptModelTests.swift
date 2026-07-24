//
//  ScriptModelTests.swift
//  SwiftJsonUI
//

import XCTest
@testable import SwiftJsonUI

final class ScriptModelTests: XCTestCase {

    // MARK: - ScriptModel Tests

    func testScriptModelInitialization() {
        let scriptModel = ScriptModel(type: .string, value: "test script")
        XCTAssertEqual(scriptModel.type, .string)
        XCTAssertEqual(scriptModel.value, "test script")
    }

    func testScriptModelFileType() {
        let scriptModel = ScriptModel(type: .file, value: "script.js")
        XCTAssertEqual(scriptModel.type, .file)
        XCTAssertEqual(scriptModel.value, "script.js")
    }

    // MARK: - ScriptType Tests

    func testScriptTypeStringRawValue() {
        XCTAssertEqual(ScriptModel.ScriptType.string.rawValue, "string")
    }

    func testScriptTypeFileRawValue() {
        XCTAssertEqual(ScriptModel.ScriptType.file.rawValue, "file")
    }

    func testScriptTypeFromRawValue() {
        XCTAssertEqual(ScriptModel.ScriptType(rawValue: "string"), .string)
        XCTAssertEqual(ScriptModel.ScriptType(rawValue: "file"), .file)
        XCTAssertNil(ScriptModel.ScriptType(rawValue: "invalid"))
    }

    // MARK: - EventType Tests

    func testEventTypeOnClickRawValue() {
        XCTAssertEqual(ScriptModel.EventType.onclick.rawValue, "onclick")
    }

    func testEventTypeOnLongTapRawValue() {
        XCTAssertEqual(ScriptModel.EventType.onlongtap.rawValue, "onlongtap")
    }

    func testEventTypePanRawValue() {
        XCTAssertEqual(ScriptModel.EventType.pan.rawValue, "pan")
    }

    func testEventTypeSwipeRawValue() {
        XCTAssertEqual(ScriptModel.EventType.swipe.rawValue, "swipe")
    }

    func testEventTypeRotateRawValue() {
        XCTAssertEqual(ScriptModel.EventType.rotate.rawValue, "rotate")
    }

    func testEventTypeScrollRawValue() {
        XCTAssertEqual(ScriptModel.EventType.scroll.rawValue, "scroll")
    }

    func testEventTypeFromRawValue() {
        XCTAssertEqual(ScriptModel.EventType(rawValue: "onclick"), .onclick)
        XCTAssertEqual(ScriptModel.EventType(rawValue: "onlongtap"), .onlongtap)
        XCTAssertEqual(ScriptModel.EventType(rawValue: "pan"), .pan)
        XCTAssertEqual(ScriptModel.EventType(rawValue: "swipe"), .swipe)
        XCTAssertEqual(ScriptModel.EventType(rawValue: "rotate"), .rotate)
        XCTAssertEqual(ScriptModel.EventType(rawValue: "scroll"), .scroll)
        XCTAssertNil(ScriptModel.EventType(rawValue: "invalid"))
    }

    func testAllEventTypes() {
        let eventTypes: [ScriptModel.EventType] = [
            .onclick, .onlongtap, .pan, .swipe, .rotate, .scroll
        ]

        XCTAssertEqual(eventTypes.count, 6)

        for eventType in eventTypes {
            XCTAssertNotNil(ScriptModel.EventType(rawValue: eventType.rawValue))
        }
    }
}
