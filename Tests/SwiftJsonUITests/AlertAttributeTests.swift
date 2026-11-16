//
//  AlertAttributeTests.swift
//  SwiftJsonUITests
//
//  `alert` cannot have a conformance fixture: it lands in the same skip class
//  as `confirmationDialog` — a modal is presented OVER the render surface, so
//  a screenshot of the surface asserts nothing about it. What CAN be pinned
//  here is the seam the attribute travels through: the generated typed
//  attribute, and the shared text resolution both dialogs use.
//
//  The rendering difference that justifies a separate attribute (in a regular
//  size class `.confirmationDialog` draws no cancel button while `.alert`
//  draws it in both) is a UI-level fact measured by the ConformanceHost probe;
//  it is not assertable from here.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class AlertAttributeTests: XCTestCase {

    // The typed attribute exists and carries the declaration through. This is
    // the regeneration guard: CommonAttributes is generated from the SSoT, so
    // a regeneration against a definitions file without `alert` fails here
    // rather than silently emitting nothing at runtime.
    func testGeneratedAttributeCarriesTheDeclaration() {
        let attrs = CommonAttributes(json: [
            "alert": [
                "isPresented": "@{showAlert}",
                "title": "Confirm",
                "message": "Sure?",
                "actions": "@{alertActions}"
            ]
        ])

        XCTAssertNotNil(attrs.alert)
        XCTAssertEqual(attrs.alert?["isPresented"] as? String, "@{showAlert}")
        XCTAssertEqual(attrs.alert?["title"] as? String, "Confirm")
        XCTAssertEqual(attrs.alert?["actions"] as? String, "@{alertActions}")
    }

    // `alert` and `confirmationDialog` are independent declarations: one
    // present must not populate the other. They apply as two modifiers, so a
    // component may legitimately carry both.
    func testTheTwoDeclarationsDoNotBleedIntoEachOther() {
        let onlyAlert = CommonAttributes(json: ["alert": ["isPresented": "@{a}"]])
        XCTAssertNotNil(onlyAlert.alert)
        XCTAssertNil(onlyAlert.confirmationDialog)

        let onlyDialog = CommonAttributes(json: ["confirmationDialog": ["isPresented": "@{d}"]])
        XCTAssertNotNil(onlyDialog.confirmationDialog)
        XCTAssertNil(onlyDialog.alert)
    }

    // A non-object declaration must not become an empty configuration: the
    // builder would then read a nil isPresented and skip, which is the same
    // outcome, but through a coercion that quietly invented a value.
    func testNonObjectDeclarationCoercesToNil() {
        XCTAssertNil(CommonAttributes(json: ["alert": "yes"]).alert)
        XCTAssertNil(CommonAttributes(json: ["alert": 42]).alert)
    }

    // Title and message travel the SAME resolution both dialogs use — a bound
    // spelling resolves, a key spelling reaches the string table, and an
    // unresolvable binding does not surface as the expression. If `alert`
    // ever grows its own text path, these tests move with it.
    func testTitleAndMessageUseTheSharedResolution() {
        XCTAssertEqual(
            DynamicModifierHelper.confirmationDialogText("@{alertTitle}", data: ["alertTitle": "Remove?"]),
            "Remove?"
        )
        XCTAssertNil(DynamicModifierHelper.confirmationDialogText("@{missingKey}", data: [:]))
    }

    // Applying the modifier without a usable declaration must be a no-op
    // rather than a crash: an absent binding, a missing isPresented, and a
    // present isPresented whose data entry is not a Bool binding.
    @available(iOS 15.0, *)
    func testUnusableDeclarationsApplyNothing() throws {
        let base = AnyView(Text("host"))

        _ = DynamicModifierHelper.applyAlert(
            base, component: try component("{\"type\": \"View\"}"), data: [:]
        )
        _ = DynamicModifierHelper.applyAlert(
            base,
            component: try component("{\"type\": \"View\", \"alert\": {\"title\": \"no isPresented\"}}"),
            data: [:]
        )
        _ = DynamicModifierHelper.applyAlert(
            base,
            component: try component("{\"type\": \"View\", \"alert\": {\"isPresented\": \"@{flag}\"}}"),
            data: ["flag": "not a binding"]
        )
    }

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }
}
#endif
