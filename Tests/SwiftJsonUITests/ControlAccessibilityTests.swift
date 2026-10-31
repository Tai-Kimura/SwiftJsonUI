//
//  ControlAccessibilityTests.swift
//  SwiftJsonUITests
//
//  The rule jsonui-cli's codegen applies (shared/core/control_accessibility
//  .rb): accessibilityLabel (alias contentDescription) names the controls a
//  user operates, and a View only when it is one button; a Label's
//  accessibilityLiveRegion is polite / assertive, and off reads nothing.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class ControlAccessibilityTests: XCTestCase {
    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    func testEveryControlTypeIsNamed() throws {
        for type in ["Button", "CheckBox", "Check", "Switch", "Toggle", "Radio", "Segment", "Slider", "SelectBox", "TextField", "EditText"] {
            let c = try component(#"{"type": "\#(type)", "accessibilityLabel": "Name"}"#)
            XCTAssertEqual(ControlAccessibility.label(c, data: [:]), "Name", type)
        }
    }

    func testTheContentDescriptionSpellingReadsTheSame() throws {
        let c = try component(#"{"type": "Button", "text": "Open", "contentDescription": "Name"}"#)
        XCTAssertEqual(ControlAccessibility.label(c, data: [:]), "Name")
    }

    func testABindingIsResolved() throws {
        let c = try component(#"{"type": "Button", "text": "Open", "accessibilityLabel": "@{name}"}"#)
        XCTAssertEqual(ControlAccessibility.label(c, data: ["name": "Open the second image"]), "Open the second image")
    }

    func testAViewIsNamedOnlyWhenItIsOneButton() throws {
        let tapped = try component(#"{"type": "View", "onClick": "@{open}", "accessibilityLabel": "Name", "child": [{"type": "Label", "text": "Card"}]}"#)
        XCTAssertEqual(ControlAccessibility.label(tapped, data: [:]), "Name")
        let still = try component(#"{"type": "View", "accessibilityLabel": "Name", "child": [{"type": "Label", "text": "Card"}]}"#)
        XCTAssertNil(ControlAccessibility.label(still, data: [:]))
        let holdsAControl = try component(#"{"type": "View", "onClick": "@{open}", "accessibilityLabel": "Name", "child": [{"type": "Switch"}]}"#)
        XCTAssertNil(ControlAccessibility.label(holdsAControl, data: [:]))
    }

    func testOtherTypesAndAnEmptyNameAreNotNamed() throws {
        XCTAssertNil(ControlAccessibility.label(try component(#"{"type": "Label", "text": "x", "accessibilityLabel": "Name"}"#), data: [:]))
        XCTAssertNil(ControlAccessibility.label(try component(#"{"type": "Button", "accessibilityLabel": ""}"#), data: [:]))
    }

    func testALabelsLiveRegion() throws {
        XCTAssertEqual(ControlAccessibility.live(try component(#"{"type": "Label", "text": "@{s}", "accessibilityLiveRegion": "polite"}"#)), .polite)
        XCTAssertEqual(ControlAccessibility.live(try component(#"{"type": "Label", "text": "@{s}", "accessibilityLiveRegion": "assertive"}"#)), .assertive)
        XCTAssertNil(ControlAccessibility.live(try component(#"{"type": "Label", "text": "@{s}", "accessibilityLiveRegion": "off"}"#)))
        // iOS has no live region: a View's does nothing.
        XCTAssertNil(ControlAccessibility.live(try component(#"{"type": "View", "accessibilityLiveRegion": "polite"}"#)))
    }
}
#endif
