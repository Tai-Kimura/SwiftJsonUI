//
//  LeafGravityProbeView.swift
//  ConformanceHost
//
//  A LEAF's partial gravity fixes only its own axis: the axis it does not
//  name stays centred (4f 2026-09-27, measured: Compose and the web centre a
//  Button's and a TextField's text vertically in a 44pt frame whatever the
//  gravity). On the Dynamic renderer and — in the codegen host — as sjui
//  generates it. NOT part of the conformance suite; launch with
//  `-leafGravityProbe` (the Dynamic half) or `-leafGravityProbeCodegen` (the
//  generated half). Its test (LeafGravityProbeUITests) is NOT opt-in.
//
//  Each row is a white matchParent View around one 44pt-tall leaf with black
//  text; the test reads where the text's ink sits in the row.
//  - `*_lg_tf_mw_h_left`: a matchParent TextField, gravity left — its text
//    centred vertically. It sat at the top (5pt down, 27pt up from the
//    bottom).
//  - `*_lg_tf_w_h_left`: a 200 × 44 TextField, gravity left — the same, on
//    the frame that sizes both axes.
//  - controls, centred before and after: `*_lg_btn_mw_h_left` and
//    `*_lg_btn_w_h_left`, a Button with gravity left (StateAwareButtonView
//    sizes and centres its own label, so the outer frame's alignment does
//    not reach it); `*_lg_btn_mw_h_center`, gravity center;
//    `*_lg_label_mw_h_left`, a Label with gravity left (a Label is not in
//    this rule).
//
//  The generated half: ProbeLayouts/probe_leaf_gravity.json.
//

import SwiftUI
import SwiftJsonUI

struct LeafGravityProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_lg_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 8, "child": [{"type": "View", "id": "dyn_lg_btn_mw_h_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "id": "dyn_lg_btn_mw_h_left_leaf", "width": "matchParent", "gravity": "left"}]}, {"type": "View", "id": "dyn_lg_btn_w_h_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "id": "dyn_lg_btn_w_h_left_leaf", "width": 200, "gravity": "left"}]}, {"type": "View", "id": "dyn_lg_tf_mw_h_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "TextField", "id": "dyn_lg_tf_mw_h_left_leaf", "text": "@{value}", "fontColor": "#000000", "background": "#DDDDDD", "width": "matchParent", "height": 44, "gravity": "left"}]}, {"type": "View", "id": "dyn_lg_tf_w_h_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "TextField", "id": "dyn_lg_tf_w_h_left_leaf", "text": "@{value}", "fontColor": "#000000", "background": "#DDDDDD", "width": 200, "height": 44, "gravity": "left"}]}, {"type": "View", "id": "dyn_lg_btn_mw_h_center", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "id": "dyn_lg_btn_mw_h_center_leaf", "width": "matchParent", "gravity": "center"}]}, {"type": "View", "id": "dyn_lg_label_mw_h_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lg_label_mw_h_left_leaf", "text": "Go", "fontColor": "#000000", "width": "matchParent", "height": 44, "gravity": "left"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "leaf gravity probe (codegen)" : "leaf gravity probe").accessibilityIdentifier("lg_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_leaf_gravity") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: ["value": "Hello"])
            } else {
                Text("did not decode").accessibilityIdentifier("lg_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
