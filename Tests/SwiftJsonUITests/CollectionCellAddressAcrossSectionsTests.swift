//
//  CollectionCellAddressAcrossSectionsTests.swift
//  SwiftJsonUITests
//
//  A cell's `{collectionId}_item_{n}` counts across the drawn sections
//  (jsonui-cli ticket jui-collection-item-identifier-repeats-per-section,
//  ruling a2; attribute_semantics idBox.collectionCellRoot): n is the cells
//  of the drawn sections before its own, then its index in its section —
//  the n of scrollTo's Int (scrollID) and of a pager's page. Until jsonui-cli
//  2.5.39 every route but the pager restarted n at 0 per section, so two
//  sections each had an `_item_0` and a test could not reach the second
//  section's rows. The index onItemAppear is called with stays the cell's
//  place in its section. The drawn cells themselves are checked in the
//  ConformanceHost (Collection/cellAddress__sections_*); this pins the count.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class CollectionCellAddressAcrossSectionsTests: XCTestCase {

    private func section(_ count: Int, header: Bool = false) -> CollectionDataSection {
        var s = CollectionDataSection()
        if header { s.setHeader(viewName: "", data: ["title": "H"]) }
        s.setCells(viewName: "", data: (0..<count).map { ["title": "c\($0)"] })
        return s
    }

    /// 1 cell, a header-only section declared with 5 cells in its data, 2 cells, 3 cells.
    private var source: CollectionDataSource {
        CollectionDataSource(sections: [section(1, header: true), section(5), section(2, header: true), section(3)])
    }

    private let sections: [[String: Any]] = [["cell": "a", "header": "h"], ["header": "h"], ["cell": "b", "header": "h"], ["cell": "c"]]

    func testTheDrawnSectionsBeforeAreCounted() {
        XCTAssertEqual(CollectionConverter.cellsBefore(0, sections: sections, dataSource: source), 0)
        XCTAssertEqual(CollectionConverter.cellsBefore(2, sections: sections, dataSource: source), 1)   // the header-only section draws no cell
        XCTAssertEqual(CollectionConverter.cellsBefore(3, sections: sections, dataSource: source), 3)
    }

    func testTheClassListCountsEveryDataSection() {
        XCTAssertEqual(CollectionConverter.cellsBefore(2, sections: nil, dataSource: source), 6)
    }

    func testAddressesAreOneSequenceAndTheIndexStaysPerSection() {
        var addresses: [Int] = []
        var indexes: [Int] = []
        for s in [0, 2, 3] {
            let items = CollectionConverter.identifiedItems(
                from: source.sections[s].cells?.data ?? [], cellIdProperty: nil, section: s,
                firstAddress: CollectionConverter.cellsBefore(s, sections: sections, dataSource: source))
            addresses += items.map(\.address)
            indexes += items.map(\.index)
        }
        XCTAssertEqual(addresses, [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(indexes, [0, 0, 1, 0, 1, 2])
    }

    /// The address a scrollTo Int names is the same cell's.
    func testTheAddressIsTheScrollToIndex() {
        let s = 3
        let items = CollectionConverter.identifiedItems(
            from: source.sections[s].cells?.data ?? [], cellIdProperty: nil, section: s,
            firstAddress: CollectionConverter.cellsBefore(s, sections: sections, dataSource: source))
        for item in items {
            XCTAssertEqual(CollectionConverter.scrollID(for: .index(item.address), sections: sections,
                                                       dataSource: source, cellIdProperty: nil), item.id)
        }
    }

    func testOneSectionKeepsItsIds() {
        let items = CollectionConverter.identifiedItems(from: [["t": 1], ["t": 2]], cellIdProperty: nil, section: 0)
        XCTAssertEqual(items.map(\.address), [0, 1])
    }
}
#endif
