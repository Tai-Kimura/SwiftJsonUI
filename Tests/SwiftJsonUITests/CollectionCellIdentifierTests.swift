//
//  CollectionCellIdentifierTests.swift
//  SwiftJsonUITests
//
//  A Collection cell has to carry the address the test drivers use —
//  `{collectionId}_item_{index}`, what `tapItem` and `waitFor` resolve, and
//  the spelling the static codegen emits.
//
//  Dynamic emitted nothing here, on any layout. Fixtures always run through
//  Dynamic, so the conformance suite could never check this contract at all
//  — which is how two of the static codegen's layout arms went without it
//  unnoticed until a consumer hit one.
//
//  Every cell path funnels through `buildCellView` (nine call sites), so
//  unlike the static side there is one place to put the rule and the "all
//  arms" property holds by construction. What is worth pinning is the
//  spelling — it has to match the codegen exactly or the drivers resolve
//  nothing — and the no-id case.
//

import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class CollectionCellIdentifierTests: XCTestCase {

    private func component(id: String?, layout: String? = nil,
                           lazy: String? = nil) throws -> DynamicComponent {
        var json = "{\"type\":\"Collection\""
        if let id { json += ",\"id\":\"\(id)\"" }
        if let layout { json += ",\"layout\":\"\(layout)\"" }
        if let lazy { json += ",\"lazy\":\"\(lazy)\"" }
        json += "}"
        return try JSONDecoder().decode(
            DynamicComponent.self, from: Data(json.utf8)
        )
    }

    func testSpellingMatchesTheStaticCodegen() throws {
        let c = try component(id: "suggested_collection")
        XCTAssertEqual(
            CollectionConverter.cellAccessibilityIdentifier(component: c, cellIndex: 0),
            "suggested_collection_item_0"
        )
        XCTAssertEqual(
            CollectionConverter.cellAccessibilityIdentifier(component: c, cellIndex: 7),
            "suggested_collection_item_7"
        )
    }

    /// The declared `layout` says how cells are arranged. It must not decide
    /// whether a test can reach them — the defect this replaces on the static
    /// side was exactly that dependency.
    func testTheIdentifierDoesNotDependOnTheLayout() throws {
        for layout in ["vertical", "horizontal", "flow", "leftAligned", "LeftAligned"] {
            let c = try component(id: "c", layout: layout)
            XCTAssertEqual(
                CollectionConverter.cellAccessibilityIdentifier(component: c, cellIndex: 3),
                "c_item_3",
                "layout: \(layout) produced a different address"
            )
        }
    }

    /// Nothing to build an address out of. An empty identifier is what
    /// SwiftUI treats as unset, so the cell keeps whatever its own root
    /// declares rather than being given a bogus one.
    func testNoCollectionIdMeansNoIdentifier() throws {
        XCTAssertEqual(
            CollectionConverter.cellAccessibilityIdentifier(
                component: try component(id: nil), cellIndex: 0),
            ""
        )
        XCTAssertEqual(
            CollectionConverter.cellAccessibilityIdentifier(
                component: try component(id: ""), cellIndex: 0),
            ""
        )
    }

    // MARK: - the container the cells live in

    /// Giving cells an address is not enough. A bare
    /// `.accessibilityIdentifier` on a view that is not itself an
    /// accessibility element is pushed DOWN onto its child elements, renaming
    /// every cell to the collection's id — so `tapItem` can address no index
    /// at all. Measured on the conformance host: with `lazy: "none"` the cell
    /// addresses timed out; with the default they resolved.
    ///
    /// Collection is not a container by TYPE, which is why it stays out of
    /// `accessibilityContainerTypes` and answers by shape instead.
    func testANonScrollCollectionIsMadeAnElement() throws {
        let c = try component(id: "c", layout: "flow", lazy: "none")
        XCTAssertTrue(DynamicModifierHelper.isAccessibilityContainer(c))
    }

    func testScrollShapesAreLeftAlone() throws {
        for lazy in [nil, "lazy", "eager"] {
            let c = try component(id: "c", layout: "flow", lazy: lazy)
            XCTAssertFalse(
                DynamicModifierHelper.isAccessibilityContainer(c),
                "lazy: \(lazy ?? "(default)") already renders a scroll container"
            )
        }
    }

    /// The shape decides, not the layout — `lazy: "none"` renders a bare
    /// stack whichever way the cells are arranged.
    func testItIsTheLazyModeAndNotTheLayoutThatDecides() throws {
        for layout in ["vertical", "horizontal", "flow"] {
            XCTAssertTrue(
                DynamicModifierHelper.isAccessibilityContainer(
                    try component(id: "c", layout: layout, lazy: "none")),
                "layout: \(layout) with lazy:none is not a scroll container"
            )
        }
    }

    func testAPlainViewIsStillAContainerByType() throws {
        let json = "{\"type\":\"View\",\"id\":\"v\"}"
        let c = try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
        XCTAssertTrue(DynamicModifierHelper.isAccessibilityContainer(c))
    }
}
#endif
