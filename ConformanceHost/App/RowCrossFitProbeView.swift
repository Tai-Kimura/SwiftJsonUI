//
//  RowCrossFitProbeView.swift
//  ConformanceHost
//
//  A horizontal Collection of wrapContent (or undeclared) height is its
//  cells' height, capped by its parent — across its scroll axis, as
//  CollectionContentFit sizes it along (4f 2026-09-27: the SSoT's
//  wrapContent is "size to content"). A LazyHStack takes the height it is
//  offered, so until SwiftJsonUI 10.29.0 / jsonui-cli 1.9.0 a lazy row
//  filled its parent (120 of a 120pt View) and pushed the view after it to
//  the parent's end, where the eager row was its cells' 28. On the Dynamic
//  renderer and — in the codegen host — as sjui generates it. NOT part of
//  the conformance suite; launch with `-rowCrossFitProbe` (the Dynamic half)
//  or `-rowCrossFitProbeCodegen` (the generated half). Its test
//  (RowCrossFitProbeUITests) is NOT opt-in.
//
//  Each row is a 300 × 120 View: a horizontal Collection of 60 × 28 cells
//  (conformance_cell), then a label "after".
//  - `*_rc_lazy_wrap`: lazy, matchParent wide, height undeclared — 28, the
//    label right under it. It was 120.
//  - `*_rc_lazy_wrap_both`: lazy, wrapContent both ways, two cells — 120 ×
//    28.
//  - controls: `*_rc_eager_wrap` 28 and `*_rc_lazy_40` (height 40) 40, as
//    before.
//
//  The generated half: ProbeLayouts/probe_row_cross_fit.json.
//

import SwiftUI
import SwiftJsonUI

struct RowCrossFitProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_rc_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 8, "child": [{"type": "View", "id": "dyn_rc_lazy_wrap_box", "orientation": "vertical", "width": 300, "height": 120, "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_rc_lazy_wrap", "layout": "horizontal", "background": "#CCE0FF", "items": "@{ten}", "sections": [{"cell": "conformance_cell"}], "width": "matchParent"}, {"type": "Label", "id": "dyn_rc_lazy_wrap_after", "text": "after", "width": "wrapContent", "height": "wrapContent"}]}, {"type": "View", "id": "dyn_rc_lazy_wrap_both_box", "orientation": "vertical", "width": 300, "height": 120, "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_rc_lazy_wrap_both", "layout": "horizontal", "background": "#CCE0FF", "items": "@{two}", "sections": [{"cell": "conformance_cell"}], "width": "wrapContent"}, {"type": "Label", "id": "dyn_rc_lazy_wrap_both_after", "text": "after", "width": "wrapContent", "height": "wrapContent"}]}, {"type": "View", "id": "dyn_rc_eager_wrap_box", "orientation": "vertical", "width": 300, "height": 120, "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_rc_eager_wrap", "layout": "horizontal", "background": "#CCE0FF", "items": "@{ten}", "sections": [{"cell": "conformance_cell"}], "width": "matchParent", "lazy": "eager"}, {"type": "Label", "id": "dyn_rc_eager_wrap_after", "text": "after", "width": "wrapContent", "height": "wrapContent"}]}, {"type": "View", "id": "dyn_rc_lazy_40_box", "orientation": "vertical", "width": 300, "height": 120, "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_rc_lazy_40", "layout": "horizontal", "background": "#CCE0FF", "items": "@{ten}", "sections": [{"cell": "conformance_cell"}], "width": "matchParent", "height": 40}, {"type": "Label", "id": "dyn_rc_lazy_40_after", "text": "after", "width": "wrapContent", "height": "wrapContent"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "row cross fit probe (codegen)" : "row cross fit probe").accessibilityIdentifier("rc_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_row_cross_fit") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [
                    "ten": CollectionDataSource(sections: [ScrollRuleProbeView.section(cells: (0..<10).map { ["title": "r\($0)"] })]),
                    "two": CollectionDataSource(sections: [ScrollRuleProbeView.section(cells: [["title": "t0"], ["title": "t1"]])])
                ])
            } else {
                Text("did not decode").accessibilityIdentifier("rc_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
