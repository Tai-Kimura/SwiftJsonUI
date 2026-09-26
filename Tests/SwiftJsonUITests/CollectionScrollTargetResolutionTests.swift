//
//  CollectionScrollTargetResolutionTests.swift
//  SwiftJsonUITests
//
//  What a Dynamic Collection's scrollTo names across sections (4f ruling
//  2026-09-27; jsonui-cli 1.9.0, the SSoT's Collection.scrollTo): an Int is a
//  CELL counted across the drawn sections in section order — a header or a
//  footer is not a cell; a String (cellIdProperty) is the first cell, in
//  section order, whose key it is. The resolver answers the `.id` of that
//  cell — a later section's cells carry "<section>:<id>", so two sections'
//  cells never answer one id.
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

    private func id(_ target: CollectionScrollTarget, key: String? = nil, sections: [[String: Any]]? = nil, source: CollectionDataSource? = nil) -> String? {
        CollectionConverter.scrollID(for: target, sections: sections ?? self.sections, dataSource: source ?? self.source, cellIdProperty: key)
    }

    func testAnIndexIsACellCountedAcrossTheSections() {
        XCTAssertEqual(id(.index(0)), "0")
        XCTAssertEqual(id(.index(4)), "4")
        XCTAssertEqual(id(.index(6)), "1:1")   // b1 — the header and footer are not counted
        XCTAssertEqual(id(.index(12)), "1:7")
        XCTAssertNil(id(.index(13)))
        XCTAssertNil(id(.index(-1)))
    }

    func testAKeyIsTheFirstCellInSectionOrderThatHasIt() {
        XCTAssertEqual(id(.cellId("k3"), key: "key"), "k3")     // a3, not b0 ("1:k3")
        XCTAssertEqual(id(.cellId("x2"), key: "key"), "1:x2")
        XCTAssertNil(id(.cellId("nothing"), key: "key"))
        // With the key property set, an index counts cells too; the id is the key.
        XCTAssertEqual(id(.index(5), key: "key"), "1:k3")
    }

    /// A section that names no cell, or whose data has none, holds no cell to count.
    func testUndrawnSectionsAreNotCounted() {
        let withHeaderOnly: [[String: Any]] = [["header": "h"], ["cell": "c"]]
        let two = CollectionDataSource(sections: [
            section(header: true, cells: [["key": "q"]]),
            section(cells: [["key": "r"], ["key": "s"]])
        ])
        XCTAssertEqual(id(.index(0), sections: withHeaderOnly, source: two), "1:0")
        XCTAssertEqual(id(.index(1), sections: withHeaderOnly, source: two), "1:1")
        XCTAssertNil(id(.cellId("q"), key: "key", sections: withHeaderOnly, source: two))
    }

    func testTheCellsScrollIDsAreDistinctAcrossSections() {
        XCTAssertEqual(CollectionConverter.cellScrollID(section: 0, cellID: "k3"), "k3")
        XCTAssertEqual(CollectionConverter.cellScrollID(section: 1, cellID: "k3"), "1:k3")
    }
}
#endif
