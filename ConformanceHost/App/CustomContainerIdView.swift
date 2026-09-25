//
//  CustomContainerIdView.swift
//  ConformanceHost
//
//  Every identifier inside a custom container is found exactly once — the
//  children's and the container's own. NOT part of the conformance suite;
//  launch with `-customContainerId`. Its test (CustomContainerIdUITests) is
//  NOT opt-in: it runs wherever this host's UI tests run.
//
//  A custom container's id replaced its children's identifiers on iOS: the
//  identifier went on bare, and SwiftUI pushed it down onto the elements
//  inside (XCUITest, iOS 26.5, 2026-09-25). Only built-in container types were
//  made explicit accessibility containers first. Ticket
//  sjui-custom-container-takes-its-childrens-identifiers.
//
//  The components are the ones LeafChildrenProbeView registers, as
//  `sjui g converter` generates them (App/LeafChildren/). In the codegen host
//  the same shapes also appear as sjui GENERATED them —
//  ProbeLayouts/probe_custom_container.json, its converters scaffolded from
//  ProbeLayouts/extensions/components.json, ids prefixed `cg_` — with the
//  marker `cc_codegen` beside them. `cc_dup` is the instrument's positive
//  control: one id on two plain views, which must count 2.
//

import SwiftUI
import SwiftJsonUI

struct CustomContainerIdView: View {
    static let shapes: [(String, String)] = [
        ("wrap_cc_one", #"{"type": "LeafProbeAuto", "id": "cc_one", "title": "one", "child": [{"type": "Label", "id": "cc_one_kid", "text": "One kid"}]}"#),
        ("wrap_cc_two", #"{"type": "LeafProbeAuto", "id": "cc_two", "title": "two", "child": [{"type": "Label", "id": "cc_two_a", "text": "Two a"}, {"type": "Label", "id": "cc_two_b", "text": "Two b"}]}"#),
        ("wrap_cc_nest", #"{"type": "LeafProbeAuto", "id": "cc_nest", "title": "nest", "child": [{"type": "View", "id": "cc_nest_view", "orientation": "vertical", "child": [{"type": "Label", "id": "cc_nest_kid", "text": "Nest kid"}]}]}"#),
        ("wrap_cc_noid", #"{"type": "LeafProbeAuto", "title": "noid", "child": [{"type": "Label", "id": "cc_noid_kid", "text": "No-id kid"}]}"#),
        ("wrap_cc_shelf", #"{"type": "LeafProbeShelf", "id": "cc_shelf", "title": "shelf", "child": [{"type": "Label", "id": "cc_shelf_kid", "text": "Shelf kid"}]}"#),
        ("wrap_cc_tap", #"{"type": "LeafProbeAuto", "id": "cc_tap", "title": "tap", "onClick": "@{onTap}", "child": [{"type": "Label", "id": "cc_tap_kid", "text": "Tap kid"}]}"#),
        ("wrap_cc_tapnoid", #"{"type": "LeafProbeAuto", "title": "tapnoid", "onClick": "@{onTap}", "child": [{"type": "Label", "id": "cc_tapnoid_kid", "text": "Tap no-id kid"}]}"#),
        // The built-in control: a View with an id and one child.
        ("wrap_cc_view", #"{"type": "View", "id": "cc_view", "orientation": "vertical", "child": [{"type": "Label", "id": "cc_view_kid", "text": "View kid"}]}"#),
    ]

    init() {
        CustomComponentRegistry.shared.registerAll([LeafProbeShelfAdapter(), LeafProbeAutoAdapter()])
    }

    private static func component(_ json: String) -> DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("custom container probe").accessibilityIdentifier("cc_ready")
                ForEach(Self.shapes, id: \.0) { shape in
                    Group {
                        if let component = Self.component(shape.1) {
                            DynamicComponentBuilder(component: component, data: ["onTap": { () -> Void in }])
                        } else {
                            Text("did not decode").accessibilityIdentifier("cc_decode_failed")
                        }
                    }
                    // The anchor the library puts on a container with one
                    // child: without it this wrapper and the container inside
                    // merge and the inner identifier is dropped — measured,
                    // a built-in View's id read 0 here while codegen's
                    // (whose generated wrapper carries the anchor) read 1.
                    .overlay(alignment: .topLeading) {
                        Color.clear
                            .frame(width: 0.5, height: 0.5)
                            .accessibilityElement(children: .ignore)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(shape.0)
                }
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_custom_container") {
                    Text("codegen shapes").accessibilityIdentifier("cc_codegen")
                    generated
                }
                // The positive control: two elements, one id.
                Text("dup one").accessibilityIdentifier("cc_dup")
                Text("dup two").accessibilityIdentifier("cc_dup")
            }
            .padding(.horizontal)
        }
    }
}
