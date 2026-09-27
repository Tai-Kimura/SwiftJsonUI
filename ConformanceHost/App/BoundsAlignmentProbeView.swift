//
//  BoundsAlignmentProbeView.swift
//  ConformanceHost
//
//  A container's min / max bounds frame puts content smaller than it at
//  top | start — the unnamed axis of a partial gravity, and both axes when
//  gravity is omitted — as the frames that size it do (gravityDefaults; 4f
//  2026-09-27). Until jsonui-cli 1.9.0 / SwiftJsonUI 10.29.0 that frame
//  centred it (codegen's ResponsiveHelper.inner_frame_alignment filled the
//  unnamed axis with centre, and emitted nothing when gravity was omitted;
//  Dynamic's applyFrameConstraints passed no alignment). On the Dynamic
//  renderer and — in the codegen host — as sjui generates it. NOT part of the
//  conformance suite; launch with `-boundsAlignmentProbe` (the Dynamic half)
//  or `-boundsAlignmentProbeCodegen` (the generated half). Its test
//  (BoundsAlignmentProbeUITests) is NOT opt-in.
//
//  Each box holds one label (28 × 20):
//  - `*_ba_min_h`: 300 wide, minHeight 100 — the label at the top (it was
//    40pt down).
//  - `*_ba_min_w`: minWidth 200, height 40 — at the start (it was 86pt in).
//  - `*_ba_max_w`: matchParent, maxWidth 200, height 40 — at the start.
//  - `*_ba_min_h_gcv`: minHeight 100, gravity centerVertical — at the start,
//    centred vertically (it was centred both ways).
//  - control `*_ba_min_h_gc`: gravity center — centred, as before.
//
//  The generated half: ProbeLayouts/probe_bounds_alignment.json.
//

import SwiftUI
import SwiftJsonUI

struct BoundsAlignmentProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_ba_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 8, "child": [{"type": "View", "id": "dyn_ba_min_h", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_ba_min_h_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": 300, "minHeight": 100}, {"type": "View", "id": "dyn_ba_min_w", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_ba_min_w_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "minWidth": 200, "height": 40}, {"type": "View", "id": "dyn_ba_max_w", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_ba_max_w_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": "matchParent", "maxWidth": 200, "height": 40}, {"type": "View", "id": "dyn_ba_min_h_gcv", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_ba_min_h_gcv_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": 300, "minHeight": 100, "gravity": "centerVertical"}, {"type": "View", "id": "dyn_ba_min_h_gc", "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_ba_min_h_gc_label", "text": "abc", "width": "wrapContent", "height": "wrapContent", "background": "#FFD9A0"}], "orientation": "vertical", "width": 300, "minHeight": 100, "gravity": "center"}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "bounds alignment probe (codegen)" : "bounds alignment probe").accessibilityIdentifier("ba_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_bounds_alignment") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("ba_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
