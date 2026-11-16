//
//  CollectionScrollMemoryTests.swift
//  SwiftJsonUITests
//
//  The screen's scrollTo memory (kjui-collection-scrollto-ignored-after-
//  visibility-gone, 2026-10-14): a Collection appearing with a value other
//  than the one the screen last saw it with is appearing with a request; the
//  first appearance on a screen, the same value, and a Collection with no id
//  are not. The drawn behaviour (a Collection back from gone with a request,
//  through DynamicView and sjui's generated code) was measured on the
//  ConformanceHost; this pins the rule the modifier reads.
//

import XCTest
@testable import SwiftJsonUI

final class CollectionScrollMemoryTests: XCTestCase {

    func testTheFirstAppearanceOnAScreenIsNoRequest() {
        let memory = CollectionScrollMemory()
        XCTAssertFalse(memory.isRequestOnEntry("list", AnyHashable("E")))
    }

    func testAnotherValueOnTheWayBackIsARequest() {
        let memory = CollectionScrollMemory()
        memory.record("list", AnyHashable(""))
        XCTAssertTrue(memory.isRequestOnEntry("list", AnyHashable("E")))
        XCTAssertFalse(memory.isRequestOnEntry("other", AnyHashable("E")), "by the Collection's id")
    }

    func testTheValueItLeftWithIsNoRequest() {
        let memory = CollectionScrollMemory()
        memory.record("list", AnyHashable("E"))
        XCTAssertFalse(memory.isRequestOnEntry("list", AnyHashable("E")))
    }

    func testAnOptionalValueIsComparedAsTheCollectionHoldsIt() {
        let memory = CollectionScrollMemory()
        let none: String? = nil
        memory.record("list", AnyHashable(none))
        XCTAssertTrue(memory.isRequestOnEntry("list", AnyHashable(Optional("E"))))
        XCTAssertFalse(memory.isRequestOnEntry("list", AnyHashable(none)))
    }

    func testACollectionWithNoIdIsNotRemembered() {
        let memory = CollectionScrollMemory()
        memory.record(nil, AnyHashable(""))
        XCTAssertFalse(memory.isRequestOnEntry(nil, AnyHashable("E")))
    }
}
