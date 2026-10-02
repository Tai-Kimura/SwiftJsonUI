//
//  AspectFillProbeView.swift
//  ConformanceHost
//
//  An image is drawn inside its frame, whatever its contentMode: AspectFill
//  is the crop (attribute_semantics.json image.ruling), not SwiftUI's
//  fill-and-overflow. jsonui-cli ticket sjui-aspectfill-image-is-not-
//  cropped-to-its-frame: a 600x600 texture with AspectFill in a 16pt spine
//  covered the whole page on iOS, and its ancestors grew to the filled size.
//  On the Dynamic renderer and — in the codegen host — as sjui generates it.
//  NOT part of the conformance suite; launch with `-aspectFillProbe` (the
//  Dynamic half) or `-aspectFillProbeCodegen` (the generated half). Its
//  test (AspectFillProbeUITests) is NOT opt-in.
//
//  Each case: a 2pt marker (the frame's top and start: a frame's own
//  accessibility frame grows with what its child draws), then a frame (120 x
//  60 box, or a 16 x 60 spine in a row) with one
//  matchParent image of conformance_sample (64x64, four colour quadrants),
//  and a label after it. Image / NetworkImage / CircleImage with AspectFill,
//  AspectFit (the control: fits, never overflows) and center (unscaled, so
//  larger than the 16pt spine). `grow`: a weight-1 frame 100 x 160 in a
//  200-wide row beside a 100-wide label — a square image filling it wants
//  160 wide, and must not take the label's room (the ticket's iPad pane).
//
//  The generated half: ProbeLayouts/probe_aspect_fill.json.
//

import SwiftUI
import SwiftJsonUI

struct AspectFillProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_af_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_af_img_fill_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_img_fill", "width": 120, "height": 60, "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_af_img_fill_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFill"}]}, {"type": "Label", "id": "dyn_af_img_fill_after", "text": "after", "height": 20, "width": "wrapContent"}, {"type": "View", "id": "dyn_af_img_fit_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_img_fit", "width": 120, "height": 60, "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_af_img_fit_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFit"}]}, {"type": "Label", "id": "dyn_af_img_fit_after", "text": "after", "height": 20, "width": "wrapContent"}, {"type": "View", "id": "dyn_af_img_center_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_img_center", "width": 120, "height": 60, "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_af_img_center_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "center"}]}, {"type": "Label", "id": "dyn_af_img_center_after", "text": "after", "height": 20, "width": "wrapContent"}, {"type": "View", "id": "dyn_af_net_fill_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_net_fill", "width": 120, "height": 60, "background": "#FFFFFF", "child": [{"type": "NetworkImage", "id": "dyn_af_net_fill_img", "width": "matchParent", "height": "matchParent", "defaultImage": "conformance_sample", "contentMode": "AspectFill"}]}, {"type": "Label", "id": "dyn_af_net_fill_after", "text": "after", "height": 20, "width": "wrapContent"}, {"type": "View", "id": "dyn_af_circle_fill_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_circle_fill", "width": 120, "height": 60, "background": "#FFFFFF", "child": [{"type": "CircleImage", "id": "dyn_af_circle_fill_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFill"}]}, {"type": "Label", "id": "dyn_af_circle_fill_after", "text": "after", "height": 20, "width": "wrapContent"}, {"type": "View", "id": "dyn_af_spine_fill_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_spine_fill_row", "orientation": "horizontal", "width": "matchParent", "height": 60, "child": [{"type": "View", "id": "dyn_af_spine_fill", "width": 16, "height": "matchParent", "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_af_spine_fill_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFill"}]}, {"type": "Label", "id": "dyn_af_spine_fill_after", "text": "after", "width": "wrapContent", "height": 20}]}, {"type": "View", "id": "dyn_af_spine_center_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_spine_center_row", "orientation": "horizontal", "width": "matchParent", "height": 60, "child": [{"type": "View", "id": "dyn_af_spine_center", "width": 16, "height": "matchParent", "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_af_spine_center_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "center"}]}, {"type": "Label", "id": "dyn_af_spine_center_after", "text": "after", "width": "wrapContent", "height": 20}]}, {"type": "View", "id": "dyn_af_grow_top", "width": 120, "height": 2, "background": "#FFFFFF"}, {"type": "View", "id": "dyn_af_grow_row", "orientation": "horizontal", "width": 200, "height": 160, "child": [{"type": "View", "id": "dyn_af_grow", "width": 0, "weight": 1, "height": "matchParent", "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_af_grow_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFill"}]}, {"type": "Label", "id": "dyn_af_grow_after", "text": "after", "width": 100, "height": 20}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "aspect fill probe (codegen)" : "aspect fill probe").accessibilityIdentifier("af_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_aspect_fill") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("af_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
