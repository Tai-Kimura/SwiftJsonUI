//
//  CellFrameRoutesProbeView.swift
//  ConformanceHost
//
//  A Collection's cellWidth / cellHeight frame every cell, on every route
//  (the SSoT's Collection.cellWidth / cellHeight: "Fixed width / height for
//  every cell … applied to the cell view AFTER it is built"). NOT part of the
//  conformance suite; launch with `-cellFrameRoutesProbe`. Its test
//  (CellFrameRoutesProbeUITests) is NOT opt-in.
//
//  Every Collection declares cellWidth 150 and cellHeight 40 and draws three
//  conformance_cell cells (60 × 28, so the cell sits at its frame's top
//  leading corner and the frame shows in where the NEXT cell starts):
//  - `cw_list`: the lazy vertical list, which read them already — the
//    control: its cells 40 apart.
//  - `cw_flow` / `cw_flow_none`: a 320-wide flow, lazy and `lazy: none`,
//    gaps 10: two cells a line (160 apart), the third on the next (50 down).
//  - `cw_none_v` / `cw_none_h`: the `lazy: none` stacks, vertical and
//    horizontal: 40 / 150 apart.
//  Until SwiftJsonUI 10.40.0 all but the list drew each cell its own size
//  (ticket collection-cellwidth-cellheight-unread-on-some-routes): the flow
//  four 60pt cells a line, the stacks 28 / 60 apart. The pager is not here:
//  where a cell smaller than its page sits is not settled yet (the same
//  ticket, paging).
//

import SwiftUI
import SwiftJsonUI

// Dynamic-mode probe: SwiftJsonUI compiles Dynamic mode (DynamicView,
// DynamicComponent, CustomComponentRegistry) in DEBUG only, so a Release
// build of this host carries no probe (it hosts the codegen face only).
#if DEBUG

struct CellFrameRoutesProbeView: View {
    static func layout(_ id: String, _ extra: String) -> String {
        ##"{"type": "Collection", "id": "\##(id)", "cellWidth": 150, "cellHeight": 40, "background": "#DDDDDD", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}]\##(extra)}"##
    }

    static let routes: [(id: String, extra: String)] = [
        ("cw_list", #", "width": 320, "height": 130"#),
        ("cw_flow", #", "layout": "flow", "width": 320, "height": 100, "columnSpacing": 10, "lineSpacing": 10"#),
        ("cw_flow_none", #", "layout": "flow", "lazy": "none", "width": 320, "height": 100, "columnSpacing": 10, "lineSpacing": 10"#),
        ("cw_none_v", #", "lazy": "none", "width": 320, "height": 130"#),
        ("cw_none_h", #", "lazy": "none", "orientation": "horizontal", "width": 320, "height": 40"#)
    ]

    static var rows: CollectionDataSource {
        CollectionDataSource(sections: [ScrollRuleProbeView.section(cells: [["title": "a0"], ["title": "a1"], ["title": "a2"]])])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("cell frame routes probe").accessibilityIdentifier("cw_ready")
                ForEach(Self.routes, id: \.id) { route in
                    Group {
                        if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout(route.id, route.extra).utf8)) {
                            DynamicComponentBuilder(component: component, data: ["rows": Self.rows])
                        } else {
                            Text("did not decode").accessibilityIdentifier("cw_decode_failed")
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
