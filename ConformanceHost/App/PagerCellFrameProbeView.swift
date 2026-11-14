//
//  PagerCellFrameProbeView.swift
//  ConformanceHost
//
//  Launched with `-pagerCellFrameProbe`: four 200 × 60 pagers
//  (`"paging": true`, horizontal) of conformance_cell cells (60 × 28), each
//  `{route}_frame`:
//  - `cp_both`: cellWidth 150, cellHeight 40 — the 150 × 40 frame in the
//    middle of the page, the cell at its top leading corner: 25, 10.
//  - `cp_w`: cellWidth 150 only — a 150 × 28 frame: 25, 16.
//  - `cp_h`: cellHeight 40 only — a 60 × 40 frame: 70, 10.
//  - `cp_none`: neither, the control — the cell itself in the middle: 70, 16.
//  Until SwiftJsonUI 10.41.0 the pager read neither (ticket
//  collection-cellwidth-cellheight-unread-on-some-routes, paging): every
//  pager drew its cell at 70, 16.
//

import SwiftUI
import SwiftJsonUI

// Dynamic-mode probe: SwiftJsonUI compiles Dynamic mode (DynamicView,
// DynamicComponent, CustomComponentRegistry) in DEBUG only, so a Release
// build of this host carries no probe (it hosts the codegen face only).
#if DEBUG

struct PagerCellFrameProbeView: View {
    static func layout(_ id: String, _ frame: String) -> String {
        ##"{"type": "Collection", "id": "\##(id)", "layout": "horizontal", "paging": true, "width": 200, "height": 60, "background": "#DDDDDD", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}]\##(frame)}"##
    }

    static let routes: [(id: String, frame: String)] = [
        ("cp_both", #", "cellWidth": 150, "cellHeight": 40"#),
        ("cp_w", #", "cellWidth": 150"#),
        ("cp_h", #", "cellHeight": 40"#),
        ("cp_none", "")
    ]

    static var rows: CollectionDataSource {
        CollectionDataSource(sections: [ScrollRuleProbeView.section(cells: [["title": "a0"], ["title": "a1"]])])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("pager cell frame probe").accessibilityIdentifier("cp_ready")
                ForEach(Self.routes, id: \.id) { route in
                    Group {
                        if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout(route.id, route.frame).utf8)) {
                            DynamicComponentBuilder(component: component, data: ["rows": Self.rows])
                        } else {
                            Text("did not decode").accessibilityIdentifier("cp_decode_failed")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("\(route.id)_frame")
                }
            }
            .padding()
        }
    }
}
#endif
