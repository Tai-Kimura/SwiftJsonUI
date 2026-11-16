//
//  CollectionReorderCallbackVectorTests.swift
//  SwiftJsonUITests
//
//  onReorderStart / onReorderEnd (shared/core/reorder_vectors.json rule.callbacks; ticket
//  jui-collection-reorder-start-callback-missing): every `callbacks` case is driven through the library's drag as the
//  recognizer drives it (pick-up test, begin, move, end) or through the row's screen reader action, and the calls
//  are recorded in order — ["start", section, index], ["reorder", section, from, to], ["end", section].
//

import XCTest
@testable import SwiftJsonUI

@MainActor
final class CollectionReorderCallbackVectorTests: XCTestCase {
    private var events: [[AnyHashable]] = []
    private let ids = ["a", "b", "c", "d"]
    private let rowHeight: CGFloat = 64

    private func cases() throws -> [[String: Any]] {
        let data = try TestFixtures.loadJSON(named: "reorder_vectors")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(json["callbacks"] as? [[String: Any]])
    }

    private func reorder() -> CollectionReorder {
        CollectionReorder(isEnabled: true,
                          onReorderStart: { [weak self] s, i in self?.events.append(["start", s, i]) },
                          onReorderEnd: { [weak self] s in self?.events.append(["end", s]) }) { [weak self] s, f, t in
            self?.events.append(["reorder", s, f, t])
        }
    }

    private func configured(_ drag: CollectionReorderDrag, ids: [String], locked: Set<Int>, reorder: CollectionReorder) {
        drag.configure(section: 0, ids: ids, locked: locked, fixed: [], reorder: reorder, registry: nil)
        for i in ids.indices { drag.frames[i] = CGRect(x: 0, y: CGFloat(i) * rowHeight, width: 320, height: rowHeight) }
    }

    private func run(_ c: [String: Any]) {
        events = []
        let from = c["from"] as! Int
        let locked = Set((c["locked"] as? [Int]) ?? [])
        let r = reorder()
        if (c["how"] as? String) == "a11y" {
            let up = (c["action"] as? String) == "up"
            let actions = CollectionReorderAccessibility.actions(section: 0, index: from, count: ids.count, locked: locked,
                                                                 fixed: [], reorder: r)
            let name = up ? CollectionReorderText.moveUp : CollectionReorderText.moveDown
            actions.first { $0.name == name }?.perform()
            return
        }
        let drag = CollectionReorderDrag()
        configured(drag, ids: ids, locked: locked, reorder: r)
        let y = CGFloat(from) * rowHeight + rowHeight / 2
        // Picked up as the recognizer picks up: only where the pick-up test finds a row.
        guard let index = drag.pickable(CGPoint(x: 160, y: y)) else { return }
        drag.begin(index: index, at: y, count: ids.count)
        switch c["cancelled"] as? String {
        case "outside":
            drag.move(to: 2_000)
        case "itemsChange":
            drag.move(to: y + rowHeight * 1.3)
            configured(drag, ids: ["new"] + ids.dropLast(), locked: locked, reorder: r)
        default:
            let to = c["to"] as! Int
            // Into the target row, clear of every edge and centre: the same place under the centre and edge rules.
            let rows = CGFloat(to - from)
            drag.move(to: y + (rows == 0 ? 0 : rowHeight * (rows + (rows > 0 ? 0.3 : -0.3))))
        }
        drag.end(cancelled: false)
    }

    func testEveryCallbacksCase() throws {
        let all = try cases()
        XCTAssertEqual(all.count, 7)
        for c in all {
            run(c)
            let want = (c["events"] as? [[Any]] ?? []).map { $0.map { $0 as! AnyHashable } }
            XCTAssertEqual(events, want, "\(c["name"] ?? "")")
        }
    }

    /// Without the two handlers nothing changes: onReorder alone, as before.
    func testWithoutCallbacksOnlyOnReorder() {
        events = []
        let r = CollectionReorder(isEnabled: true) { [weak self] s, f, t in self?.events.append(["reorder", s, f, t]) }
        let drag = CollectionReorderDrag()
        configured(drag, ids: ids, locked: [], reorder: r)
        drag.begin(index: 1, at: 96, count: ids.count)
        drag.move(to: 96 + rowHeight * 2.3)
        drag.end(cancelled: false)
        XCTAssertEqual(events, [["reorder", 0, 1, 3]])
    }

    #if DEBUG
    /// Dynamic reads both handlers by name from the data, as it reads onReorder.
    func testDynamicReadsBothHandlers() throws {
        let json = #"{"type": "Collection", "id": "c", "reorderable": true, "onReorder": "@{move}", "onReorderStart": "@{began}", "onReorderEnd": "@{ended}"}"#
        let component = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        var calls: [String] = []
        let data: [String: Any] = [
            "move": { (s: Int, f: Int, t: Int) in calls.append("move \(s) \(f) \(t)") } as (Int, Int, Int) -> Void,
            "began": { (s: Int, i: Int) in calls.append("began \(s) \(i)") } as (Int, Int) -> Void,
            "ended": { (s: Int) in calls.append("ended \(s)") } as (Int) -> Void,
        ]
        let r = try XCTUnwrap(CollectionConverter.reorder(component: component, data: data))
        XCTAssertTrue(r.hasCallbacks)
        XCTAssertFalse(r.usesSystemContainer)
        r.step(section: 0, index: 2) { r.report(section: 0, from: 2, to: 1, count: 4, locked: []) }
        XCTAssertEqual(calls, ["began 0 2", "move 0 2 1", "ended 0"])
    }
    #endif

    /// Declared, the stack keeps the library's drag on iOS 27 too: the system container has no pick-up hook.
    func testCallbacksKeepTheLibrarysDrag() {
        let plain = CollectionReorder(isEnabled: true) { _, _, _ in }
        let withStart = CollectionReorder(isEnabled: true, onReorderStart: { _, _ in }) { _, _, _ in }
        let withEnd = CollectionReorder(isEnabled: true, onReorderEnd: { _ in }) { _, _, _ in }
        XCTAssertFalse(withStart.usesSystemContainer)
        XCTAssertFalse(withEnd.usesSystemContainer)
        if CollectionReorder.systemContainerIsCompiled, #available(iOS 27.0, *) {
            XCTAssertTrue(plain.usesSystemContainer, "control: without them iOS 27 uses its container")
        }
    }
}
