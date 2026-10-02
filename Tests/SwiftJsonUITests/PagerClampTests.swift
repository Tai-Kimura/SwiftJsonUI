//
//  PagerClampTests.swift
//  SwiftJsonUITests
//
//  A pager's selection outside its pages is clamped and written back, and the
//  page-change callback is told the clamped page — only when the shown page
//  changes — never the out-of-range value (jsonui-cli ticket
//  sjui-dynamic-pager-does-not-write-back-a-clamped-page). Until 10.29.2 a
//  bound currentPage of 10 on three pages left page 0 shown, the binding at
//  10 and the callback told 10.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class PagerClampTests: XCTestCase {
    private func change(_ old: Int, _ new: Int, pages: Int = 3) -> [Int?] {
        let c = CollectionConverter.pageChange(from: old, to: new, pageCount: pages)
        return [c.writeBack, c.report]
    }

    func testAPageInsideThePagesIsToldAsItIs() {
        XCTAssertEqual(change(0, 1), [nil, 1])
        XCTAssertEqual(change(2, 0), [nil, 0])
    }

    func testAPagePastTheLastIsClampedWrittenBackAndToldOnce() {
        XCTAssertEqual(change(0, 10), [2, 2])   // the write: page 2 shown, 2 written back, 2 told
        XCTAssertEqual(change(10, 2), [nil, nil]) // the write-back's own change: not a page change
        XCTAssertEqual(change(-3, 0), [nil, nil])
    }

    func testAClampToThePageAlreadyShownTellsNothing() {
        XCTAssertEqual(change(2, 10), [2, nil])
        XCTAssertEqual(change(0, -1), [0, nil])
    }

    func testNoPagesClampsToZero() {
        XCTAssertEqual(change(0, 4, pages: 0), [0, nil])
    }
}
#endif
