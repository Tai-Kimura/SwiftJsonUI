//
//  DynamicScrollViewAxisTests.swift
//  SwiftJsonUITests
//
//  The axis a Dynamic ScrollView scrolls on: sideways when `horizontalScroll`
//  is true or its own `orientation` is `horizontal`, vertically otherwise —
//  never from its children (attribute_definitions.json ScrollView, user
//  ruling 2026-10-14, jui-scrollview-axis-from-child-web-disagrees; the rule
//  sjui / kjui codegen and rjui share). A pair that disagrees is refused by
//  jui build (ERROR [scrollview]); neither key outranks the other here.
//
//  An earlier commit of the 10.29.14 train (never released on its own) took
//  the axis from a single child View, read as written before its
//  `responsive` (sjui-dynamic-scrollview-axis-from-resolved-child). Those
//  specimens stay: a child horizontal as written, and a child turned by its
//  responsive block — each case first asserts that the child really is
//  horizontal where it is read, so a case that passes is one where taking the
//  axis from the child would have answered the other way.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicScrollViewAxisTests: XCTestCase {

    private func child(_ orientation: String, regular: String? = nil, type: String = "View") -> [String: Any] {
        var node: [String: Any] = ["type": type, "orientation": orientation,
                                   "child": [["type": "Label", "text": "a"]]]
        if let regular { node["responsive"] = ["regular": ["orientation": regular]] }
        return node
    }

    private func scroll(_ children: [[String: Any]], _ extra: [String: Any] = [:]) -> [String: Any] {
        var node: [String: Any] = ["type": "ScrollView", "child": children]
        extra.forEach { node[$0.key] = $0.value }
        return node
    }

    /// The tree as DynamicView resolves it, decoded; the ScrollView's axis and
    /// its first child's orientation as drawn.
    private func resolve(_ json: [String: Any], _ size: UserInterfaceSizeClass,
                         file: StaticString = #filePath, line: UInt = #line) -> (horizontal: Bool, childOrientation: String?) {
        let tree = ResponsiveResolver(horizontalSizeClass: size, verticalSizeClass: .regular).resolveTree(json)
        guard let component = JSONLayoutLoader.decodeComponent(from: tree) else {
            XCTFail("the tree did not decode", file: file, line: line)
            return (false, nil)
        }
        let children = (component.childComponents ?? []).filter { $0.isValid || $0.include != nil }
        return (DynamicScrollViewContainer.isHorizontal(component), children.first?.orientation)
    }

    func testAHorizontalChildLeavesTheScrollVertical() {
        let drawn = resolve(scroll([child("horizontal")]), .compact)
        XCTAssertEqual(drawn.childOrientation, "horizontal", "the specimen: the child is horizontal")
        XCTAssertFalse(drawn.horizontal)
    }

    func testAChildTurnedHorizontalUnderRegularLeavesTheScrollVertical() {
        let json = scroll([child("vertical", regular: "horizontal")])
        let regular = resolve(json, .regular)
        XCTAssertEqual(regular.childOrientation, "horizontal", "the specimen: the resolved child is turned")
        XCTAssertFalse(regular.horizontal)
        XCTAssertFalse(resolve(json, .compact).horizontal)
    }

    func testAChildHorizontalAsWrittenButVerticalUnderRegularLeavesTheScrollVertical() {
        let json = scroll([child("horizontal", regular: "vertical")])
        let compact = resolve(json, .compact)
        XCTAssertEqual(compact.childOrientation, "horizontal", "the specimen: the child is horizontal as written")
        XCTAssertFalse(compact.horizontal)
        XCTAssertFalse(resolve(json, .regular).horizontal)
    }

    func testOrientationHorizontalScrollsSideways() {
        XCTAssertTrue(resolve(scroll([child("vertical")], ["orientation": "horizontal"]), .compact).horizontal)
    }

    func testHorizontalScrollTrueScrollsSideways() {
        XCTAssertTrue(resolve(scroll([child("vertical")], ["horizontalScroll": true]), .compact).horizontal)
    }

    func testNeitherKeyOutranksTheOther() {
        // The pairs jui build refuses; drawn anyway, either key turns it.
        XCTAssertTrue(resolve(scroll([child("vertical")], ["orientation": "horizontal", "horizontalScroll": false]), .compact).horizontal)
        XCTAssertTrue(resolve(scroll([child("vertical")], ["orientation": "vertical", "horizontalScroll": true]), .compact).horizontal)
    }

    func testAScrollViewWithNoKeyIsVertical() {
        XCTAssertFalse(resolve(scroll([child("vertical")]), .compact).horizontal)
        XCTAssertFalse(resolve(scroll([child("vertical")], ["orientation": "vertical"]), .compact).horizontal)
        XCTAssertFalse(resolve(scroll([child("vertical")], ["horizontalScroll": false]), .compact).horizontal)
    }
}
#endif
