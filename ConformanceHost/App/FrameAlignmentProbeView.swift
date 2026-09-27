//
//  FrameAlignmentProbeView.swift
//  ConformanceHost
//
//  A frame that sizes ONE axis of a container puts content smaller than it
//  at top | start (the user's ruling of 2026-09-27; gravityDefaults), as
//  Compose and the web do; a declared center* gravity still centres. On the
//  Dynamic renderer and — in the codegen host — as sjui generates it. NOT
//  part of the conformance suite; launch with `-frameAlignmentProbe` (the
//  Dynamic half) or `-frameAlignmentProbeCodegen` (the generated half). Its
//  test (FrameAlignmentProbeUITests) is NOT opt-in.
//
//  Each box holds one label (28 × 20):
//  - `*_fa_v_mw_h` / `*_fa_z_mw_h`: matchParent × 60, vertical and with no
//    orientation — the label at the top. It was 19pt down.
//  - `*_fa_v_ww_h`: wrapContent × 60 — at the top. It was 19pt down.
//  - `*_fa_v_w_wh`: 200 × wrapContent — at the start. It was 85pt in.
//  - `*_fa_v_w_mh`: 200 × matchParent in a 60pt parent — at the start. It
//    was 85pt in.
//  - `*_fa_c_mw_h`: a `lazy: none` Collection, matchParent × 60 — its cell
//    at the top. It was 20pt down.
//  - controls: `*_fa_v_w_h`, 200 × 60 — top-left, as before;
//    `*_fa_v_mw_h_gcv`, matchParent × 60 with gravity centerVertical —
//    centred, as before.
//
//  The generated half: ProbeLayouts/probe_frame_alignment.json.
//

import SwiftUI
import SwiftJsonUI

struct FrameAlignmentProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_fa_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_fa_v_mw_h", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_fa_v_mw_h_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": "matchParent", "height": 60}, {"type": "View", "id": "dyn_fa_z_mw_h", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_fa_z_mw_h_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "width": "matchParent", "height": 60}, {"type": "View", "id": "dyn_fa_v_ww_h", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_fa_v_ww_h_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": "wrapContent", "height": 60}, {"type": "View", "id": "dyn_fa_v_w_wh", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_fa_v_w_wh_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": 200, "height": "wrapContent"}, {"type": "View", "id": "dyn_fa_v_w_mh_parent", "orientation": "vertical", "background": "#EEEEEE", "child": [{"type": "View", "id": "dyn_fa_v_w_mh", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_fa_v_w_mh_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": 200, "height": "matchParent"}], "width": "matchParent", "height": 60}, {"type": "View", "id": "dyn_fa_v_w_h", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_fa_v_w_h_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": 200, "height": 60}, {"type": "View", "id": "dyn_fa_v_mw_h_gcv", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_fa_v_mw_h_gcv_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": "matchParent", "height": 60, "gravity": "centerVertical"}, {"type": "Collection", "id": "dyn_fa_c_mw_h", "width": "matchParent", "height": 60, "lazy": "none", "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "frame alignment probe (codegen)" : "frame alignment probe").accessibilityIdentifier("fa_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_frame_alignment") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: ["rows": CollectionDataSource(sections: [ScrollRuleProbeView.section(cells: [["title": "c0"]])])])
            } else {
                Text("did not decode").accessibilityIdentifier("fa_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
