//
//  TouchDisabledStateIsUIKitOnlyTests.swift
//  SwiftJsonUITests
//
//  touchDisabledState is UIKit's hit-test mode (SJUIView: none / onlyMe /
//  viewsWithoutTouchEnabled / viewsWithoutInList — jsonui-cli's
//  attribute_definitions.json, mode uikit). The SwiftUI Dynamic path read any
//  value of it as "stop everything" (allowsHitTesting(false)), "none" too,
//  and onlyMe — which keeps the subviews tappable on UIKit — as well; a Bool
//  written for it failed the component's decode. It reads neither now.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class TouchDisabledStateIsUIKitOnlyTests: XCTestCase {

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    func testNoModeStopsTheView() throws {
        for mode in ["none", "onlyMe", "viewsWithoutTouchEnabled", "viewsWithoutInList"] {
            let c = try component(#"{"type": "View", "touchDisabledState": "\#(mode)"}"#)
            XCTAssertFalse(DynamicModifierHelper.stopsHitTesting(c, data: [:]), mode)
        }
    }

    func testTheFlagStillStopsIt() throws {
        XCTAssertTrue(DynamicModifierHelper.stopsHitTesting(try component(#"{"type": "View", "userInteractionEnabled": false}"#), data: [:]))
        let bound = try component(#"{"type": "View", "userInteractionEnabled": "@{u}"}"#)
        XCTAssertTrue(DynamicModifierHelper.stopsHitTesting(bound, data: ["u": false]))
        XCTAssertFalse(DynamicModifierHelper.stopsHitTesting(bound, data: ["u": true]))
        XCTAssertFalse(DynamicModifierHelper.stopsHitTesting(try component(#"{"type": "View"}"#), data: [:]))
    }

    func testABoolDecodesAndIsTheUnknownValueOfTheMode() throws {
        let c = try component(#"{"type": "View", "id": "v", "touchDisabledState": true}"#)
        XCTAssertEqual(c.id, "v")
        if case .unknown? = c.typedAttributes(CommonAttributes.self).touchDisabledState {} else {
            XCTFail("a Bool is no mode: \(String(describing: c.typedAttributes(CommonAttributes.self).touchDisabledState))")
        }
        if case .known(.onlyMe)? = try component(#"{"type": "View", "touchDisabledState": "onlyMe"}"#)
            .typedAttributes(CommonAttributes.self).touchDisabledState {} else {
            XCTFail("onlyMe is the declared mode")
        }
    }
}
#endif
