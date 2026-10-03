//
//  AspectFillHitProbeView.swift
//  ConformanceHost
//
//  Does an AspectFill image take touches, or the accessibility hit test,
//  outside its frame? A 16 x 60 spine holds a square image (conformance_
//  sample) with AspectFill: drawn, it is 60 wide and overflows 22pt on each
//  side, over the right of the TextField before it. The fill row and the
//  AspectFit control row are tapped at the same point inside the field and
//  inside that overflow; AspectFillHitProbeUITests reads whether the field
//  took focus and whether XCUITest calls it hittable; a 30-wide field (its
//  centre inside the overflow) is what XCUITest calls covered; a label after
//  each spine measures the spine's laid-out width. On the Dynamic renderer
//  and — in the codegen host — as sjui generates it
//  (ProbeLayouts/probe_aspect_fill_hit.json). NOT part of the conformance
//  suite; launch with `-aspectFillHitProbe` or `-aspectFillHitProbeCodegen`.
//

import SwiftUI
import SwiftJsonUI

struct AspectFillHitProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_afh_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_afh_fill_row", "orientation": "horizontal", "width": "matchParent", "height": 60, "child": [{"type": "TextField", "id": "dyn_afh_fill_field", "width": 120, "height": 60, "hint": "f", "background": "#EEEEEE"}, {"type": "View", "id": "dyn_afh_fill_spine", "width": 16, "height": "matchParent", "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_afh_fill_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFill"}]}, {"type": "Label", "id": "dyn_afh_fill_after", "text": "after", "width": "wrapContent", "height": 20}]}, {"type": "View", "id": "dyn_afh_gap1", "width": 10, "height": 40}, {"type": "View", "id": "dyn_afh_fit_row", "orientation": "horizontal", "width": "matchParent", "height": 60, "child": [{"type": "TextField", "id": "dyn_afh_fit_field", "width": 120, "height": 60, "hint": "f", "background": "#EEEEEE"}, {"type": "View", "id": "dyn_afh_fit_spine", "width": 16, "height": "matchParent", "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_afh_fit_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFit"}]}, {"type": "Label", "id": "dyn_afh_fit_after", "text": "after", "width": "wrapContent", "height": 20}]}, {"type": "View", "id": "dyn_afh_gap2", "width": 10, "height": 40}, {"type": "View", "id": "dyn_afh_narrow_row", "orientation": "horizontal", "width": "matchParent", "height": 60, "child": [{"type": "TextField", "id": "dyn_afh_narrow_field", "width": 30, "height": 60, "hint": "f", "background": "#EEEEEE"}, {"type": "View", "id": "dyn_afh_narrow_spine", "width": 16, "height": "matchParent", "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_afh_narrow_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFill"}]}, {"type": "Label", "id": "dyn_afh_narrow_after", "text": "after", "width": "wrapContent", "height": 20}]}, {"type": "View", "id": "dyn_afh_gap3", "width": 10, "height": 40}, {"type": "View", "id": "dyn_afh_narrowfit_row", "orientation": "horizontal", "width": "matchParent", "height": 60, "child": [{"type": "TextField", "id": "dyn_afh_narrowfit_field", "width": 30, "height": 60, "hint": "f", "background": "#EEEEEE"}, {"type": "View", "id": "dyn_afh_narrowfit_spine", "width": 16, "height": "matchParent", "background": "#FFFFFF", "child": [{"type": "Image", "id": "dyn_afh_narrowfit_img", "width": "matchParent", "height": "matchParent", "src": "conformance_sample", "contentMode": "AspectFit"}]}, {"type": "Label", "id": "dyn_afh_narrowfit_after", "text": "after", "width": "wrapContent", "height": 20}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "aspect fill hit probe (codegen)" : "aspect fill hit probe").accessibilityIdentifier("afh_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_aspect_fill_hit") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("afh_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
