import XCTest
import SwiftUI
@testable import SwiftJsonUI

/// The Dynamic pager's page identity — the id `flattenedPageItems` hands to
/// the TabView's ForEach — is the page's place, not its key. With
/// autoChangeTrackingId the key is the enriched cellId, which follows the
/// cell's content; a page whose id changed during a swipe could be removed
/// and re-inserted mid-animation (jsonui-cli ticket sjui-paging-collection-
/// uses-change-tracking-cellid-as-page-identity-and-stops-mid-swipe; the
/// generated pager stopped on 12 of 24 swipes before its fix). This is the
/// Dynamic face's structural reading: the ConformanceHost probe's Dynamic
/// half settled on every swipe before and after the change, so it does not
/// discriminate it; this test does (it fails on the key-based id).
final class DynamicPagerPageIdentityTests: XCTestCase {

    private func pages(titles: [String]) -> [PagingPageItem] {
        let cells: [[String: Any]] = titles.enumerated().map { ["key": "p\($0.offset)", "title": $0.element] }
        var section = CollectionDataSection()
        section.setCells(viewName: "conformance_cell", data: cells)
        // As CollectionConverter resolves a bound items with change tracking on.
        let tracked = CollectionDataSource(sections: [section]).reconfigured(cellIdProperty: "key", autoChangeTrackingId: true)
        return CollectionConverter.flattenedPageItems(
            sections: [["cell": "conformance_cell"]], dataSource: tracked, cellIdProperty: "key")
    }

    func testAPageKeepsItsIdWhenItsContentChanges() {
        let before = pages(titles: ["A", "B", "C", "D", "E"])
        let after = pages(titles: ["A", "B", "C changed", "D", "E"])
        XCTAssertEqual(before.map(\.id), after.map(\.id))
        // Control: the change-tracking cellId the cell redraws on did change.
        XCTAssertNotEqual(before[2].data["cellId"] as? String, after[2].data["cellId"] as? String)
    }

    func testEveryPageHasItsOwnId() {
        let ids = pages(titles: ["A", "A", "A"]).map(\.id)
        XCTAssertEqual(Set(ids).count, 3)
    }
}
