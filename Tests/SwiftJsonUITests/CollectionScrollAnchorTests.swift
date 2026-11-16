//
//  CollectionScrollAnchorTests.swift
//  SwiftJsonUITests
//
//  A bound Collection.scrollAnchor (jsonui-cli 1.9.29,
//  jui-collection-scrollto-per-request-anchor): CollectionScrollAnchor.point
//  is what sjui's generated code calls inside the `.onChange(of:)` a scrollTo
//  value keys, and the Dynamic Collection resolves the bound value from the
//  render's data the same way. Top / center / bottom along the scroll axis;
//  anything else bottom, named once per (Collection, value) in a DEBUG build.
//  A written anchor lands as it did. A bound scrollAnimated animates only
//  when the bound value is true.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

final class CollectionScrollAnchorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        CollectionScrollAnchor.resetForTest()
    }

    override func tearDown() {
        CollectionScrollAnchor.warningSink = nil
        CollectionScrollAnchor.resetForTest()
        super.tearDown()
    }

    func testTheThreeAnchorsAlongEachAxis() {
        XCTAssertEqual(CollectionScrollAnchor.point("top", horizontal: false), .top)
        XCTAssertEqual(CollectionScrollAnchor.point("center", horizontal: false), .center)
        XCTAssertEqual(CollectionScrollAnchor.point("bottom", horizontal: false), .bottom)
        XCTAssertEqual(CollectionScrollAnchor.point("top", horizontal: true), .leading)
        XCTAssertEqual(CollectionScrollAnchor.point("center", horizontal: true), .center)
        XCTAssertEqual(CollectionScrollAnchor.point("bottom", horizontal: true), .trailing)
    }

    func testAValueThatIsNoAnchorLandsAsBottomAndIsNamedOnce() {
        var heard: [String] = []
        CollectionScrollAnchor.warningSink = { heard.append($0) }
        XCTAssertEqual(CollectionScrollAnchor.point("sideways", horizontal: false, collection: "message_list"), .bottom)
        XCTAssertEqual(CollectionScrollAnchor.point("sideways", horizontal: false, collection: "message_list"), .bottom)
        XCTAssertEqual(CollectionScrollAnchor.point(nil, horizontal: true, collection: "message_list"), .trailing)
        XCTAssertEqual(CollectionScrollAnchor.point("top", horizontal: false, collection: "message_list"), .top)
        #if DEBUG
        XCTAssertEqual(heard, [
            "Collection message_list: scrollAnchor \"sideways\" is not top, center or bottom — lands as bottom",
            "Collection message_list: scrollAnchor \"nil\" is not top, center or bottom — lands as bottom",
        ])
        #else
        XCTAssertEqual(heard, [])
        #endif
    }

    #if DEBUG
    private func component(_ json: [String: Any]) -> DynamicComponent {
        JSONLayoutLoader.decodeComponent(from: json)!
    }

    func testTheDynamicCollectionResolvesABoundAnchorFromTheRendersData() {
        let bound = component(["type": "Collection", "id": "list", "scrollAnchor": "@{anchor}"])
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(bound, data: ["anchor": "top"], horizontal: false), .top)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(bound, data: ["anchor": "center"], horizontal: false), .center)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(bound, data: ["anchor": "bottom"], horizontal: true), .trailing)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(bound, data: [:], horizontal: false), .bottom)
    }

    func testAWrittenAnchorLandsAsBefore() {
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(component(["type": "Collection", "scrollAnchor": "top"]), data: [:], horizontal: false), .top)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(component(["type": "Collection", "scrollAnchor": "top"]), data: [:], horizontal: true), .leading)
        XCTAssertEqual(CollectionConverter.scrollAnchorPoint(component(["type": "Collection"]), data: [:], horizontal: false), .bottom)
    }

    func testABoundScrollAnimatedAnimatesOnlyWhenTrue() {
        let bound = component(["type": "Collection", "scrollAnimated": "@{animated}"])
        XCTAssertTrue(CollectionConverter.scrollAnimated(bound, data: ["animated": true]))
        XCTAssertFalse(CollectionConverter.scrollAnimated(bound, data: ["animated": false]))
        XCTAssertFalse(CollectionConverter.scrollAnimated(bound, data: [:]))
        XCTAssertTrue(CollectionConverter.scrollAnimated(component(["type": "Collection"]), data: [:]))
        XCTAssertFalse(CollectionConverter.scrollAnimated(component(["type": "Collection", "scrollAnimated": false]), data: [:]))
    }
    #endif
}
