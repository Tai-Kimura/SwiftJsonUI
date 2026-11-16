//
//  SegmentReadsNoCornerTests.swift
//  SwiftJsonUITests
//
//  A Segment reads no cornerRadius (the requester's ruling 2026-11-16,
//  jsonui-cli ticket rjui-selectbox-default-corner-overrides-declared): its
//  track and selected fill are the segmented control's capsules on every
//  platform. The Dynamic converter draws the component without the
//  declaration, a size class's included, so the standard chain neither clips
//  a declared background nor shapes a border with it. What the picture looks
//  like is the conformance fixtures' (common/cornerRadius_on_Segment__*).
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class SegmentReadsNoCornerTests: XCTestCase {

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    private func corner(_ c: DynamicComponent) -> Any? {
        c.typedAttributes(CommonAttributes.self).cornerRadius
    }

    func testADeclaredCornerIsDrawnWithout() throws {
        for radius: Any in [4, 100, "@{r}"] {
            let c = try component(["type": "Segment", "id": "s", "items": ["A", "B"],
                                   "background": "#FF0000", "cornerRadius": radius])
            XCTAssertNotNil(corner(c), "the fixture declares one: \(radius)")
            let drawn = SegmentConverter.withoutCorner(c)
            XCTAssertNil(corner(drawn), "\(radius)")
            XCTAssertNil(drawn.rawData["cornerRadius"])
            // Everything else is the node as declared.
            XCTAssertEqual(drawn.rawData["background"] as? String, "#FF0000")
            XCTAssertEqual(SegmentConverter.tabIdentifier(drawn, index: 1), "s_tab_1")
        }
    }

    func testASizeClassCornerIsDrawnWithout() throws {
        let c = try component(["type": "Segment", "items": ["A", "B"],
                               "responsive": ["regular": ["cornerRadius": 4, "background": "#00FF00"]]])
        let responsive = SegmentConverter.withoutCorner(c).rawData["responsive"] as? [String: Any]
        let regular = try XCTUnwrap(responsive?["regular"] as? [String: Any])
        XCTAssertNil(regular["cornerRadius"])
        XCTAssertEqual(regular["background"] as? String, "#00FF00")
    }

    // Its border and declared fill follow the capsule (the orchestrator's decision 2026-11-16):
    // the cornerRadius stage clips a fill to it, the border stage strokes it.
    func testOnlyASegmentIsDrawnInACapsule() throws {
        XCTAssertTrue(DynamicModifierHelper.drawnInACapsule(try component(["type": "Segment", "items": ["A"]])))
        XCTAssertFalse(DynamicModifierHelper.drawnInACapsule(try component(["type": "Button", "text": "A"])))
        XCTAssertFalse(DynamicModifierHelper.drawnInACapsule(try component(["type": "View"])))
    }

    func testNoCornerLeavesTheComponentAsItIs() throws {
        let c = try component(["type": "Segment", "items": ["A", "B"]])
        XCTAssertEqual(SegmentConverter.withoutCorner(c).rawData.count, c.rawData.count)
    }
}
#endif
