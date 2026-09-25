//
//  LeafChildrenProbeView.swift
//  ConformanceHost
//
//  A custom component scaffolded as a leaf (`sjui g converter <Name>
//  --no-container`) that a layout gives children. NOT part of the conformance
//  suite; launch with `-leafChildren`. Its test (LeafChildrenUITests) is NOT
//  opt-in: it runs wherever this host's UI tests run.
//
//  Before 10.29.0 the leaf adapter never read its children: they were not
//  drawn and nothing said so (XCUITest, iOS 26.5, 2026-09-25), while
//  `jui build` now refuses the same layout. Dynamic draws an error naming the
//  component and the children in the component's place instead.
//
//  LeafChildren/ holds what sjui 1.8.121 generates for three components —
//  `--container`, the default and `--no-container` — views and adapters as
//  written, except the leaf's body, which draws its title so the test can
//  tell a drawn leaf from a refused one. `lp_control` is the instrument's
//  positive control: one plain view, which must count 1.
//

import SwiftUI
import SwiftJsonUI

struct LeafChildrenProbeView: View {
    static let shapes: [(String, String)] = [
        ("wrap_leaf", #"{"type": "LeafProbeLeaf", "id": "lp_leaf", "title": "leaf drawn", "child": [{"type": "Label", "id": "lp_leaf_kid", "text": "Leaf kid"}]}"#),
        ("wrap_leaf_alone", #"{"type": "LeafProbeLeaf", "id": "lp_leaf_alone", "title": "alone drawn"}"#),
        ("wrap_auto", #"{"type": "LeafProbeAuto", "id": "lp_auto", "title": "auto", "child": [{"type": "Label", "id": "lp_auto_kid", "text": "Auto kid"}]}"#),
        ("wrap_shelf", #"{"type": "LeafProbeShelf", "id": "lp_shelf", "title": "shelf", "child": [{"type": "Label", "id": "lp_shelf_kid", "text": "Shelf kid"}]}"#),
    ]

    init() {
        CustomComponentRegistry.shared.registerAll([
            LeafProbeShelfAdapter(), LeafProbeAutoAdapter(), LeafProbeLeafAdapter(),
        ])
    }

    private static func component(_ json: String) -> DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("leaf children probe").accessibilityIdentifier("lp_ready")
                ForEach(Self.shapes, id: \.0) { shape in
                    Group {
                        if let component = Self.component(shape.1) {
                            DynamicComponentBuilder(component: component, data: [:])
                        } else {
                            Text("did not decode").accessibilityIdentifier("lp_decode_failed")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(shape.0)
                }
                Text("control").accessibilityIdentifier("lp_control")
            }
            .padding(.horizontal)
        }
    }
}
