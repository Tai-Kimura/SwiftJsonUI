//
//  PagerHeightProbeView.swift
//  ConformanceHost
//
//  A paging Collection of height wrapContent in a vertical ScrollView is as
//  tall as the page it shows, as KotlinJsonUI's HorizontalPager(...
//  wrapContentHeight()) is. A page-style TabView has no height of its own: in
//  a vertical ScrollView it took whatever height the ScrollView had left (309
//  of 420 here) and asked its ideal size it is 0 — a consumer's carousel of
//  378pt measured 40.7pt with the label above and below (jsonui-cli ticket
//  2026-10-23-sjui-paging-collection-wrapcontent-height-collapses-in-scrollview).
//  The pages are jsonui-cli's conformance cells: page 0 conformance_cell (28pt
//  tall), page 1 conformance_cell_bare (40pt). Below it, the same pager at a
//  fixed height of 60 (the control: drawn as before). PagerHeightProbeUITests
//  reads the frames, swipes to page 1 and reads them again. On the Dynamic
//  renderer and — in the codegen host — as sjui generates it
//  (ProbeLayouts/probe_pager_height.json; PagerHeightCodegenHalf, compiled
//  only in the codegen host). NOT part of the conformance suite; launch with
//  `-pagerHeightProbe` or `-pagerHeightProbeCodegen`.
//

import SwiftUI
import SwiftJsonUI

// Dynamic-mode probe: SwiftJsonUI compiles Dynamic mode in DEBUG only.
#if DEBUG

struct PagerHeightProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_ph_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "ScrollView", "id": "dyn_ph_scroll", "orientation": "vertical", "width": "matchParent", "height": 420, "child": [{"type": "View", "id": "dyn_ph_content", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "Label", "id": "dyn_ph_head", "text": "head", "fontSize": 14}, {"type": "Collection", "id": "dyn_ph_pager", "layout": "horizontal", "paging": true, "width": "matchParent", "height": "wrapContent", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}, {"cell": "conformance_cell_bare"}]}, {"type": "Label", "id": "dyn_ph_foot", "text": "foot", "fontSize": 14}, {"type": "Collection", "id": "dyn_ph_fixed", "layout": "horizontal", "paging": true, "width": "matchParent", "height": 60, "items": "@{rows}", "sections": [{"cell": "conformance_cell"}, {"cell": "conformance_cell_bare"}]}, {"type": "Label", "id": "dyn_ph_end", "text": "end", "fontSize": 14}]}]}], "data": [{"name": "rows", "class": "CollectionDataSource", "defaultValue": {"sections": [{"cells": []}, {"cells": []}]}}]}"##

    /// Two sections, one page each: a 28pt cell, then a 40pt one.
    static func rows() -> CollectionDataSource {
        var first = CollectionDataSection()
        first.setCells(viewName: "conformance_cell", data: [["title": "A"]])
        var second = CollectionDataSection()
        second.setCells(viewName: "conformance_cell_bare", data: [["title": "B"]])
        return CollectionDataSource(sections: [first, second])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "pager height probe (codegen)" : "pager height probe").accessibilityIdentifier("ph_ready")
            if codegen {
                // CodegenOnly/ in the codegen host; a stub in the dynamic-only one.
                PagerHeightCodegenHalf()
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: ["rows": Self.rows()])
            } else {
                Text("did not decode").accessibilityIdentifier("ph_decode_failed")
            }
            Spacer()
        }
    }
}
#endif
