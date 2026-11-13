//
//  CollectionReorderAccessibilityTests.swift
//  SwiftJsonUITests
//
//  A reorderable Collection's rows carry "Move up" / "Move down" for VoiceOver (ticket
//  jui-collection-drag-to-reorder). The rows apply CollectionReorderAccessibility.actions as it stands (one
//  accessibilityActions block, no condition of its own); this reads that list — the names VoiceOver shows and the
//  move each one reports. XCUITest cannot perform a custom action, and a test process builds no SwiftUI
//  accessibility tree without an assistive technology running.
//

import XCTest
@testable import SwiftJsonUI

@MainActor
final class CollectionReorderAccessibilityTests: XCTestCase {

    private var reported: [String] = []

    private func actions(_ index: Int, count: Int = 4, locked: Set<Int>, enabled: Bool = true)
        -> [CollectionReorderAccessibility.Action] {
        let reorder = CollectionReorder(isEnabled: enabled) { [weak self] section, from, to in
            self?.reported.append("\(section):\(from)->\(to)")
        }
        return CollectionReorderAccessibility.actions(section: 1, index: index, count: count, locked: locked, reorder: reorder)
    }

    func testEachRowOffersTheMovesTheRuleAllows() {
        let up = CollectionReorderText.moveUp, down = CollectionReorderText.moveDown
        XCTAssertEqual(actions(0, locked: []).map(\.name), [down], "the first row has no up")
        XCTAssertEqual(actions(1, locked: []).map(\.name), [up, down])
        XCTAssertEqual(actions(3, locked: []).map(\.name), [up], "the last row has no down")
        XCTAssertEqual(actions(1, locked: [2]).map(\.name), [up], "the row below is locked")
        XCTAssertEqual(actions(3, locked: [2]).map(\.name), [], "the row above is locked and it is the last")
        XCTAssertEqual(actions(2, locked: [2]).map(\.name), [], "a locked row")
    }

    func testPerformingAMoveReportsIt() {
        reported = []
        actions(0, locked: []).first?.perform()
        actions(2, locked: []).first?.perform()
        XCTAssertEqual(reported, ["1:0->1", "1:2->1"])
    }

    func testAMoveIsNotReportedWhileReorderingIsOff() {
        reported = []
        actions(1, locked: [], enabled: false).forEach { $0.perform() }
        XCTAssertEqual(reported, [])
    }

    /// iOS 27's container is used only for a Collection with neither a handle nor locked rows; the library's drag
    /// otherwise, on every iOS.
    func testThePathFollowsTheDeclaration() {
        let plain = CollectionReorder(isEnabled: true) { _, _, _ in }
        let handle = CollectionReorder(isEnabled: true, usesHandle: true) { _, _, _ in }
        let locked = CollectionReorder(isEnabled: true, hasLockedRows: true) { _, _, _ in }
        if #available(iOS 27.0, *) {
            XCTAssertTrue(plain.usesSystemContainer)
        } else {
            XCTAssertFalse(plain.usesSystemContainer)
        }
        XCTAssertFalse(handle.usesSystemContainer)
        XCTAssertFalse(locked.usesSystemContainer)
    }

    func testTheWordsFollowTheLanguage() {
        XCTAssertTrue(["上へ移動", "Move up"].contains(CollectionReorderText.moveUp))
        XCTAssertTrue(["下へ移動", "Move down"].contains(CollectionReorderText.moveDown))
    }
}
