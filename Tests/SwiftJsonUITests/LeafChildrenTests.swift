//
//  LeafChildrenTests.swift
//  SwiftJsonUITests
//
//  A custom component whose adapter says it takes no children
//  (`acceptsChildren == false`, which `sjui g converter <Name> --no-container`
//  scaffolds) and that a layout gives children: Dynamic draws an error naming
//  the component and the children instead of the component, as `jui build`
//  refuses that layout in codegen. Before 10.29.0 the leaf adapter never read
//  its children and they vanished without a word.
//
//  The drawing is measured by ConformanceHost's LeafChildrenUITests; this is
//  the decision and its text.
//

import XCTest
import SwiftUI
@testable import SwiftJsonUI

#if DEBUG
final class LeafChildrenTests: XCTestCase {
    private struct Leaf: CustomComponentAdapter {
        var componentType: String { "Leaf" }
        var acceptsChildren: Bool { false }
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            AnyView(EmptyView())
        }
    }

    /// An adapter from before 10.29.0: it says nothing, so it takes children.
    private struct Unsaid: CustomComponentAdapter {
        var componentType: String { "Box" }
        func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
            AnyView(EmptyView())
        }
    }

    private func component(_ json: String) throws -> DynamicComponent {
        try JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    func testAnAdapterThatSaysNothingTakesChildren() {
        XCTAssertTrue(Unsaid().acceptsChildren)
        let existential: CustomComponentAdapter = Leaf()
        XCTAssertFalse(existential.acceptsChildren, "the leaf's own value, through the protocol")
    }

    /// The shared table: the sentence, and when there is none — the same
    /// cases the Android wrapper kjui writes is run against.
    func testTheSharedVectors() throws {
        let data = try TestFixtures.loadJSON(named: "leaf_children_vectors")
        let table = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cases = try XCTUnwrap(table["cases"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty)
        for vector in cases {
            let name = vector["name"] as? String ?? "?"
            let json = try JSONSerialization.data(withJSONObject: try XCTUnwrap(vector["component"]))
            let leaf = try JSONDecoder().decode(DynamicComponent.self, from: json)
            XCTAssertEqual(LeafChildren.rejection(for: Leaf(), component: leaf), vector["expected"] as? String, name)
        }
    }

    func testNothingToRefuse() throws {
        XCTAssertNil(LeafChildren.rejection(for: Leaf(), component: try component(#"{"type": "Leaf", "id": "a"}"#)))
        XCTAssertNil(LeafChildren.rejection(for: Leaf(), component: try component(#"{"type": "Leaf", "id": "a", "child": []}"#)))
        XCTAssertNil(LeafChildren.rejection(for: Leaf(), component: try component(#"{"type": "Leaf", "child": [{"data": [{"name": "x", "class": "String"}]}]}"#)),
                     "a data definition is not a child")
        // The control: the same children, an adapter that takes them.
        XCTAssertNil(LeafChildren.rejection(for: Unsaid(), component: try component(#"{"type": "Box", "child": [{"type": "Label", "text": "x"}]}"#)))
    }
}
#endif
