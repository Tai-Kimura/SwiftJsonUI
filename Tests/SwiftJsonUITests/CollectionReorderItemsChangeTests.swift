//
//  CollectionReorderItemsChangeTests.swift
//  SwiftJsonUITests
//
//  The rows changing under a drag (rule.itemsChange; ticket jui-collection-reorder-start-callback-missing): the
//  library's drag reads the rows (ids, locked, fixed) when it is picked up, and the rows as configure last drew them
//  when it is let go. A change of ids (number or order), of the locked rows or of the fixed rows cancels it — nothing
//  is reported, since its indexes would name other rows; the text alone rebuilt does not. The drag is driven as the
//  recognizer drives it (begin, move, end), over rows laid out 64 pt apart.
//

import XCTest
@testable import SwiftJsonUI

@MainActor
final class CollectionReorderItemsChangeTests: XCTestCase {
    private var reported: [String] = []

    private func drag(ids: [String], locked: Set<Int> = [], fixed: Set<Int> = []) -> (CollectionReorderDrag, CollectionReorder) {
        let reorder = CollectionReorder(isEnabled: true) { [weak self] s, f, t in self?.reported.append("\(s):\(f)->\(t)") }
        let drag = CollectionReorderDrag()
        drag.configure(section: 0, ids: ids, locked: locked, fixed: fixed, reorder: reorder, registry: nil)
        for i in ids.indices { drag.frames[i] = CGRect(x: 0, y: CGFloat(i) * 64, width: 320, height: 64) }
        return (drag, reorder)
    }

    /// Pick row 1 up, move it 2.2 rows down, let [rebuild] redraw the rows halfway, and let go.
    private func run(_ ids: [String], locked: Set<Int> = [], rebuild: (CollectionReorderDrag, CollectionReorder) -> Void) {
        reported = []
        let (drag, reorder) = drag(ids: ids, locked: locked)
        drag.begin(index: 1, at: 96, count: ids.count)
        drag.move(to: 96 + 64)
        rebuild(drag, reorder)
        drag.move(to: 96 + 64 * 2.2)
        drag.end(cancelled: false)
        XCTAssertNil(drag.dragging)
        XCTAssertNil(drag.started)
    }

    private let rows = ["a", "b", "c", "d", "e", "f"]

    func testNothingChangedCommits() {
        run(rows) { _, _ in }
        XCTAssertEqual(reported, ["0:1->3"])
    }

    func testTheTextAloneRebuiltCommits() {
        run(rows) { d, r in d.configure(section: 0, ids: rows, locked: [], fixed: [], reorder: r, registry: nil) }
        XCTAssertEqual(reported, ["0:1->3"])
    }

    func testARowRemovedBelowCancels() {
        run(rows) { d, r in d.configure(section: 0, ids: ["a", "b", "c", "d", "f"], locked: [], fixed: [], reorder: r, registry: nil) }
        XCTAssertEqual(reported, [])
    }

    func testARowAddedAboveCancels() {
        run(rows) { d, r in d.configure(section: 0, ids: ["new"] + rows, locked: [], fixed: [], reorder: r, registry: nil) }
        XCTAssertEqual(reported, [])
    }

    func testARowLockedCancels() {
        run(rows) { d, r in d.configure(section: 0, ids: rows, locked: [5], fixed: [], reorder: r, registry: nil) }
        XCTAssertEqual(reported, [])
    }

    func testARowsHandleGoneCancels() {
        run(rows) { d, r in d.configure(section: 0, ids: rows, locked: [], fixed: [4], reorder: r, registry: nil) }
        XCTAssertEqual(reported, [])
    }
}
