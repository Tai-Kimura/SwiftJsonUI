//
//  TabItemsAndStoppedItemsTests.swift
//  SwiftJsonUITests
//
//  The judgments the Dynamic runtime takes for two of 4f's rulings (jsonui-cli
//  1.9.0), the same as sjui build's emit:
//  - a TabView's `enabled` stops its tab items, not the tab view: no
//    `.disabled` stage for it (applyDisabled), the tab items read the value
//    (enabledBinding → jsonuiTabItemsEnabled), and its own tap and gestures
//    follow a bound one (applyEvents);
//  - a Segment's segments are elements of their own, so the stopped control
//    is told `items` (holdsItemElements); no other control is.
//  What they do on screen is ConformanceHost's (-tabEnabledProbe,
//  -a11yActivationProbe -wrappers).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class TabItemsAndStoppedItemsTests: XCTestCase {

    private func component(_ json: [String: Any]) throws -> DynamicComponent {
        try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    private func tabView(_ extra: [String: Any] = [:]) throws -> DynamicComponent {
        var json: [String: Any] = ["type": "TabView", "id": "t", "tabs": [["title": "One"], ["title": "Two"]]]
        json.merge(extra) { _, new in new }
        return try component(json)
    }

    func testATabViewIsTheTypeItIsDrawnAs() throws {
        XCTAssertTrue(DynamicModifierHelper.isTabView(try tabView()))
        XCTAssertFalse(DynamicModifierHelper.isTabView(try component(["type": "View", "id": "v"])))
    }

    func testEnabledFalseIsAConstantFalseForTheTabItems() throws {
        let enabled = try XCTUnwrap(DynamicModifierHelper.enabledBinding(try tabView(["enabled": false]), data: [:]))
        XCTAssertFalse(enabled.wrappedValue)
    }

    func testEnabledTrueOrNoneLeavesTheTabItemsAlone() throws {
        XCTAssertNil(DynamicModifierHelper.enabledBinding(try tabView(["enabled": true]), data: [:]))
        XCTAssertNil(DynamicModifierHelper.enabledBinding(try tabView(), data: [:]))
    }

    func testABoundEnabledFollowsItsValue() throws {
        let c = try tabView(["enabled": "@{on}"])
        XCTAssertEqual(DynamicModifierHelper.enabledBinding(c, data: ["on": false])?.wrappedValue, false)
        XCTAssertEqual(DynamicModifierHelper.enabledBinding(c, data: ["on": true])?.wrappedValue, true)
    }

    func testATabViewsOwnTapAndGesturesFollowABoundEnabled() throws {
        let c = try tabView(["enabled": "@{on}", "onClick": "@{onTap}"])
        XCTAssertTrue(DynamicEventHelper.tabViewOperationsShut(c, data: ["on": false]))
        XCTAssertFalse(DynamicEventHelper.tabViewOperationsShut(c, data: ["on": true]))
        XCTAssertFalse(DynamicEventHelper.tabViewOperationsShut(try tabView(["onClick": "@{onTap}"]), data: [:]))
        // Another type's bound enabled is `.disabled`'s, as before.
        let view = try component(["type": "View", "id": "v", "enabled": "@{on}", "onClick": "@{onTap}"])
        XCTAssertFalse(DynamicEventHelper.tabViewOperationsShut(view, data: ["on": false]))
    }

    /// The tab-change handler is called as the data holds it: `(Int)`,
    /// `(String, Int)` (the viewId first) and `()` alike, and each alias.
    /// Only `(Int) -> Void` was called.
    func testTheTabChangeHandlerIsCalledAsTheDataHoldsIt() throws {
        var got: [String] = []
        let data: [String: Any] = [
            "onIndex": { (i: Int) in got.append("index \(i)") } as (Int) -> Void,
            "onIdIndex": { (id: String, i: Int) in got.append("\(id) \(i)") } as (String, Int) -> Void,
            "onNothing": { got.append("nothing") } as () -> Void,
        ]
        for (key, handler) in [("onValueChange", "onIndex"), ("onValueChange", "onIdIndex"), ("onTabChange", "onNothing")] {
            let callback = try XCTUnwrap(TabViewConverter.tabChangeCallback(component: try tabView([key: "@{\(handler)}"]), data: data), key)
            callback(1)
        }
        XCTAssertEqual(got, ["index 1", "t 1", "nothing"])
        XCTAssertNil(TabViewConverter.tabChangeCallback(component: try tabView(), data: data))
    }

    func testOnlyASegmentHoldsItemElements() throws {
        XCTAssertTrue(DynamicModifierHelper.holdsItemElements(try component(["type": "Segment", "id": "s", "items": ["a", "b"]])))
        for type in ["Radio", "Switch", "CheckBox", "Button", "SelectBox", "Slider", "TextField"] {
            XCTAssertFalse(DynamicModifierHelper.holdsItemElements(try component(["type": type, "id": "c"])), type)
        }
    }
}
#endif
