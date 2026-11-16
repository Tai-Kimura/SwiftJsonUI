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

    private func actions(_ index: Int, count: Int = 4, locked: Set<Int>, fixed: Set<Int> = [], enabled: Bool = true)
        -> [CollectionReorderAccessibility.Action] {
        let reorder = CollectionReorder(isEnabled: enabled) { [weak self] section, from, to in
            self?.reported.append("\(section):\(from)->\(to)")
        }
        return CollectionReorderAccessibility.actions(section: 1, index: index, count: count, locked: locked,
                                                      fixed: fixed, reorder: reorder)
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

    /// A fixed row (reorderFixedProperty, or a handle that is not drawn) has neither action, and is passed: the rows
    /// next to it keep theirs, and a move past it is reported (ticket jui-collection-reorder-fixed-row-vs-barrier-row).
    func testAFixedRowHasNoActionAndIsPassed() {
        let up = CollectionReorderText.moveUp, down = CollectionReorderText.moveDown
        XCTAssertEqual(actions(2, locked: [], fixed: [2]).map(\.name), [], "a fixed row")
        XCTAssertEqual(actions(1, locked: [], fixed: [2]).map(\.name), [up, down], "the row above a fixed one")
        XCTAssertEqual(actions(3, locked: [], fixed: [2]).map(\.name), [up], "the row below a fixed one")
        XCTAssertEqual(actions(2, locked: [2], fixed: [2]).map(\.name), [], "locked and fixed: locked")
        reported = []
        actions(1, locked: [], fixed: [2]).last?.perform()
        XCTAssertEqual(reported, ["1:1->2"], "moved past the fixed row")
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

    /// iOS 27's container is used only for a Collection with neither a handle nor locked rows, and only in a build
    /// against the iOS 27 SDK; the library's drag otherwise, on every iOS.
    func testThePathFollowsTheDeclaration() {
        let plain = CollectionReorder(isEnabled: true) { _, _, _ in }
        let handle = CollectionReorder(isEnabled: true, usesHandle: true) { _, _, _ in }
        let locked = CollectionReorder(isEnabled: true, hasLockedRows: true) { _, _, _ in }
        let fixed = CollectionReorder(isEnabled: true, hasFixedRows: true) { _, _, _ in }
        if #available(iOS 27.0, *), CollectionReorder.systemContainerIsCompiled {
            XCTAssertTrue(plain.usesSystemContainer)
        } else {
            XCTAssertFalse(plain.usesSystemContainer)
        }
        XCTAssertFalse(handle.usesSystemContainer)
        XCTAssertFalse(locked.usesSystemContainer)
        XCTAssertFalse(fixed.usesSystemContainer)
    }

    /// The build against the iOS 27 SDK (SwiftUI 8) has the container; one against an older SDK has none of it.
    func testTheContainerIsCompiledOnlyAgainstTheIOS27SDK() {
        #if canImport(SwiftUI, _version: 8.0)
        XCTAssertTrue(CollectionReorder.systemContainerIsCompiled)
        #else
        XCTAssertFalse(CollectionReorder.systemContainerIsCompiled)
        #endif
    }

    /// The app's Localizable jsonui_reorder_move_up / _down name the actions when it has them; a key it does not
    /// have falls back to the library's words.
    func testTheAppsWordsComeFirst() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("reorder-words-\(UUID().uuidString)")
        let lproj = dir.appendingPathComponent("en.lproj")
        try FileManager.default.createDirectory(at: lproj, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try "\"jsonui_reorder_move_up\" = \"Nach oben\";\n".write(to: lproj.appendingPathComponent("Localizable.strings"),
                                                                atomically: true, encoding: .utf8)
        let bundle = try XCTUnwrap(Bundle(path: lproj.path))
        XCTAssertEqual(CollectionReorderText.appWord("jsonui_reorder_move_up", in: bundle), "Nach oben")
        XCTAssertNil(CollectionReorderText.appWord("jsonui_reorder_move_down", in: bundle))
        XCTAssertNil(CollectionReorderText.appWord("jsonui_reorder_move_up"), "the test host has no such key")
    }

    func testTheWordsFollowTheLanguage() {
        XCTAssertTrue(["上へ移動", "Move up"].contains(CollectionReorderText.moveUp))
        XCTAssertTrue(["下へ移動", "Move down"].contains(CollectionReorderText.moveDown))
    }
}
