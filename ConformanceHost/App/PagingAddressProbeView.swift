//
//  PagingAddressProbeView.swift
//  ConformanceHost
//
//  Every page of a sectioned pager answers `{collectionId}_item_{n}`, n its
//  place among all the pages. NOT part of the conformance suite; launch with
//  `-pagingAddressProbe`. Its test (PagingAddressProbeUITests) is NOT opt-in:
//  it runs wherever this host's UI tests run.
//
//  The pager: sections of two cells, a header only, three cells and one —
//  six pages (A0 A1 B0 B1 B2 C0; a header is not a page), addressed 0…5
//  across the sections as sjui's page tag and KotlinJsonUI's pager count
//  them. Three sections draw cells, so two of them follow the first: the
//  generated loops of those two must not share ids either. The
//  Dynamic pager drew its pages without the builder every other route's
//  cells go through, so no page had an address at all (4f ruling
//  2026-09-26, round 8). The unit-test host cannot see accessibility
//  identifiers; XCUITest can.
//
//  A two-section list is here too: every section's cells are drawn (the
//  sjui-generated lazy list dropped a later section's cells at an offset an
//  earlier section already had — its ForEach ids repeated — round 8).
//
//  In the codegen host the same pager also appears as sjui GENERATED it —
//  ProbeLayouts/probe_paging_address.json (and the list,
//  probe_section_list.json), built by
//  scripts/generate_codegen_host.rb, id `cg_pager` — with the marker
//  `pa_codegen` beside it. Each pager sits in a `.contain` frame of its own
//  so the test can swipe across the whole page, not only the 60pt cell.
//

import SwiftUI
import SwiftJsonUI

struct PagingAddressProbeView: View {
    static let layout = ##"{"type": "Collection", "id": "pa_pager", "layout": "horizontal", "paging": true, "width": 200, "height": 60, "background": "#DDDDDD", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}, {"header": "conformance_cell"}, {"cell": "conformance_cell"}, {"cell": "conformance_cell"}]}"##

    static let listLayout = ##"{"type": "Collection", "id": "pa_list", "width": 200, "height": 200, "background": "#DDDDDD", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}, {"header": "conformance_cell"}, {"cell": "conformance_cell"}, {"cell": "conformance_cell"}]}"##

    static var rows: CollectionDataSource {
        var a = CollectionDataSection()
        a.setCells(viewName: "", data: [["title": "A0"], ["title": "A1"]])
        var h = CollectionDataSection()
        h.setHeader(viewName: "", data: ["title": "H"])
        var b = CollectionDataSection()
        b.setCells(viewName: "", data: [["title": "B0"], ["title": "B1"], ["title": "B2"]])
        var c = CollectionDataSection()
        c.setCells(viewName: "", data: [["title": "C0"]])
        return CollectionDataSource(sections: [a, h, b, c])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("paging address probe").accessibilityIdentifier("pa_ready")
            Group {
                if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                    DynamicComponentBuilder(component: component, data: ["rows": Self.rows])
                } else {
                    Text("did not decode").accessibilityIdentifier("pa_decode_failed")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("pa_pager_frame")
            Group {
                if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.listLayout.utf8)) {
                    DynamicComponentBuilder(component: component, data: ["rows": Self.rows])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("pa_list_frame")
            if let generated = CodegenFixtureRegistry.probeView(named: "probe_paging_address") {
                Text("codegen pager").accessibilityIdentifier("pa_codegen")
                generated
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_pager_frame")
            }
            if let generated = CodegenFixtureRegistry.probeView(named: "probe_section_list") {
                generated
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cg_list_frame")
            }
            Spacer()
        }
        .padding()
    }
}
