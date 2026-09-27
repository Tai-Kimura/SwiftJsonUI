//
//  LabelVerticalProbeView.swift
//  ConformanceHost
//
//  A Label's text in a box taller than it sits at the vertical its gravity
//  names (top, bottom, centerVertical / center), else at the centre — the
//  canon's leafOwnFrameChannel default for "a text block smaller than its
//  fixed box" (4f 2026-09-27). Until jsonui-cli 1.9.0 / SwiftJsonUI 10.29.0
//  it depended on the frame: a matchParent- or wrapContent-wide Label of
//  height 44 was centred whatever its gravity, a 200 × 44 one put `left` /
//  `right` at the top (and the Dynamic renderer put every declared gravity
//  but `top` at the top too), a matchParent × matchParent or min-height one
//  with no gravity at the top. On the Dynamic renderer and — in the codegen
//  host — as sjui generates it. NOT part of the conformance suite; launch
//  with `-labelVerticalProbe` (the Dynamic half) or
//  `-labelVerticalProbeCodegen` (the generated half). Its test
//  (LabelVerticalProbeUITests) is NOT opt-in.
//
//  Each row is a white View around one Label ("Go", black); the test reads
//  where the text's ink sits in the row. The rows and what they expect are
//  in LabelVerticalProbeUITests.
//
//  The generated half: ProbeLayouts/probe_label_vertical.json.
//

import SwiftUI
import SwiftJsonUI

struct LabelVerticalProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_lv_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 6, "child": [{"type": "View", "id": "dyn_lv_mw_top", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_mw_top_label", "text": "Go", "fontColor": "#000000", "width": "matchParent", "height": 44, "gravity": "top"}]}, {"type": "View", "id": "dyn_lv_mw_bottom", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_mw_bottom_label", "text": "Go", "fontColor": "#000000", "width": "matchParent", "height": 44, "gravity": "bottom"}]}, {"type": "View", "id": "dyn_lv_ww_top", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_ww_top_label", "text": "Go", "fontColor": "#000000", "width": "wrapContent", "height": 44, "gravity": "top"}]}, {"type": "View", "id": "dyn_lv_w200_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_w200_left_label", "text": "Go", "fontColor": "#000000", "width": 200, "height": 44, "gravity": "left"}]}, {"type": "View", "id": "dyn_lv_w200_right", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_w200_right_label", "text": "Go", "fontColor": "#000000", "width": 200, "height": 44, "gravity": "right"}]}, {"type": "View", "id": "dyn_lv_w200_bottom", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_w200_bottom_label", "text": "Go", "fontColor": "#000000", "width": 200, "height": 44, "gravity": "bottom"}]}, {"type": "View", "id": "dyn_lv_w200_cv", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_w200_cv_label", "text": "Go", "fontColor": "#000000", "width": 200, "height": 44, "gravity": "centerVertical"}]}, {"type": "View", "id": "dyn_lv_fill_none", "orientation": "vertical", "width": "matchParent", "height": 60, "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_fill_none_label", "text": "Go", "fontColor": "#000000", "width": "matchParent", "height": "matchParent"}]}, {"type": "View", "id": "dyn_lv_minh_none", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_minh_none_label", "text": "Go", "fontColor": "#000000", "width": "matchParent", "minHeight": 60}]}, {"type": "View", "id": "dyn_lv_mw_none", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_mw_none_label", "text": "Go", "fontColor": "#000000", "width": "matchParent", "height": 44}]}, {"type": "View", "id": "dyn_lv_w200_top", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_w200_top_label", "text": "Go", "fontColor": "#000000", "width": 200, "height": 44, "gravity": "top"}]}, {"type": "View", "id": "dyn_lv_w200_center_tac", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lv_w200_center_tac_label", "text": "Go", "fontColor": "#000000", "width": 200, "height": 44, "gravity": "center", "textAlign": "center"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "label vertical probe (codegen)" : "label vertical probe").accessibilityIdentifier("lv_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_label_vertical") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("lv_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
