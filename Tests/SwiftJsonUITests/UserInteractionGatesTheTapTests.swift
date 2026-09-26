//
//  UserInteractionGatesTheTapTests.swift
//  SwiftJsonUITests
//
//  `userInteractionEnabled` gates the tap as canTap does (jsonui-cli
//  shared/core/tap_accessibility.rb): false — or a binding resolving false —
//  on the component, or on one around it, attaches no tap and no button
//  trait. A component around it reaches the component as
//  `interactionStoppedAround`, which DynamicComponentBuilder sets under
//  `jsonuiInteractionStopped` (the vector tests walk the same marking); the
//  component's own flag is resolved where the tap is attached
//  (DynamicEventHelper.tapGateOpen).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class UserInteractionGatesTheTapTests: XCTestCase {

    private func label(_ extra: [String: Any] = [:]) throws -> DynamicComponent {
        var json: [String: Any] = ["type": "Label", "id": "t", "text": "Open", "onClick": "@{onOpen}"]
        json.merge(extra) { _, new in new }
        return try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
    }

    func testWithNoFlagTheTapIsOpenAndAButton() throws {
        let c = try label()
        XCTAssertTrue(DynamicEventHelper.tapGateOpen(c, data: [:]))
        XCTAssertEqual(TapAccessibility.shape(of: c), .button)
    }

    func testFalseShutsTheTapAndTheTrait() throws {
        let c = try label(["userInteractionEnabled": false])
        XCTAssertFalse(DynamicEventHelper.tapGateOpen(c, data: [:]))
        XCTAssertNil(TapAccessibility.shape(of: c))
    }

    func testTrueLeavesItOpen() throws {
        let c = try label(["userInteractionEnabled": true])
        XCTAssertTrue(DynamicEventHelper.tapGateOpen(c, data: [:]))
        XCTAssertEqual(TapAccessibility.shape(of: c), .button)
    }

    func testABindingFollowsItsValue() throws {
        let c = try label(["userInteractionEnabled": "@{u}"])
        XCTAssertFalse(DynamicEventHelper.tapGateOpen(c, data: ["u": false]))
        XCTAssertTrue(DynamicEventHelper.tapGateOpen(c, data: ["u": true]))
        // The shape is the rule's static answer: the gate decides at run time.
        XCTAssertEqual(TapAccessibility.shape(of: c), .button)
    }

    func testAComponentMarkedAsInsideAStopHasNoTap() throws {
        let original = try label()
        let marked = original.markedStopped()
        XCTAssertFalse(DynamicEventHelper.tapGateOpen(marked, data: [:]))
        XCTAssertNil(TapAccessibility.shape(of: marked))
        // The mark is on a copy: the layout's own component is left as it was.
        XCTAssertFalse(original.interactionStoppedAround)
        XCTAssertTrue(DynamicEventHelper.tapGateOpen(original, data: [:]))
        // An image in it operates nothing (the image rule asks the tap rule).
        let image: [String: Any] = ["type": "Image", "id": "i", "src": "x", "onClick": "@{onOpen}"]
        XCTAssertFalse(ImageAccessibility.isTappable(image, stopped: true))
        XCTAssertEqual(ImageAccessibility.role(image, nearestTappable: nil, stopped: true), .decorative)
        XCTAssertEqual(ImageAccessibility.role(image, nearestTappable: nil), .control)
    }

    /// A Label's links are none under a stop (the Linkable Label ticket): the
    /// mark from a stop around it — a cell drawn under one — takes them, as
    /// the rule's `stopped` does for a node inside the same layout, and so
    /// does the Label's own flag, asked with no stop around (holdsAControl
    /// folds a child's flag into `stopped` before it asks, so the vectors do
    /// not reach that clause). A binding is the gate's to decide at run time.
    func testALinkedLabelMarkedAsInsideAStopOperatesNothing() throws {
        func linked(_ extra: [String: Any] = [:]) throws -> DynamicComponent {
            var json: [String: Any] = ["type": "Label", "id": "k", "text": "see https://example.com", "linkable": true]
            json.merge(extra) { _, new in new }
            return try XCTUnwrap(JSONLayoutLoader.decodeComponent(from: json))
        }
        XCTAssertTrue(TapAccessibility.isOperable(try linked()))
        XCTAssertFalse(TapAccessibility.isOperable(try linked().markedStopped()))
        XCTAssertFalse(TapAccessibility.isOperable(try linked(["userInteractionEnabled": false])))
        XCTAssertTrue(TapAccessibility.isOperable(try linked(["userInteractionEnabled": "@{u}"])))
    }

    func testCanTapAndTheFlagAreBothGates() throws {
        XCTAssertFalse(DynamicEventHelper.tapGateOpen(try label(["canTap": false, "userInteractionEnabled": true]), data: [:]))
        XCTAssertFalse(DynamicEventHelper.tapGateOpen(try label(["canTap": true, "userInteractionEnabled": false]), data: [:]))
    }
}
#endif
