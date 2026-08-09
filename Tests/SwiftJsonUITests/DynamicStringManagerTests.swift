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
}
#endif
