//
//  DynamicScrollViewAxisTests.swift
//  SwiftJsonUITests
//
//  The axis a Dynamic ScrollView scrolls on, in sjui's codegen order
//  (jsonui-cli sjui_tools scrollview_converter.rb): `horizontalScroll`, else
//  the ScrollView's own `orientation`, else its only child View's
//  orientation AS WRITTEN — before that child's `responsive` is resolved
//  (sjui-dynamic-scrollview-axis-from-resolved-child).
//
//  The specimen the defect needs is a child whose responsive override turns
//  its orientation: every such case first asserts that the resolved child
//  really is turned, so a case that passes is one where reading the resolved
//  child would have answered the other way.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicScrollViewAxisTests: XCTestCase {

    private func child(_ orientation: String, regular: String? = nil) -> [String: Any] {
        var node: [String: Any] = ["type": "View", "orientation": orientation,
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
    /// its drawn child's orientation.
    private func resolve(_ json: [String: Any], _ size: UserInterfaceSizeClass,
                         file: StaticString = #filePath, line: UInt = #line) -> (horizontal: Bool, childOrientation: String?) {
        let tree = ResponsiveResolver(horizontalSizeClass: size, verticalSizeClass: .regular).resolveTree(json)
        guard let component = JSONLayoutLoader.decodeComponent(from: tree) else {
            XCTFail("the tree did not decode", file: file, line: line)
            return (false, nil)
        }
        let children = (component.childComponents ?? []).filter { $0.isValid || $0.include != nil }
        return (DynamicScrollViewContainer.isHorizontal(component, children: children), children.first?.orientation)
    }

    func testAChildTurnedHorizontalUnderRegularLeavesTheScrollVertical() {
        let json = scroll([child("vertical", regular: "horizontal")])
        let regular = resolve(json, .regular)
        XCTAssertEqual(regular.childOrientation, "horizontal", "the specimen: the resolved child is turned")
        XCTAssertFalse(regular.horizontal)
        XCTAssertFalse(resolve(json, .compact).horizontal)
    }

    func testAChildTurnedVerticalUnderRegularLeavesTheScrollHorizontal() {
        let json = scroll([child("horizontal", regular: "vertical")])
        let regular = resolve(json, .regular)
        XCTAssertEqual(regular.childOrientation, "vertical", "the specimen: the resolved child is turned")
        XCTAssertTrue(regular.horizontal)
        XCTAssertTrue(resolve(json, .compact).horizontal)
    }

    func testTheScrollViewsOwnVerticalWinsOverAHorizontalChild() {
        XCTAssertFalse(resolve(scroll([child("horizontal")], ["orientation": "vertical"]), .compact).horizontal)
        XCTAssertFalse(resolve(scroll([child("horizontal", regular: "horizontal")], ["orientation": "vertical"]), .regular).horizontal)
    }

    func testTheScrollViewsOwnHorizontalWinsOverAVerticalChild() {
        XCTAssertTrue(resolve(scroll([child("vertical")], ["orientation": "horizontal"]), .compact).horizontal)
    }

    func testHorizontalScrollWinsOverTheScrollViewsOwnVertical() {
        XCTAssertTrue(resolve(scroll([child("vertical")], ["orientation": "vertical", "horizontalScroll": true]), .compact).horizontal)
    }

    func testAChildWithoutABlockStillGivesItsAxis() {
        let json = scroll([child("horizontal")])
        XCTAssertTrue(resolve(json, .regular).horizontal)
        XCTAssertNil(ResponsiveResolver.stampingScrollAxis(json)[ResponsiveResolver.scrollBaseChildOrientationKey],
                     "nothing to stamp: the child is already as written")
    }

    func testADataEntryBesideTheChildIsNotCounted() {
        let json = scroll([["data": [["name": "x", "class": "String"]]], child("vertical", regular: "horizontal")])
        let regular = resolve(json, .regular)
        XCTAssertEqual(regular.childOrientation, "horizontal", "the specimen: the resolved child is turned")
        XCTAssertFalse(regular.horizontal)
    }

    func testTwoChildrenGiveNoAxisFromAChild() {
        let json = scroll([child("horizontal", regular: "horizontal"), child("horizontal")])
        XCTAssertNil(ResponsiveResolver.stampingScrollAxis(json)[ResponsiveResolver.scrollBaseChildOrientationKey])
        XCTAssertFalse(resolve(json, .regular).horizontal)
    }
}
#endif
