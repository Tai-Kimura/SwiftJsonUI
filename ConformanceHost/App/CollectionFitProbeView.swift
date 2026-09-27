//
//  CollectionFitProbeView.swift
//  ConformanceHost
//
//  A wrapContent Collection sizes to its content (4f ruling 2026-09-27, the
//  user's "size to content"), on the Dynamic renderer and — in the codegen
//  host — as sjui generates it. NOT part of the conformance suite; launch
//  with `-collectionFitProbe` (the Dynamic half) or
//  `-collectionFitProbeCodegen` (the generated half). Its test
//  (CollectionFitProbeUITests) is NOT opt-in.
//
//  Cells are 60 × 28 (conformance_cell), labelled f0… (three), l0… (ten),
//  h0… (two).
//  - `*_fit_box`: a 200 × 150 View; in it a wrapContent Collection of three
//    cells, then a label. The Collection is its cells' 84pt and the label
//    right under them. Until jsonui-cli 1.9.0 the Collection took the box
//    (a ScrollView takes every point offered) and the label sat at its end.
//  - `*_fit_long_box`: 200 × 110, ten cells: more than the box, so the
//    Collection is the box less the label and scrolls — as before.
//  - `*_fit_scroll`: a ScrollView, 140 tall; in it a wrapContent Collection
//    of three cells, then a label: 84pt, the label under it. It filled the
//    visible height.
//  - `*_fit_row`: a 200 × 40 horizontal View; a horizontal Collection of
//    wrapContent width, two cells, then a label: 120pt wide, the label
//    after it. It took the row.
//  - `*_fit_eager` / `*_fit_none`: 200 × 90, three cells, `lazy` eager /
//    none — the cells at the leading edge, as on the lazy route. They stood
//    in the middle (a ScrollView centres narrower content; a none
//    Collection's frame was not a container's, top | start).
//
//  The generated half: ProbeLayouts/probe_collection_fit.json.
//

import SwiftUI
import SwiftJsonUI

struct CollectionFitProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_fit_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_fit_box", "orientation": "vertical", "width": 200, "height": 150, "background": "#EEEEEE", "child": [{"type": "Collection", "id": "dyn_fit_list", "width": "matchParent", "height": "wrapContent", "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}]}, {"type": "Label", "id": "dyn_fit_after", "text": "after", "width": "wrapContent", "height": "wrapContent"}]}, {"type": "View", "id": "dyn_fit_long_box", "orientation": "vertical", "width": 200, "height": 110, "background": "#EEEEEE", "child": [{"type": "Collection", "id": "dyn_fit_long", "width": "matchParent", "height": "wrapContent", "background": "#CCE0FF", "items": "@{long}", "sections": [{"cell": "conformance_cell"}]}, {"type": "Label", "id": "dyn_fit_long_after", "text": "long after", "width": "wrapContent", "height": "wrapContent"}]}, {"type": "ScrollView", "id": "dyn_fit_scroll", "orientation": "vertical", "width": 200, "height": 140, "background": "#EEEEEE", "child": [{"type": "View", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_fit_inner", "width": "matchParent", "height": "wrapContent", "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}]}, {"type": "Label", "id": "dyn_fit_inner_after", "text": "inner after", "width": "wrapContent", "height": "wrapContent"}]}]}, {"type": "View", "id": "dyn_fit_row", "orientation": "horizontal", "width": 200, "height": 40, "background": "#EEEEEE", "child": [{"type": "Collection", "id": "dyn_fit_h", "width": "wrapContent", "height": 40, "background": "#CCE0FF", "items": "@{two}", "sections": [{"cell": "conformance_cell"}], "layout": "horizontal"}, {"type": "Label", "id": "dyn_fit_h_after", "text": "h after", "width": "wrapContent", "height": "wrapContent"}]}, {"type": "Collection", "id": "dyn_fit_eager", "width": 200, "height": 90, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "lazy": "eager"}, {"type": "Collection", "id": "dyn_fit_none", "width": 200, "height": 90, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "lazy": "none"}]}"##

    static func rows(_ prefix: String, _ count: Int) -> CollectionDataSource {
        CollectionDataSource(sections: [ScrollRuleProbeView.section(cells: (0..<count).map { ["title": "\(prefix)\($0)"] })])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "collection fit probe (codegen)" : "collection fit probe").accessibilityIdentifier("cf_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_collection_fit") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: ["rows": Self.rows("f", 3), "long": Self.rows("l", 10), "two": Self.rows("h", 2)])
            } else {
                Text("did not decode").accessibilityIdentifier("cf_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
