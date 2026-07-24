//
//  DynamicHiddenModifierTests.swift
//  SwiftJsonUITests
//
//  Canonical spec: `hidden: true` is the boolean shorthand for
//  visibility:"invisible" — the view KEEPS its layout space, is not drawn,
//  and is removed from the accessibility tree. It must NOT collapse (that
//  is visibility:"gone").
//
//  These tests lock in the invisible mechanism (opacity(0) +
//  .accessibilityElement(children: .ignore) + .accessibilityHidden(true),
//  mirroring VisibilityWrapper.invisible) on every path:
//  - DynamicModifierHelper.applyHidden (off-builder fallback): literal,
//    plain binding, reactive binding (ReactiveHiddenWrapper)
//  - DynamicComponentBuilder.buildWithVisibility: literal hidden maps to
//    VisibilityWrapper("invisible"), binding hidden maps to
//    "invisible"/"visible" (plain and reactive)
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
    /// modifier mechanism without hard-coding SwiftUI internal type names.
    private func storageTypeName(_ view: AnyView) -> String {
        let mirror = Mirror(reflecting: view)
        if let storage = mirror.children.first(where: { $0.label == "storage" })?.value {
            return String(describing: type(of: storage))
        }
        return String(describing: type(of: view)) // fallback if layout changes
    }

    private var baseView: AnyView { AnyView(Text("probe")) }

    /// Self-calibrated reference for the invisible mechanism
    /// (mirrors VisibilityWrapper's `.invisible` branch).
    private var invisibleReferenceTypeName: String {
        storageTypeName(AnyView(
            baseView.opacity(0)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(true)
        ))
    }

    /// The mechanism visibility:"gone" still uses off-builder: AnyView(view.hidden())
    private var hiddenModifierTypeName: String {
        storageTypeName(AnyView(baseView.hidden()))
    }

    /// The unmodified pass-through mechanism
    private var passthroughTypeName: String {
        storageTypeName(baseView)
    }

    // MARK: - Literal path

    func testLiteralHiddenTrueUsesInvisibleMechanism() throws {
        let c = try component("""
        { "type": "View", "hidden": true }
        """)
        let result = DynamicModifierHelper.applyHidden(baseView, component: c)
        // hidden == invisible: space kept + accessibility-hidden — NOT bare .hidden()
        XCTAssertEqual(storageTypeName(result), invisibleReferenceTypeName)
        XCTAssertNotEqual(storageTypeName(result), hiddenModifierTypeName)
    }

    func testLiteralHiddenFalseIsPassthrough() throws {
        let c = try component("""
        { "type": "View", "hidden": false }
        """)
        let result = DynamicModifierHelper.applyHidden(baseView, component: c)
        XCTAssertEqual(storageTypeName(result), passthroughTypeName)
    }

    /// visibility:"gone" literal handling stays as-is (.hidden() fallback).
    func testVisibilityGoneKeepsHiddenModifier() throws {
        let c = try component("""
        { "type": "View", "visibility": "gone" }
        """)
        let result = DynamicModifierHelper.applyHidden(baseView, component: c)
        XCTAssertEqual(storageTypeName(result), hiddenModifierTypeName)
    }

    // MARK: - Binding path, plain value

    func testBindingHiddenTruePlainValueUsesInvisibleMechanism() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isHidden": true])
        // Same mechanism as literal hidden: true (invisible), not .hidden()
        XCTAssertEqual(storageTypeName(result), invisibleReferenceTypeName)
        XCTAssertNotEqual(storageTypeName(result), hiddenModifierTypeName)
    }

    func testBindingHiddenFalsePlainValueIsPassthrough() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isHidden": false])
        XCTAssertEqual(storageTypeName(result), passthroughTypeName)
    }

    /// hidden: "@{!flag}" with flag=false resolves to hidden=true — the
    /// element keeps its space but leaves the accessibility tree.
    func testBindingNegationResolvedTrueUsesInvisibleMechanism() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{!isShown}" }
        """)
        let result = DynamicModifierHelper.applyHidden(
            baseView, component: c, data: ["isShown": false])
        XCTAssertEqual(storageTypeName(result), invisibleReferenceTypeName)
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

    /// ReactiveHiddenWrapper's hidden branch must use the invisible
    /// mechanism (space kept + accessibility-hidden), not bare .hidden().
    func testReactiveHiddenWrapperHiddenBranchUsesInvisibleMechanism() {
        var flag = true
        let binding = SwiftUI.Binding<Bool>(get: { flag }, set: { flag = $0 })
        let wrapper = ReactiveHiddenWrapper(isHidden: binding, content: baseView)
        let bodyName = String(describing: type(of: wrapper.body))
        // Self-calibrated: the true branch type is exactly the invisible chain
        // applied to the AnyView content.
        let reference = String(describing: type(of:
            baseView.opacity(0)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(true)
        ))
        XCTAssertTrue(bodyName.contains(reference), "body type was \(bodyName)")
    }

    // MARK: - Builder-level mapping (hidden == visibility:"invisible")

    /// Recursively search a view tree (via Mirror) for a wrapper whose type
    /// name starts with the given prefix.
    private func findWrapper(in value: Any, typePrefix: String, depth: Int = 0) -> Any? {
        if depth > 16 { return nil }
        if String(describing: type(of: value)).hasPrefix(typePrefix) { return value }
        for child in Mirror(reflecting: value).children {
            if let found = findWrapper(in: child.value, typePrefix: typePrefix, depth: depth + 1) {
                return found
            }
        }
        return nil
    }

    private func visibilityOf(_ wrapper: Any) -> String? {
        Mirror(reflecting: wrapper).children
            .first { $0.label == "visibility" }
            .map { String(describing: $0.value) }
    }

    func testBuilderLiteralHiddenMapsToInvisibleWrapper() throws {
        let c = try component("""
        { "type": "View", "hidden": true }
        """)
        let builder = DynamicComponentBuilder(component: c, data: [:])
        let wrapper = findWrapper(in: builder.body, typePrefix: "VisibilityWrapper<")
        XCTAssertNotNil(wrapper, "literal hidden must wrap in VisibilityWrapper")
        XCTAssertEqual(wrapper.flatMap(visibilityOf), "invisible")
    }

    func testBuilderPlainBindingHiddenTrueMapsToInvisibleWrapper() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        let builder = DynamicComponentBuilder(component: c, data: ["isHidden": true])
        let wrapper = findWrapper(in: builder.body, typePrefix: "VisibilityWrapper<")
        XCTAssertNotNil(wrapper)
        XCTAssertEqual(wrapper.flatMap(visibilityOf), "invisible")
    }

    func testBuilderPlainBindingHiddenFalseMapsToVisibleWrapper() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        let builder = DynamicComponentBuilder(component: c, data: ["isHidden": false])
        let wrapper = findWrapper(in: builder.body, typePrefix: "VisibilityWrapper<")
        XCTAssertNotNil(wrapper)
        XCTAssertEqual(wrapper.flatMap(visibilityOf), "visible")
    }

    func testBuilderReactiveBindingMapsToInvisibleAndBackToVisible() throws {
        let c = try component("""
        { "type": "View", "hidden": "@{isHidden}" }
        """)
        var flag = true
        let binding = SwiftUI.Binding<Bool>(get: { flag }, set: { flag = $0 })
        let builder = DynamicComponentBuilder(component: c, data: ["isHidden": binding])
        let wrapper = findWrapper(in: builder.body, typePrefix: "ReactiveVisibilityWrapper<")
        XCTAssertNotNil(wrapper, "reactive hidden must wrap in ReactiveVisibilityWrapper")
        let visibilityBinding = wrapper.flatMap { w in
            Mirror(reflecting: w).children
                .first { $0.label == "_visibility" }?
                .value as? SwiftUI.Binding<String>
        }
        XCTAssertEqual(visibilityBinding?.wrappedValue, "invisible")
        flag = false
        XCTAssertEqual(visibilityBinding?.wrappedValue, "visible")
    }
}
#endif // DEBUG
