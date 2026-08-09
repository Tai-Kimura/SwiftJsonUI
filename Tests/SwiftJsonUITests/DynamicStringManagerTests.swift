//
//  DynamicStringManagerTests.swift
//  SwiftJsonUITests
//
//  Pins the localize() resolution order: declared-key membership wins over
//  the value reverse-lookup and over any spelling heuristic. The extractor
//  truncates long ASCII text to 31 chars, which can leave a trailing
//  underscore ("dont_have_an_account_apply_for_") — a spelling the old
//  snake_case gate rejected, while a legacy poison entry whose VALUE is that
//  raw key hijacked the value lookup, so the dynamic face rendered the key
//  itself (a downstream login screen, 2026-08-09).
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
                "dont_have_an_account_apply_for_": [
                    "en": "Don't have an account? Apply for Membership",
                    "ja": "アカウントをお持ちでない方は会員登録"
                ],
                // Legacy poison: a key whose value IS the other key's spelling.
                "dont_have_an_account_apply_for": "dont_have_an_account_apply_for_",
                "email_address": "Email address",
                "apply_for_membership": [
                    "en": "Apply for Membership",
                    "ja": "会員登録"
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
            "dont_have_an_account_apply_for_".dynamicLocalized(),
            "login_dont_have_an_account_apply_for_"
        )
    }

    func testKeyMembershipWinsOverPoisonedValueLookup() {
        // The poison entry maps the VALUE "dont_have_an_account_apply_for_"
        // to "login_dont_have_an_account_apply_for" (no trailing underscore).
        // Key-first ordering must pick the declared key instead.
        let resolved = "dont_have_an_account_apply_for_".dynamicLocalized()
        XCTAssertNotEqual(resolved, "login_dont_have_an_account_apply_for")
        XCTAssertEqual(resolved, "login_dont_have_an_account_apply_for_")
    }

    func testValueLookupStillResolvesDisplayText() {
        XCTAssertEqual(
            "Email address".dynamicLocalized(),
            "login_email_address"
        )
    }

    func testDeclaredPlainSnakeCaseKeyResolves() {
        XCTAssertEqual(
            "apply_for_membership".dynamicLocalized(),
            "login_apply_for_membership"
        )
    }

    func testNonKeyTextPassesThrough() {
        XCTAssertEqual("Hello World".dynamicLocalized(), "Hello World")
    }

    // A bare key declared in several sections resolves through the section
    // the RENDERING layout owns — flat iteration order picked one by chance
    // (a downstream app: home.open=営業中 vs store_info.open=開店, the home tab
    // rendered 開店 on the dynamic face, 2026-08-10).
    func testOwnSectionWinsForCollidingBareKey() {
        DynamicStringManager.shared.loadStrings(fromParsed: [
            "home": ["open": ["en": "Open", "ja": "営業中"]],
            "store_info": ["open": ["en": "Open", "ja": "開店"]]
        ])
        DynamicStringManager.shared.beginLayout("home")
        XCTAssertEqual("open".dynamicLocalized(), "home_open")
        DynamicStringManager.shared.beginLayout("store_info")
        XCTAssertEqual("open".dynamicLocalized(), "store_info_open")
    }

    func testFlatFallbackStillResolvesForeignKeys() {
        DynamicStringManager.shared.loadStrings(fromParsed: [
            "home": ["open": ["en": "Open", "ja": "営業中"]],
            "settings": ["logout": ["en": "Log out", "ja": "ログアウト"]]
        ])
        // home renders a key it does not own — the flat map still answers.
        DynamicStringManager.shared.beginLayout("home")
        XCTAssertEqual("logout".dynamicLocalized(), "settings_logout")
    }

    func testOwnSectionValueLookupWins() {
        DynamicStringManager.shared.loadStrings(fromParsed: [
            "home": ["open": "Open"],
            "store_info": ["open_hours": "Open"]
        ])
        DynamicStringManager.shared.beginLayout("home")
        XCTAssertEqual("Open".dynamicLocalized(), "home_open")
    }
}
#endif
