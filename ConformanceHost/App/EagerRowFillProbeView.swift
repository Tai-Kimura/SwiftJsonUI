//
//  EagerRowFillProbeView.swift
//  ConformanceHost
//
//  A horizontal eager Collection fills a declared height, as a lazy one does
//  (4f 2026-09-27, measured: in a 40pt frame the eager row's ScrollView was
//  its cells' 28pt and the lazy row's 40, generated and Dynamic alike). On
//  the Dynamic renderer and — in the codegen host — as sjui generates it. NOT
//  part of the conformance suite; launch with `-eagerRowFillProbe` (the
//  Dynamic half) or `-eagerRowFillProbeCodegen` (the generated half). Its
//  test (EagerRowFillProbeUITests) is NOT opt-in.
//
//  Each Collection is horizontal, 300 wide, with ten 60 × 28 cells
//  (conformance_cell, e0…e9), so it scrolls.
//  - `*_er_eager_40`: eager, height 40 — its ScrollView 40 tall, and a drag
//    12pt below the cells scrolls it. It was 28 and the drag scrolled nothing.
//  - `*_er_eager_fill`: eager, matchParent in a 40pt View — the same.
//  - controls: `*_er_lazy_40`, lazy, height 40 — 40, as before;
//    `*_er_eager_wrap`, eager, wrapContent in a 120pt View — its cells' 28,
//    as before (a wrapContent height stays its content's).
//
//  The generated half: ProbeLayouts/probe_eager_row_fill.json.
//

import SwiftUI
import SwiftJsonUI

struct EagerRowFillProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_er_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 12, "child": [{"type": "View", "id": "dyn_er_eager_40_row", "orientation": "vertical", "width": 300, "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_er_eager_40", "layout": "horizontal", "lazy": "eager", "width": "matchParent", "height": 40, "background": "#CCE0FF", "items": "@{ten}", "sections": [{"cell": "conformance_cell"}]}]}, {"type": "View", "id": "dyn_er_eager_fill_row", "orientation": "vertical", "width": 300, "height": 40, "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_er_eager_fill", "layout": "horizontal", "lazy": "eager", "width": "matchParent", "height": "matchParent", "background": "#CCE0FF", "items": "@{ten}", "sections": [{"cell": "conformance_cell"}]}]}, {"type": "View", "id": "dyn_er_lazy_40_row", "orientation": "vertical", "width": 300, "height": "wrapContent", "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_er_lazy_40", "layout": "horizontal", "lazy": "lazy", "width": "matchParent", "height": 40, "background": "#CCE0FF", "items": "@{ten}", "sections": [{"cell": "conformance_cell"}]}]}, {"type": "View", "id": "dyn_er_eager_wrap_row", "orientation": "vertical", "width": 300, "height": 120, "background": "#FFFFFF", "child": [{"type": "Collection", "id": "dyn_er_eager_wrap", "layout": "horizontal", "lazy": "eager", "width": "matchParent", "height": "wrapContent", "background": "#CCE0FF", "items": "@{ten}", "sections": [{"cell": "conformance_cell"}]}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "eager row fill probe (codegen)" : "eager row fill probe").accessibilityIdentifier("er_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_eager_row_fill") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: ["ten": CollectionDataSource(sections: [
                    ScrollRuleProbeView.section(cells: (0..<10).map { ["title": "e\($0)"] })
                ])])
            } else {
                Text("did not decode").accessibilityIdentifier("er_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
