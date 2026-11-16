//
//  SegmentTabIdentifierTests.swift
//  SwiftJsonUITests
//
//  Each segment of a Dynamic Segment carries `<id>_tab_<n>`, the id every
//  driver's selectTab looks for (jsonui-cli ticket
//  jui-segment-tabs-carry-no-tab-ids-so-selecttab-cannot-reach-them). This
//  holds the id; that it reaches XCUITest as the segment's button was
//  measured on the iOS 26.5 simulator (2026-10-03), not here.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class SegmentTabIdentifierTests: XCTestCase {

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    func testEachSegmentIsTheSegmentsIdTabN() throws {
        let c = try component(["type": "Segment", "id": "style_segment", "items": ["App", "Book"]])
        XCTAssertEqual((0..<2).map { SegmentConverter.tabIdentifier(c, index: $0) },
                       ["style_segment_tab_0", "style_segment_tab_1"])
    }

    func testNoIdGivesNoSegmentIdentifier() throws {
        let c = try component(["type": "Segment", "items": ["App", "Book"]])
        XCTAssertNil(SegmentConverter.tabIdentifier(c, index: 0))
    }
}
#endif
