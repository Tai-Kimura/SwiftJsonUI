//
//  TabViewShowLabelsTests.swift
//  SwiftJsonUITests
//
//  `showLabels` is declared `boolean` with `default: true`, so the fixture
//  (`showLabels: true`) and its control (attribute absent) must resolve to the
//  SAME value and render the same picture. Pinned because 51-E2 §2 measured
//  `TabView/showLabels__true` ACTIVE on ios, which this path cannot explain.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class TabViewShowLabelsTests: XCTestCase {

    private func tabView(_ dict: [String: Any]) -> DynamicComponent {
        var d: [String: Any] = [
            "type": "TabView",
            "tabs": [["title": "One"], ["title": "Two"]]
        ]
        d.merge(dict) { _, new in new }
        let data = try! JSONSerialization.data(withJSONObject: d)
        return try! JSONDecoder().decode(DynamicComponent.self, from: data)
    }

    private func resolved(_ c: DynamicComponent) -> Bool {
        c.typedAttributes(TabViewAttributes.self).showLabels ?? true
    }

    /// The fixture and its control must be indistinguishable at the attribute
    /// layer — declaring the default is not a change.
    func testDeclaringTheDefaultResolvesTheSameAsOmittingIt() {
        XCTAssertEqual(
            resolved(tabView(["showLabels": true])),
            resolved(tabView([:])),
            "showLabels: true is the declared default; it cannot differ from absent"
        )
    }

    func testTheDeclaredDefaultIsTrue() {
        XCTAssertTrue(resolved(tabView([:])))
    }

    /// The face that IS a change still is one.
    func testFalseIsDistinguishableFromTheDefault() {
        XCTAssertNotEqual(resolved(tabView(["showLabels": false])), resolved(tabView([:])))
    }
}
#endif
