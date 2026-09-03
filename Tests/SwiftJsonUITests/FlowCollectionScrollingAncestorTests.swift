//
//  FlowCollectionScrollingAncestorTests.swift
//  SwiftJsonUITests
//
//  Ruling (2026-09-03): a flow Collection with `lazy` in effect scrolls
//  inside its own bounds; a wrapping one has none. The dynamic flow arm
//  wrapped its FlowLayout in a ScrollView unconditionally, so a wrapContent
//  flow inside a ScrollView became an inner ScrollView grown to the outer
//  viewport's height (the corpus's flowOverflow__wrap picture on iOS) while
//  Android wraps and lets the parent scroll. Now, under a scrolling
//  ancestor, the wrapping flow takes the non-lazy container and the
//  ancestor scrolls.
//
//  The decision has two halves. The half that reads the component is
//  pinned here (the same table sjui's flow_defers_to_scrolling_ancestor?
//  answers). The half that reads the context — SwiftUI environment set by
//  ScrollViewConverter and by a scrolling Collection on its cells — is a
//  render-time fact; what is pinned about it is which Collections set it
//  and that nothing sets it by default.
//

import SwiftUI
import XCTest
@testable import SwiftJsonUI

#if DEBUG
final class FlowCollectionScrollingAncestorTests: XCTestCase {

    private func component(layout: String? = "flow", lazy: String? = nil,
                           height: String? = "\"wrapContent\"",
                           extra: String = "") throws -> DynamicComponent {
        var json = "{\"type\":\"Collection\",\"id\":\"c\""
        if let layout { json += ",\"layout\":\"\(layout)\"" }
        if let lazy { json += ",\"lazy\":\"\(lazy)\"" }
        if let height { json += ",\"height\":\(height)" }
        json += extra
        json += "}"
        return try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    private func defers(_ c: DynamicComponent, inside: Bool = true) -> Bool {
        CollectionConverter.flowDefersToScrollingAncestor(c, data: [:], insideScrollingAncestor: inside)
    }

    // MARK: - the component half

    /// The consumer's shape: a chip flow, no height of its own, inside a
    /// screen that scrolls.
    func testAWrappingFlowUnderAScrollingAncestorDefers() throws {
        XCTAssertTrue(defers(try component()))
    }

    /// An undeclared height is wrapContent — the same reading sjui makes.
    func testAnUndeclaredHeightIsWrapContent() throws {
        XCTAssertTrue(defers(try component(height: nil)))
    }

    /// `leftAligned` is the alias spelling of flow (SSoT valueAliases).
    func testLeftAlignedIsFlow() throws {
        XCTAssertTrue(defers(try component(layout: "leftAligned")))
    }

    /// Any `lazy` IN EFFECT — the default and the explicit values alike —
    /// would build the ScrollView, so all of them defer. "none" never
    /// reaches this question: it renders the non-scroll container already.
    func testEveryLazyInEffectDefersAndNoneDoesNot() throws {
        for lazy in [nil, "lazy", "eager"] {
            XCTAssertTrue(defers(try component(lazy: lazy)), "lazy: \(lazy ?? "(default)")")
        }
        XCTAssertFalse(defers(try component(lazy: "none")))
    }

    /// Bounds of its own: a numeric height keeps the ScrollView (it clips
    /// and scrolls inside the box). matchParent borrows the parent's bounds,
    /// which the ScrollView then fills — also unchanged.
    func testASelfBoundedOrFillingFlowKeepsItsScrollView() throws {
        XCTAssertFalse(defers(try component(height: "100")))
        XCTAssertFalse(defers(try component(height: "\"matchParent\"")))
    }

    /// A bound height is unknown here; unknown keeps the container it had.
    func testABoundHeightKeepsTheScrollView() throws {
        XCTAssertFalse(defers(try component(height: "\"@{h}\"")))
    }

    func testOnlyFlowLayoutsAreConcerned() throws {
        for layout in ["vertical", "horizontal", nil] {
            XCTAssertFalse(defers(try component(layout: layout)), "layout: \(layout ?? "(default)")")
        }
    }

    /// Without the context there is nothing to defer to: the shape a
    /// full-screen chip destination relies on stays exactly as it was.
    func testNothingDefersOutsideAScrollingAncestor() throws {
        XCTAssertFalse(defers(try component(), inside: false))
        XCTAssertFalse(defers(try component(height: nil), inside: false))
    }

    // MARK: - the context half

    func testTheDefaultEnvironmentIsNotUnderAScrollingAncestor() {
        XCTAssertFalse(EnvironmentValues().jsonuiScrollingAncestor)
    }

    /// Which Collections tell their cells they scroll: the vertical shapes
    /// with `lazy` in effect (a flow scrolls vertically too). Horizontal
    /// ones scroll the other axis and `lazy: "none"` does not scroll at all
    /// — both leave the inherited mark alone rather than clearing it.
    func testAVerticallyScrollingCollectionMarksItsCells() throws {
        XCTAssertTrue(CollectionConverter.scrollsVertically(try component(layout: "vertical"), data: [:]))
        XCTAssertTrue(CollectionConverter.scrollsVertically(try component(layout: nil), data: [:]))
        XCTAssertTrue(CollectionConverter.scrollsVertically(try component(layout: "flow"), data: [:]))
        XCTAssertFalse(CollectionConverter.scrollsVertically(try component(layout: "horizontal"), data: [:]))
        XCTAssertFalse(CollectionConverter.scrollsVertically(
            try component(layout: "vertical", extra: ",\"horizontalScroll\":true"), data: [:]))
        XCTAssertFalse(CollectionConverter.scrollsVertically(try component(layout: "vertical", lazy: "none"), data: [:]))
    }
}
#endif
