//
//  RelativeConstraintToAGoneAnchorTests.swift
//  SwiftJsonUITests
//
//  A constraint that names a gone element does not apply (attribute_semantics
//  goneModel, 2026-11-10; ticket relative-constraint-to-gone-anchor-keeps-its-place):
//  "gone takes no size and no position: the element is laid out as if it were
//  absent, and a constraint that names a gone element does not apply — the
//  constrained element is placed as it would be without that constraint."
//
//  RelativePositionContainer did not read visibility: a gone anchor kept the
//  box its own constraints placed and a sibling was linked to it as if it
//  were there (alignTopView + topMargin 10 at y 50 where the ruling places it
//  at y 10; family table 2026-11-10, iOS dynamic and codegen alike). Measured
//  end to end on 81 layouts in the conformance host; these pin the two
//  halves: which children the container lays out, and how Dynamic reads gone.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
@available(iOS 16.0, *)
final class RelativeConstraintToAGoneAnchorTests: XCTestCase {

    private func config(_ id: String, _ constraints: [RelativePositionConstraint], gone: Bool = false) -> RelativeChildConfig {
        RelativeChildConfig(id: id, view: AnyView(Color.clear), constraints: constraints, isGone: gone)
    }

    // MARK: - The container

    func testAGoneChildIsNotLaidOutAndAConstraintNamingItIsDropped() {
        let container = RelativePositionContainer(children: [
            config("a", [.init(type: .parentCenter, targetId: "")], gone: true),
            config("t", [.init(type: .alignTop, targetId: "a"), .init(type: .parentLeft, targetId: "")]),
        ])
        let laidOut = container.laidOutChildren
        XCTAssertEqual(laidOut.map(\.id), ["t"])
        XCTAssertEqual(laidOut[0].constraints.map(\.targetId), [""])
    }

    func testAVisibleAnchorKeepsEveryChildAndConstraint() {
        let container = RelativePositionContainer(children: [
            config("a", [.init(type: .parentCenter, targetId: "")]),
            config("t", [.init(type: .alignTop, targetId: "a")]),
        ])
        XCTAssertEqual(container.laidOutChildren.map(\.id), ["a", "t"])
        XCTAssertEqual(container.laidOutChildren[1].constraints.map(\.targetId), ["a"])
    }

    func testOnlyTheConstraintsNamingTheGoneChildAreDropped() {
        let container = RelativePositionContainer(children: [
            config("a", [], gone: true),
            config("b", []),
            config("t", [.init(type: .below, targetId: "a"), .init(type: .rightOf, targetId: "b")]),
        ])
        let t = container.laidOutChildren.first { $0.id == "t" }
        XCTAssertEqual(t?.constraints.map(\.targetId), ["b"])
    }

    // MARK: - Dynamic reads gone as it draws it

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    func testALiteralGoneIsGoneAndInvisibleIsNot() throws {
        XCTAssertTrue(RelativePositionConverter.isGone(try component(#"{"type":"View","visibility":"gone"}"#), data: [:]))
        XCTAssertFalse(RelativePositionConverter.isGone(try component(#"{"type":"View","visibility":"invisible"}"#), data: [:]))
        XCTAssertFalse(RelativePositionConverter.isGone(try component(#"{"type":"View"}"#), data: [:]))
        // hidden: true is invisible, not gone.
        XCTAssertFalse(RelativePositionConverter.isGone(try component(#"{"type":"View","hidden":true}"#), data: [:]))
    }

    func testABoundVisibilityIsReadFromTheData() throws {
        let bound = try component(#"{"type":"View","visibility":"@{aVis}"}"#)
        XCTAssertTrue(RelativePositionConverter.isGone(bound, data: ["aVis": "gone"]))
        XCTAssertFalse(RelativePositionConverter.isGone(bound, data: ["aVis": "visible"]))
        XCTAssertTrue(RelativePositionConverter.isGone(bound, data: ["aVis": SwiftUI.Binding.constant("gone")]))
        XCTAssertTrue(RelativePositionConverter.isGone(bound, data: ["aVis": false]))
    }
}
#endif
