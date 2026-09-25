//
//  CustomContainerAccessibilityTests.swift
//  SwiftJsonUITests
//
//  A project's own component (drawn by a registered CustomComponentAdapter)
//  that the layout gives children is made an explicit accessibility container
//  before its identifier, as the built-in containers are — otherwise the bare
//  identifier is pushed down onto the children and replaces theirs (measured
//  on iOS 26.5, 2026-09-25: one child's id found 0 times, the container's found
//  on it; ConformanceHost's CustomContainerIdUITests is the measurement).
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class CustomContainerAccessibilityTests: XCTestCase {
    private struct Box: CustomComponentAdapter {
        var componentType: String { "CustomContainerProbeBox" }
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            AnyView(EmptyView())
        }
    }

    override func setUp() {
        super.setUp()
        CustomComponentRegistry.shared.register(Box())
    }

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    func testARegisteredComponentWithChildrenIsAContainer() throws {
        let box = try component(#"{"type": "CustomContainerProbeBox", "id": "box", "child": [{"type": "Label", "id": "kid", "text": "x"}]}"#)
        XCTAssertTrue(DynamicModifierHelper.isAccessibilityContainer(box))
    }

    func testWithoutChildrenItIsNot() throws {
        XCTAssertFalse(DynamicModifierHelper.isAccessibilityContainer(try component(#"{"type": "CustomContainerProbeBox", "id": "box"}"#)))
        XCTAssertFalse(DynamicModifierHelper.isAccessibilityContainer(
            try component(#"{"type": "CustomContainerProbeBox", "id": "box", "child": [{"data": [{"name": "x", "class": "String"}]}]}"#)),
            "a data definition is not a child")
    }

    func testAnUnregisteredTypeIsNotOne() throws {
        // No adapter draws it (Dynamic shows "Unknown component type"), so
        // there is no content slot to protect.
        XCTAssertFalse(DynamicModifierHelper.isAccessibilityContainer(
            try component(#"{"type": "NobodyRegisteredThis", "id": "x", "child": [{"type": "Label", "text": "x"}]}"#)))
    }

    func testTheBuiltInContainersAreUnchanged() throws {
        XCTAssertTrue(DynamicModifierHelper.isAccessibilityContainer(try component(#"{"type": "View", "id": "v"}"#)))
        XCTAssertFalse(DynamicModifierHelper.isAccessibilityContainer(try component(#"{"type": "Label", "id": "l", "text": "x"}"#)))
    }
}
#endif
