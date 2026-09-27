//
//  CollectionScrollTargetResolutionTests.swift
//  SwiftJsonUITests
//
//  What a Dynamic Collection's scrollTo names across sections (4f ruling
//  2026-09-27; jsonui-cli 1.9.0, the SSoT's Collection.scrollTo): an Int is a
//  CELL counted across the drawn sections in section order — a header or a
//  footer is not a cell; a String (cellIdProperty) is the first cell, in
//  section order, whose key it is. The resolver answers the id of that
//  cell (identifiedItems, 4f round 14): its key qualified by its section
//  when no earlier cell of the section has it, else its place — so no two
//  cells answer one id, a cell with no key answers no String, and a key two
//  cells of one section share is the first's.
//
//  Until round 14 the ids were Strings — the key, else "\(index)", with
//  "<section>:" after section 0 — so a cell with no key at 3 and a cell
//  keyed "3" were one id, as two cells of one section with one key were.
//
//  Until 1.9.0 the value went to ScrollViewProxy as it was: an Int named no
//  cell (the cells' ids are Strings; it named the section of that number, the
//  outer ForEach's id) and a key two sections share named whichever view
//  SwiftUI found. The scroll itself is drawn in the ConformanceHost
//  (ScrollRuleProbeUITests); this pins the arithmetic.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class CollectionScrollTargetResolutionTests: XCTestCase {

    private func section(header: Bool = false, cells: [[String: Any]]?, footer: Bool = false) -> CollectionDataSection {
        var s = CollectionDataSection()
        if header { s.setHeader(viewName: "", data: ["title": "H"]) }
        if let cells { s.setCells(viewName: "", data: cells) }
        if footer { s.setFooter(viewName: "", data: ["title": "F"]) }
        return s
    }

    /// Section A: header, a0…a4 (keys k0…k4), footer; section B: header, b0…b7 (keys k3, x1…x7).
    private var source: CollectionDataSource {
        let second = ["k3"] + (1..<8).map { "x\($0)" }
        return CollectionDataSource(sections: [
            section(header: true, cells: (0..<5).map { ["key": "k\($0)"] }, footer: true),
            section(header: true, cells: (0..<8).map { ["key": second[$0]] })
        ])
    }

    private let sections: [[String: Any]] = [
        ["cell": "c", "header": "h", "footer": "f"],
        ["cell": "c", "header": "h"]
    ]

    private func id(_ target: CollectionScrollTarget, key: String? = nil, sections: [[String: Any]]? = nil, source: CollectionDataSource? = nil) -> AnyHashable? {
        CollectionConverter.scrollID(for: target, sections: sections ?? self.sections, dataSource: source ?? self.source, cellIdProperty: key)
    }

    private func place(_ item: Int, _ section: Int) -> AnyHashable { AnyHashable(IndexPath(item: item, section: section)) }
    private func keyID(_ key: String, _ section: Int) -> AnyHashable { AnyHashable(CollectionCellItem.Key(section: section, key: key)) }

    func testAnIndexIsACellCountedAcrossTheSections() {
        // No cellIdProperty and no cellId: no cell has a key, each is its place.
        XCTAssertEqual(id(.index(0)), place(0, 0))
        XCTAssertEqual(id(.index(4)), place(4, 0))
        XCTAssertEqual(id(.index(6)), place(1, 1))   // b1 — the header and footer are not counted
        XCTAssertEqual(id(.index(12)), place(7, 1))
        XCTAssertNil(id(.index(13)))
        XCTAssertNil(id(.index(-1)))
    }

    func testAKeyIsTheFirstCellInSectionOrderThatHasIt() {
        XCTAssertEqual(id(.cellId("k3"), key: "key"), keyID("k3", 0))     // a3, not b0
        XCTAssertEqual(id(.cellId("x2"), key: "key"), keyID("x2", 1))
        XCTAssertNil(id(.cellId("nothing"), key: "key"))
        // With the key property set, an index counts cells too; the id is the cell's own.
        XCTAssertEqual(id(.index(5), key: "key"), keyID("k3", 1))
    }

    /// A section that names no cell, or whose data has none, holds no cell to count.
    func testUndrawnSectionsAreNotCounted() {
        let withHeaderOnly: [[String: Any]] = [["header": "h"], ["cell": "c"]]
        let two = CollectionDataSource(sections: [
            section(header: true, cells: [["key": "q"]]),
            section(cells: [["key": "r"], ["key": "s"]])
        ])
        XCTAssertEqual(id(.index(0), sections: withHeaderOnly, source: two), place(0, 1))
        XCTAssertEqual(id(.index(1), sections: withHeaderOnly, source: two), place(1, 1))
        XCTAssertNil(id(.cellId("q"), key: "key", sections: withHeaderOnly, source: two))
    }

    /// On a horizontal Collection scrollAnchor is along the horizontal axis:
    /// top / center / bottom are the leading edge / middle / trailing edge
    /// (4f ruling 2026-09-27). They were .top / .center / .bottom — x 0.5.
    func testAHorizontalAnchorIsAlongTheScrollAxis() {
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint("top", horizontal: true), .leading)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint("center", horizontal: true), .center)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint("bottom", horizontal: true), .trailing)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(nil, horizontal: true), .trailing)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint("top", horizontal: false), .top)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint("center", horizontal: false), .center)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(nil, horizontal: false), .bottom)
    }

    func testTheCellsIDsAreDistinctAcrossSections() {
        let a = CollectionConverter.identifiedItems(from: [["key": "k3"]], cellIdProperty: "key", section: 0)
        let b = CollectionConverter.identifiedItems(from: [["key": "k3"]], cellIdProperty: "key", section: 1)
        XCTAssertEqual(a.map(\.id), [keyID("k3", 0)])
        XCTAssertEqual(b.map(\.id), [keyID("k3", 1)])
        XCTAssertNotEqual(a[0].id, b[0].id)
    }

    /// Round 14: a cell with no key at 3 and a cell keyed "3", in one
    /// section. The first is its place, which no String equals; "3" names the
    /// second. They were one id, "3".
    func testACellWithNoKeyIsItsPlaceAndNoStringEqualsIt() {
        let cells: [[String: Any]] = (0..<6).map { $0 == 5 ? ["key": "3"] : [:] }
        let items = CollectionConverter.identifiedItems(from: cells, cellIdProperty: "key", section: 0)
        XCTAssertEqual(items[3].id, place(3, 0))
        XCTAssertEqual(items[5].id, keyID("3", 0))
        XCTAssertEqual(Set(items.map(\.id)).count, 6)
        XCTAssertFalse(items.contains { $0.id == AnyHashable("3") || $0.id == AnyHashable(3) })
        let one = CollectionDataSource(sections: [section(cells: cells)])
        XCTAssertEqual(id(.cellId("3"), key: "key", sections: [["cell": "c"]], source: one), keyID("3", 0))
    }

    /// Round 14: two cells of one section keyed "k". The first takes the key,
    /// the later is its place: no two ids are one, and "k" names the first.
    /// They were one id, "k".
    func testAKeyTwoCellsOfOneSectionShareIsTheFirstsAndTheLaterIsItsPlace() {
        let cells: [[String: Any]] = [["key": "a"], ["key": "k"], ["key": "b"], ["key": "k"]]
        let items = CollectionConverter.identifiedItems(from: cells, cellIdProperty: "key", section: 2)
        XCTAssertEqual(items.map(\.id), [keyID("a", 2), keyID("k", 2), keyID("b", 2), place(3, 2)])
        let one = CollectionDataSource(sections: [section(cells: cells)])
        XCTAssertEqual(id(.cellId("k"), key: "key", sections: [["cell": "c"]], source: one), keyID("k", 0))
        XCTAssertEqual(id(.index(3), key: "key", sections: [["cell": "c"]], source: one), place(3, 0))
    }
}
#endif
