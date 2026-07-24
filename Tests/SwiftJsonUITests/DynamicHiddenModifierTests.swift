//
//  DynamicHiddenModifierTests.swift
//  SwiftJsonUITests
//
//  Regression tests for DynamicModifierHelper.applyHidden — a binding-resolved
//  `hidden` must produce the SAME observable mechanism as the literal
//  `hidden: true` path (.hidden(): out of the accessibility tree, layout space
//  preserved). The former fallback `.opacity(isHidden ? 0 : 1)` kept the
//  element visible to XCUITest (conformance fixture
//  common/hidden__binding_negation failed with "Expected not visible").
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class DynamicHiddenModifierTests: XCTestCase {

    // MARK: - Helpers

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: json.data(using: .utf8)!)
    }

    /// Type name of the AnyView's erased storage — lets us compare the exact
    /// modifier mechanism (e.g. ModifiedContent<AnyView, _HiddenModifier>)
    /// without hard-coding SwiftUI internal type names.
    private func storageTypeName(_ view: AnyView) -> String {
        let mirror = Mirror(reflecting: view)
        if let storage = mirror.children.first(where: { $0.label == "storage" })?.value {
            return String(describing: type(of: storage))
        }
        return String(describing: type(of: view)) // fallback if layout changes
    }

    private var baseView: AnyView { AnyView(Text("probe")) }

    /// The mechanism the literal path uses: AnyView(view.hidden())
    private var literalHiddenTypeName: String {
        storageTypeName(AnyView(baseView.hidden()))
    }

    /// The unmodified pass-through mechanism
    private var passthroughTypeName: String {
        storageTypeName(baseView)
    }

    // MARK: - Literal path (baseline)

    func testLiteralHiddenTrueUsesHiddenModifier() throws {
        let c = try component("""
        { "type": "View", "hidden": true }
        """)
        let result = DynamicModifierHelper.applyHidden(baseView, component: c)
        XCTAssertEqual(storageTypeName(result), literalHiddenTypeName)
    }

    func testLiteralHiddenFalseIsPassthrough() throws {
        let c = try component("""
        { "type": "View", "hidden": false }
        """)
        let result = DynamicModifierHelper.applyHidden(baseView, component: c)
        XCTAssertEqual(storageTypeName(result), passthroughTypeName)
    }

    func testVisibilityGoneUsesHiddenModifier() throws {
        let c = try component("""
        { "type": "View", "visibility": "gone" }
        """)
        let result = DynamicModifierHelper.applyHidden(baseView, component: c)
        XCTAssertEqual(storageTypeName(result), literalHiddenTypeName)
    }

    // MARK: - Binding path, plain value (the regression)

    func testBindingHiddenTruePlainValueMatchesLiteralMechanism() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isHidden": true])
        // MUST be the same mechanism as literal hidden: true — NOT opacity(0)
        XCTAssertEqual(storageTypeName(result), literalHiddenTypeName)
        XCTAssertFalse(storageTypeName(result).lowercased().contains("opacity"))
    }

    func testBindingHiddenFalsePlainValueIsPassthrough() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isHidden": false])
        // The old fallback wrapped in .opacity(1) even when visible —
        // resolved-false must now leave the view untouched.
        XCTAssertEqual(storageTypeName(result), passthroughTypeName)
    }

    /// The exact fixture shape that failed: hidden: "@{!flag}" with flag=false
    /// resolves to hidden=true — the element must leave the accessibility tree.
    func testBindingNegationResolvedTrueMatchesLiteralMechanism() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{!isShown}" }
        """)
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isShown": false])
        XCTAssertEqual(storageTypeName(result), literalHiddenTypeName)
    }

    func testBindingNegationResolvedFalseIsPassthrough() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{!isShown}" }
        """)
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isShown": true])
        XCTAssertEqual(storageTypeName(result), passthroughTypeName)
    }

    func testBindingMissingKeyFallsBackToVisible() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{missing}" }
        """)
        let result = DynamicModifierHelper.applyHidden(baseView, component: c, data: [:])
        XCTAssertEqual(storageTypeName(result), passthroughTypeName)
    }

    // MARK: - Binding path, reactive SwiftUI.Binding<Bool>

    func testReactiveBindingUsesReactiveHiddenWrapper() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        var flag = true
        let binding = SwiftUI.Binding<Bool>(get: { flag }, set: { flag = $0 })
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isHidden": binding])
        XCTAssertTrue(storageTypeName(result).contains("ReactiveHiddenWrapper"))
    }

    func testReactiveNegatedBindingUsesReactiveHiddenWrapper() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{!isShown}" }
        """)
        var flag = false
        let binding = SwiftUI.Binding<Bool>(get: { flag }, set: { flag = $0 })
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isShown": binding])
        XCTAssertTrue(storageTypeName(result).contains("ReactiveHiddenWrapper"))
    }

    // MARK: - ReactiveHiddenWrapper mechanism parity

    /// ReactiveHiddenWrapper's hidden branch must also use .hidden()
    /// (it does — this locks the parity in).
    func testReactiveHiddenWrapperHiddenBranchUsesHiddenModifier() {
        var flag = true
        let binding = SwiftUI.Binding<Bool>(get: { flag }, set: { flag = $0 })
        let wrapper = ReactiveHiddenWrapper(isHidden: binding, content: baseView)
        let bodyName = String(describing: type(of: wrapper.body))
        // _ConditionalContent branch types carry the .hidden() ModifiedContent
        XCTAssertTrue(bodyName.contains("Hidden"), "body type was \(bodyName)")
        XCTAssertFalse(bodyName.lowercased().contains("opacity"))
    }
}
#endif // DEBUG
