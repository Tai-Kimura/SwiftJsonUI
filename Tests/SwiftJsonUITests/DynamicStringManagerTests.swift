//
//  DynamicStringManagerTests.swift
//  SwiftJsonUITests
//
//  Pins the localize() resolution order: declared-key membership wins over
//  the value reverse-lookup and over any spelling heuristic. The extractor
//  truncates long ASCII text to 31 chars, which can leave a trailing
//  underscore ("foo_bar_") — a spelling the old
//  snake_case gate rejected, while a legacy poison entry whose VALUE is that
//  raw key hijacked the value lookup, so the dynamic face rendered the key
//  itself (a downstream app's login screen, 2026-08-09).
//
//  In the test host there is no Localizable.strings, so `.localized()`
//  passes the key through — asserting the PREFIXED key spelling proves
//  which mapping won without needing a string table.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class DynamicStringManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DynamicStringManager.shared.loadStrings(fromParsed: [
            "login": [
                "foo_bar_": [
                    "en": "Foo bar",
                    "ja": "あいうえ"
                ],
                // Legacy poison: a key whose value IS the other key's spelling.
                "foo_bar": "foo_bar_",
                "email_address": "Email address",
                "foo_baz": [
                    "en": "Foo baz",
                    "ja": "かきく"
                ]
            ]
        ])
    }

    override func tearDown() {
        DynamicStringManager.shared.reload()
        super.tearDown()
    }

    func testDeclaredTrailingUnderscoreKeyResolvesAsKey() {
        XCTAssertEqual(
            "foo_bar_".dynamicLocalized(),
            "login_foo_bar_"
        )
    }

    func testKeyMembershipWinsOverPoisonedValueLookup() {
        // The poison entry maps the VALUE "foo_bar_"
        // to "login_foo_bar" (no trailing underscore).
        // Key-first ordering must pick the declared key instead.
        let resolved = "foo_bar_".dynamicLocalized()
        XCTAssertNotEqual(resolved, "login_foo_bar")
        XCTAssertEqual(resolved, "login_foo_bar_")
    }

    func testValueLookupStillResolvesDisplayText() {
        XCTAssertEqual(
            "Email address".dynamicLocalized(),
            "login_email_address"
        )
    }

    func testDeclaredPlainSnakeCaseKeyResolves() {
        XCTAssertEqual(
            "foo_baz".dynamicLocalized(),
            "login_foo_baz"
        )
    }

    func testNonKeyTextPassesThrough() {
        XCTAssertEqual("Hello World".dynamicLocalized(), "Hello World")
    }

    // A bare key declared in several sections resolves through the section
    // the RENDERING layout owns — flat iteration order picked one by chance
    // (a downstream app: home.open="A" vs info.open="B", the home tab
    // rendered "B" on the dynamic face, 2026-08-10).
    func testOwnSectionWinsForCollidingBareKey() {
        DynamicStringManager.shared.loadStrings(fromParsed: [
            "home": ["open": ["en": "Open", "ja": "A"]],
            "info": ["open": ["en": "Open", "ja": "B"]]
        ])
        DynamicStringManager.shared.beginLayout("home")
        XCTAssertEqual("open".dynamicLocalized(), "home_open")
        DynamicStringManager.shared.beginLayout("info")
        XCTAssertEqual("open".dynamicLocalized(), "info_open")
    }

    func testFlatFallbackStillResolvesForeignKeys() {
        DynamicStringManager.shared.loadStrings(fromParsed: [
            "home": ["open": ["en": "Open", "ja": "A"]],
            "settings": ["logout": ["en": "Log out", "ja": "C"]]
        ])
        // home renders a key it does not own — the flat map still answers.
        DynamicStringManager.shared.beginLayout("home")
        XCTAssertEqual("logout".dynamicLocalized(), "settings_logout")
    }

    func testOwnSectionValueLookupWins() {
        DynamicStringManager.shared.loadStrings(fromParsed: [
            "home": ["open": "Open"],
            "info": ["open_hours": "Open"]
        ])
        DynamicStringManager.shared.beginLayout("home")
        XCTAssertEqual("Open".dynamicLocalized(), "home_open")
    }
}
#endif
