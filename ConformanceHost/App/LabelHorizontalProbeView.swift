//
//  LabelHorizontalProbeView.swift
//  ConformanceHost
//
//  Where a Label's text sits across a frame wider than it: textAlign, else
//  the horizontal part of its gravity (left, right, centerHorizontal,
//  center), else the start — the SSoT's Label.textAlign, the user's ruling
//  of 2026-09-27 ("align iOS to start"). The lines of a multi-line Label
//  follow the same rule. Until jsonui-cli 1.9.0 / SwiftJsonUI 10.29.0 a
//  fixed-width Label with neither textAlign nor gravity drew its text in the
//  middle, and a Label's gravity did not place its text across its frame nor
//  align its lines. On the Dynamic renderer and — in the codegen host — as
//  sjui generates it. NOT part of the conformance suite; launch with
//  `-labelHorizontalProbe` (the Dynamic half) or
//  `-labelHorizontalProbeCodegen` (the generated half). Its test
//  (LabelHorizontalProbeUITests) is NOT opt-in.
//
//  Each row is a white View around one Label (black, 14pt); the test reads
//  where the text's ink sits in the row, line by line. A fixed-width row is
//  the Label's width; a multi-line one is its longest line's. The rows and
//  what they expect are in LabelHorizontalProbeUITests.
//
//  The generated half: ProbeLayouts/probe_label_horizontal.json.
//

import SwiftUI
import SwiftJsonUI

struct LabelHorizontalProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_lh_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 6, "child": [{"type": "View", "id": "dyn_lh_w50_none", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w50_none_label", "fontColor": "#000000", "fontSize": 14, "width": 50, "text": "Mon"}]}, {"type": "View", "id": "dyn_lh_w70_none", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w70_none_label", "fontColor": "#000000", "fontSize": 14, "width": 70, "text": "Peaty"}]}, {"type": "View", "id": "dyn_lh_w110_none", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w110_none_label", "fontColor": "#000000", "fontSize": 14, "width": 110, "text": "Region"}]}, {"type": "View", "id": "dyn_lh_w32_right", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w32_right_label", "fontColor": "#000000", "fontSize": 14, "width": 32, "text": "7", "gravity": "right"}]}, {"type": "View", "id": "dyn_lh_w200h44_none", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w200h44_none_label", "fontColor": "#000000", "fontSize": 14, "width": 200, "height": 44, "text": "Go"}]}, {"type": "View", "id": "dyn_lh_w200_center", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w200_center_label", "fontColor": "#000000", "fontSize": 14, "width": 200, "text": "Go", "gravity": "center"}]}, {"type": "View", "id": "dyn_lh_w200_chz", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w200_chz_label", "fontColor": "#000000", "fontSize": 14, "width": 200, "text": "Go", "gravity": "centerHorizontal"}]}, {"type": "View", "id": "dyn_lh_mw_right", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_mw_right_label", "fontColor": "#000000", "fontSize": 14, "width": "matchParent", "text": "Go", "gravity": "right"}]}, {"type": "View", "id": "dyn_lh_weighted_right", "orientation": "horizontal", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_weighted_right_label", "fontColor": "#000000", "fontSize": 14, "width": 0, "weight": 1, "text": "Go", "gravity": "right"}]}, {"type": "View", "id": "dyn_lh_w200_left", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w200_left_label", "fontColor": "#000000", "fontSize": 14, "width": 200, "text": "Go", "gravity": "left"}]}, {"type": "View", "id": "dyn_lh_w200_tac", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w200_tac_label", "fontColor": "#000000", "fontSize": 14, "width": 200, "text": "Go", "textAlign": "center"}]}, {"type": "View", "id": "dyn_lh_w200_tar_gleft", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_w200_tar_gleft_label", "fontColor": "#000000", "fontSize": 14, "width": 200, "text": "Go", "textAlign": "right", "gravity": "left"}]}, {"type": "View", "id": "dyn_lh_ml_none", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_ml_none_label", "fontColor": "#000000", "fontSize": 14, "text": "Go\nGo Go Go Go", "lines": 0}]}, {"type": "View", "id": "dyn_lh_ml_center", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_ml_center_label", "fontColor": "#000000", "fontSize": 14, "text": "Go\nGo Go Go Go", "lines": 0, "gravity": "center"}]}, {"type": "View", "id": "dyn_lh_ml_right", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_ml_right_label", "fontColor": "#000000", "fontSize": 14, "text": "Go\nGo Go Go Go", "lines": 0, "gravity": "right"}]}, {"type": "View", "id": "dyn_lh_ml_tac", "orientation": "vertical", "width": "wrapContent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Label", "id": "dyn_lh_ml_tac_label", "fontColor": "#000000", "fontSize": 14, "text": "Go\nGo Go Go Go", "lines": 0, "textAlign": "center"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "label horizontal probe (codegen)" : "label horizontal probe").accessibilityIdentifier("lh_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_label_horizontal") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("lh_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
