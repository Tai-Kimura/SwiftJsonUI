//
//  ContainerAccessibilityHazardTests.swift
//  SwiftJsonUITests
//
//  Tests for DynamicModifierHelper.accessibilityMergeHazard — the anchor
//  overlay that keeps a container's accessibilityIdentifier queryable must
//  only be applied where the single-child merge hazard exists. Applied to
//  every id-bearing container it is a linear per-nesting-level stack cost
//  (the overlay layout node recurses through the content inline, AnyView
//  erasure does not break the chain) and exhausted the device main-thread
//  stack on large screens (EXC_BAD_ACCESS code=2).
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class ContainerAccessibilityHazardTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    // MARK: - Hazardous shapes (anchor required)

    func testSingleChildContainerIsHazard() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "Hi" } ] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testEmptyContainerIsHazard() throws {
        let c = try component("""
        { "type": "View", "id": "root", "child": [] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testVisibilityBindingChildDoesNotCount() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "One" },
                     { "type": "Label", "text": "Two", "visibility": "@{isShown}" } ] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testInvisibleChildDoesNotCount() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "One" },
                     { "type": "Label", "text": "Two", "visibility": "invisible" } ] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testIncludeChildDoesNotCount() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "One" },
                     { "include": "some_partial" } ] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testDataDrivenChildDoesNotCount() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "One" },
                     { "type": "Collection", "id": "list" } ] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testDecorativeEmptyContainerChildDoesNotCount() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "One" },
                     { "type": "View", "height": 1, "background": "#CCCCCC" } ] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    /// An image is an element only while its alt keeps it one: with no alt it
    /// is decorative and hidden (unless the tappables around it make it a
    /// control), with alt "" hidden, with a bound alt hidden when that is "".
    /// Counted as sure, a hidden image and one tappable View read as two
    /// children: the container took no anchor and SwiftUI merged it into the
    /// View, whose id then read the container's box (jsonui-cli ticket
    /// sjui-a-tappable-elements-anchor-inside-its-tap-target-moves-the-tap-
    /// point-off-it). sjui_tools container_accessibility_spec holds the same rows.
    private func imageAndLabel(_ image: String) throws -> DynamicComponent {
        try component("""
        { "type": "View", "id": "root",
          "child": [ \(image), { "type": "Label", "text": "One" } ] }
        """)
    }

    func testAnImageThatMayBeHiddenDoesNotCount() throws {
        for type in ["Image", "NetworkImage", "CircleImage"] {
            for extra in ["", #", "alt": """#, #", "alt": "@{photoAlt}""#, #", "accessibilityLabel": "@{photoAlt}""#] {
                let c = try imageAndLabel(#"{ "type": "\#(type)", "src": "photo"\#(extra) }"#)
                XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c), "\(type)\(extra)")
            }
        }
    }

    func testAnImageWithANonEmptyAltCounts() throws {
        for key in ["alt", "accessibilityLabel", "contentDescription"] {
            let c = try imageAndLabel(#"{ "type": "NetworkImage", "src": "photo", "\#(key)": "Photo" }"#)
            XCTAssertFalse(DynamicModifierHelper.accessibilityMergeHazard(c), key)
        }
    }

    func testACardOfADecorativeImageAndOneTappableViewIsHazard() throws {
        let c = try component("""
        { "type": "View", "id": "card", "width": "matchParent", "height": 200, "onClick": "@{onCard}",
          "child": [ { "type": "NetworkImage", "id": "photo", "width": "matchParent", "height": "matchParent",
                       "src": "@{url}", "contentMode": "AspectFill" },
                     { "type": "View", "id": "remove", "width": 30, "height": 30,
                       "alignTop": true, "alignRight": true, "onClick": "@{onRemove}",
                       "child": [ { "type": "Label", "text": "x" } ] } ] }
        """)
        XCTAssertTrue(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    // MARK: - Safe shapes (no anchor; bounded depth cost)

    func testTwoGuaranteedElementsIsSafe() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "One" },
                     { "type": "Label", "text": "Two" } ] }
        """)
        XCTAssertFalse(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testIdBearingContainerChildCountsAsElement() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "Label", "text": "One" },
                     { "type": "View", "id": "section",
                       "child": [ { "type": "Label", "text": "A" },
                                  { "type": "Label", "text": "B" } ] } ] }
        """)
        XCTAssertFalse(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testIdLessWrapperPromotesDescendants() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "View",
                       "child": [ { "type": "Label", "text": "A" },
                                  { "type": "Label", "text": "B" } ] } ] }
        """)
        XCTAssertFalse(DynamicModifierHelper.accessibilityMergeHazard(c))
    }

    func testMixedControlTypesAreSafe() throws {
        let c = try component("""
        { "type": "View", "id": "root",
          "child": [ { "type": "TextField", "id": "name" },
                     { "type": "Button", "text": "Save" } ] }
        """)
        XCTAssertFalse(DynamicModifierHelper.accessibilityMergeHazard(c))
    }
}
#endif
