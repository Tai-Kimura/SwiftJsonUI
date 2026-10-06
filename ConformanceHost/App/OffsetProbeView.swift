//
//  OffsetProbeView.swift
//  ConformanceHost
//
//  offsetX moves the drawn box on every leaf type, in Dynamic as in codegen.
//  Until SwiftJsonUI 10.29.7 the Dynamic Label, Button, TextView and SelectBox
//  built their own modifier chain without the offset stage, so offsetX moved
//  nothing (measured: Label / Button / TextView drawn at the margin, x = 20,
//  where codegen and Android draw 25; ticket sjui-dynamic-offsetx-is-not-
//  applied-to-label-button-and-textview). Image runs the standard chain and is
//  the control. NOT part of the conformance suite; launch with `-offsetPlacementProbe`
//  (the Dynamic half) or `-offsetPlacementProbeCodegen` (the generated half). Its test
//  (OffsetProbeUITests) is NOT opt-in.
//
//  Each type appears twice, each copy the only child of a fixed 300 x 60
//  parent: with offsetX 5 (`*_of_<t>_off`) and without (`*_of_<t>_no`). The
//  test reads each copy relative to its parent, so the offset is the
//  difference whatever box the type's id names.
//
//  The generated half: ProbeLayouts/probe_offset.json.
//

import SwiftUI
import SwiftJsonUI

struct OffsetProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_of_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_of_p_label_off", "width": 300, "height": 60, "child": [{"type": "Label", "text": "Label", "id": "dyn_of_label_off", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00", "offsetX": 5}]}, {"type": "View", "id": "dyn_of_p_label_no", "width": 300, "height": 60, "child": [{"type": "Label", "text": "Label", "id": "dyn_of_label_no", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_of_p_button_off", "width": 300, "height": 60, "child": [{"type": "Button", "text": "Button", "id": "dyn_of_button_off", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00", "offsetX": 5}]}, {"type": "View", "id": "dyn_of_p_button_no", "width": 300, "height": 60, "child": [{"type": "Button", "text": "Button", "id": "dyn_of_button_no", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_of_p_textview_off", "width": 300, "height": 60, "child": [{"type": "TextView", "hint": "Text", "id": "dyn_of_textview_off", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00", "offsetX": 5}]}, {"type": "View", "id": "dyn_of_p_textview_no", "width": 300, "height": 60, "child": [{"type": "TextView", "hint": "Text", "id": "dyn_of_textview_no", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_of_p_selectbox_off", "width": 300, "height": 60, "child": [{"type": "SelectBox", "hint": "Pick", "items": ["a", "b"], "id": "dyn_of_selectbox_off", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00", "offsetX": 5}]}, {"type": "View", "id": "dyn_of_p_selectbox_no", "width": 300, "height": 60, "child": [{"type": "SelectBox", "hint": "Pick", "items": ["a", "b"], "id": "dyn_of_selectbox_no", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_of_p_image_off", "width": 300, "height": 60, "child": [{"type": "Image", "srcName": "conformance_sample", "id": "dyn_of_image_off", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00", "offsetX": 5}]}, {"type": "View", "id": "dyn_of_p_image_no", "width": 300, "height": 60, "child": [{"type": "Image", "srcName": "conformance_sample", "id": "dyn_of_image_no", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "offset probe (codegen)" : "offset probe").accessibilityIdentifier("of_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_offset") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("of_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
