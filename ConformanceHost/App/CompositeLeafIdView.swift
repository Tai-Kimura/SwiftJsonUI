//
//  CompositeLeafIdView.swift
//  ConformanceHost
//
//  A composite leaf — a component drawn as several SwiftUI views — is found
//  by its id exactly once, as the element a test driver means. NOT part of
//  the conformance suite; launch with `-compositeLeafId`. Its test
//  (CompositeLeafIdUITests) is NOT opt-in: it runs wherever this host's UI
//  tests run.
//
//  The id goes on these components bare, as on a leaf, and SwiftUI hands an
//  identifier on a view that is not an accessibility element to EVERY element
//  inside it. Measured before the fix (SwiftJsonUI 505a728, iOS 26.5): a tap
//  on a TextField with a clear button pressed the button and emptied the
//  field; an IconLabel's text read returned its icon's name; an empty
//  TextView's text read returned its hint. Ticket
//  sjui-a-composite-leaf-gives-its-id-to-every-element-inside.
//
//  In the codegen host the same shapes also appear as sjui GENERATED them —
//  ProbeLayouts/probe_composite_leaf.json, ids prefixed `cg_` — with the
//  marker `cl_codegen` beside them. `cl_dup` is the instrument's positive
//  control: one id on two plain views, which must count 2.
//

import SwiftUI
import SwiftJsonUI

struct CompositeLeafIdView: View {
    static let shapes: [(String, String)] = [
        // TextField with a clear button, and its control with none.
        ("cl_tf_clear", ##"{"type": "TextField", "id": "cl_tf_clear", "width": 240, "height": 40, "text": "Clear me", "clearButtonMode": "always"}"##),
        ("cl_tf_noclear", ##"{"type": "TextField", "id": "cl_tf_noclear", "width": 240, "height": 40, "text": "Clear me", "clearButtonMode": "never"}"##),
        // TextField with a styled placeholder (an overlay Text), empty.
        ("cl_tf_styled", ##"{"type": "TextField", "id": "cl_tf_styled", "width": 240, "height": 40, "hint": "Styled hint", "hintColor": "#FF0000"}"##),
        // IconLabel, the icon on either side.
        ("cl_il_left", ##"{"type": "IconLabel", "id": "cl_il_left", "text": "Sample", "icon_off": "conformance_sample", "iconPosition": "left"}"##),
        ("cl_il_right", ##"{"type": "IconLabel", "id": "cl_il_right", "text": "Sample", "icon_off": "conformance_sample", "iconPosition": "right"}"##),
        // TextView, empty, with a hint, and its control with none.
        ("cl_tv_hint", ##"{"type": "TextView", "id": "cl_tv_hint", "width": 240, "height": 80, "hint": "Conformance Hint"}"##),
        ("cl_tv_nohint", ##"{"type": "TextView", "id": "cl_tv_nohint", "width": 240, "height": 80}"##),
        // Radio with items: one element containing its options.
        ("cl_radio_items", ##"{"type": "Radio", "id": "cl_radio_items", "width": 240, "height": "wrapContent", "text": "Pick", "items": ["Alpha", "Beta"]}"##),
        // Image with a pressed-state image.
        ("cl_image_hl", ##"{"type": "Image", "id": "cl_image_hl", "width": 140, "height": 80, "src": "conformance_sample", "highlightSrc": "conformance_sample_alt"}"##),
        // The unexplained row: a tappable View whose tap gate is bound.
        ("cl_tap_gate", ##"{"type": "View", "id": "cl_tap_gate", "width": 200, "height": 60, "background": "#DDDDDD", "onClick": "@{onTap}", "canTap": "@{tapGate}", "child": [{"type": "View", "id": "cl_tap_gate_box", "width": 40, "height": 40, "background": "#FF0000"}]}"##),
    ]

    private static func component(_ json: String) -> DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("composite leaf probe").accessibilityIdentifier("cl_ready")
                // Under an explicit accessibility container with an id, as
                // every Dynamic container with an id and every generated root
                // is: a part hidden with `.accessibilityHidden` is found with
                // the id again there (measured), so the shapes are asked in
                // the context they live in.
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Self.shapes, id: \.0) { shape in
                        if let component = Self.component(shape.1) {
                            DynamicComponentBuilder(
                                component: component,
                                data: ["onTap": { () -> Void in }, "tapGate": true]
                            )
                        } else {
                            Text("did not decode").accessibilityIdentifier("cl_decode_failed")
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("cl_root")
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_composite_leaf") {
                    Text("codegen shapes").accessibilityIdentifier("cl_codegen")
                    generated
                }
                // The positive control: two elements, one id.
                Text("dup one").accessibilityIdentifier("cl_dup")
                Text("dup two").accessibilityIdentifier("cl_dup")
            }
            .padding(.horizontal)
        }
    }
}
