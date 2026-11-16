//
//  ScreenMarkerGateTests.swift
//  SwiftJsonUITests
//
//  The screen marker draws in a DEBUG build, or when the app's Info.plist
//  turns com.swiftjsonui.SCREEN_MARKER on, and in nothing else — a shipped
//  app is neither. Until 10.29.9 the gate was `#if DEBUG` alone, so the UI
//  tests could not run on an optimized Release-like configuration (ticket
//  sjui-screenmarker-compiled-out-in-release-blocks-optimized-ui-tests).
//
//  The gate is a pure function of (is this a DEBUG build, the Info.plist
//  value); the value Xcode writes for `$(JSONUI_SCREEN_MARKER)` is a string —
//  "" where the setting is unset, "YES" where it is set (measured, Xcode 27 RC).
//

import XCTest
@testable import SwiftJsonUI

final class ScreenMarkerGateTests: XCTestCase {

    // MARK: - DEBUG x key

    func testAShippedAppDrawsNoMarker() {
        XCTAssertFalse(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: nil))
    }

    func testADebugBuildDraws() {
        XCTAssertTrue(screenMarkerEnabled(isDebugBuild: true, infoPlistValue: nil))
    }

    func testAReleaseLikeBuildThatTurnsTheKeyOnDraws() {
        XCTAssertTrue(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: "YES"))
    }

    func testADebugBuildThatAlsoTurnsTheKeyOnDraws() {
        XCTAssertTrue(screenMarkerEnabled(isDebugBuild: true, infoPlistValue: "YES"))
    }

    // MARK: - The value's boundaries (a Release build, so only the key decides)

    func testWhatReleaseWritesWhenTheSettingIsUnsetIsOff() {
        // `$(JSONUI_SCREEN_MARKER)` with the setting unset expands to "".
        XCTAssertFalse(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: ""))
    }

    func testNoAndOtherWordsAreOff() {
        for value in ["NO", "no", "0", "false", "FALSE", "on", "2", " "] {
            XCTAssertFalse(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: value), "\(value.debugDescription)")
        }
    }

    func testYesTrueAndOneAreOnInAnyCase() {
        for value in ["YES", "yes", "Yes", " YES ", "TRUE", "true", "1"] {
            XCTAssertTrue(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: value), "\(value.debugDescription)")
        }
    }

    func testAPlistBooleanOrNumberIsReadAsItsTruth() {
        XCTAssertTrue(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: true))
        XCTAssertFalse(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: false))
        XCTAssertTrue(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: NSNumber(value: 1)))
        XCTAssertFalse(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: NSNumber(value: 0)))
    }

    func testAnotherTypeIsOff() {
        XCTAssertFalse(screenMarkerEnabled(isDebugBuild: false, infoPlistValue: ["YES"]))
    }

    // MARK: - The spelling

    /// The key is written in the code and in the consumer document; the two agree.
    func testTheDocumentNamesTheKeyTheCodeReads() throws {
        XCTAssertEqual(screenMarkerInfoPlistKey, "com.swiftjsonui.SCREEN_MARKER")
        var root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while !FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path) {
            let parent = root.deletingLastPathComponent()
            // Not a skip: a check that cannot find its file must not pass.
            guard parent != root else { return XCTFail("the package root is not reachable from #filePath") }
            root = parent
        }
        let doc = root.appendingPathComponent("Docs/ui-tests-on-release-builds.md")
        let text = try String(contentsOf: doc, encoding: .utf8)
        XCTAssertTrue(text.contains("<key>\(screenMarkerInfoPlistKey)</key>"),
                      "\(doc.path) does not name <key>\(screenMarkerInfoPlistKey)</key>")
    }
}
