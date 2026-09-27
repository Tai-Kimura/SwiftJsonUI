//
//  ScrollRouteProbeView.swift
//  ConformanceHost
//
//  Whether a Collection's scrollTo reaches its cells on the routes that drew
//  no scroll until jsonui-cli 1.9.0 — the flow (sjui codegen and the Dynamic
//  renderer) and the sectioned List (the Dynamic renderer) — and when it
//  scrolls: on a CHANGE of the value, a value arriving where there was none
//  included, and never for the value the Collection is drawn with (the SSoT's
//  Collection.scrollTo). NOT part of the conformance suite; launch with
//  `-scrollRouteProbe` (the Dynamic half) or `-scrollRouteProbeCodegen` (the
//  generated half, in the codegen host). Its test (ScrollRouteProbeUITests)
//  is NOT opt-in.
//
//  The data is ScrollRuleProbeView's: `ruleRows` — a header, A0…A4, a
//  footer; a header, B0…B7 — and `ruleKeyed` — a0…a9 with keys k0…k9, then
//  b0…b9 with k3, x1…x9. Each Collection is 200 × 84, anchor top, not
//  animated; a cell is 60 × 28, so a flow row holds three.
//  - `*_route_flow` / `*_route_list`: "go 6" names B1, the seventh cell;
//  - `*_route_flow_key` / `*_route_list_key`: "go k3" names a3, the first
//    section's cell of the key both sections have;
//  - `*_route_initial`: drawn with scrollTo 6 — it stays at its top;
//  - `dyn_route_nil`: drawn with no scrollTo value at all; "dyn nil go 6"
//    sends one, a change like any other.
//
//  The second page (`-scrollRouteProbe2` / `-scrollRouteProbe2Codegen`,
//  jsonui-cli 1.9.0 round 12): the routes that drew no scrollTo on iOS until
//  then, and a String with no cellIdProperty —
//  - `*_route_class` / `*_route_class_key`: the class-list shape (cellClasses,
//    no `sections`): a List of every data section — A0…A4, then B0…B7;
//    "go 6" names B1, "go k3" a3;
//  - `*_route_pager` / `*_route_pager_key`: a pager of two sections; "go 6"
//    turns to page 6, B1; "go k3" to the page of a3;
//  - `*_route_cellid`: two sections, NO cellIdProperty, cells carrying a
//    `cellId` (c0…c9, then c3, y1…y9); "go c3" names a3 — the first section's.
//
//  The third page (`-scrollRouteProbe3` / `-scrollRouteProbe3Codegen`, 4f
//  round 14): what a value names is its declared class's, and no two cells
//  share an id —
//  - `*_route_int_list` / `*_route_int_class` / `*_route_int_pager`: two
//    sections with cellIdProperty `key` (a0…a9 keyed k0…k9, b0…b9 keyed k3,
//    x1…x9) — a sectioned list, the class-list List, a pager — and an INT
//    scrollTo: "go 12" names b2, the thirteenth cell. Until jsonui-cli 1.9.0
//    sjui read every value on a Collection with cellIdProperty as a key: the
//    class-list List and the pager did not compile, the list scrolled
//    nowhere;
//  - `*_route_dup`: cellIdProperty `key`, a String; g0…g9 keyed z0…z9 but g1
//    keyed "3", g3 with no key and g6 and g8 both keyed "k"; h0…h9 keyed
//    w0…w9 but h2 keyed "k". "go 3" names g1 (g3 has no key), "go k" g6 (the
//    first of the three), "go w5" h5, and "go k" again g6. Until then two
//    cells of one section with one key were one id (sjui codegen and the
//    Dynamic renderer), and in the Dynamic renderer g1 and g3 were one id,
//    "3" — which view a scroll reached was SwiftUI's choice.
//
//  The generated half: ProbeLayouts/probe_scroll_route.json,
//  probe_scroll_route2.json and probe_scroll_route3.json (handlers:
//  ProbeLayouts/handlers/), built by scripts/generate_codegen_host.rb.
//

import SwiftUI
import SwiftJsonUI

struct ScrollRouteProbeView: View {
    let codegen: Bool
    var second = false
    var third = false

    static func layout(_ id: String, rows: String, target: String, extra: String) -> String {
        let sections = rows == "ruleRows"
            ? #"[{"cell": "conformance_cell", "header": "conformance_cell", "footer": "conformance_cell"}, {"cell": "conformance_cell", "header": "conformance_cell"}]"#
            : #"[{"cell": "conformance_cell"}, {"cell": "conformance_cell"}]"#
        return ##"{"type": "Collection", "id": "\##(id)", "width": 200, "height": 84, "background": "#DDDDDD", "items": "@{\##(rows)}", "sections": \##(sections), \##(extra)"scrollTo": "@{\##(target)}", "scrollAnchor": "top", "scrollAnimated": false}"##
    }

    @State private var flowIndex = 0
    @State private var flowKey = ""
    @State private var listIndex = 0
    @State private var listKey = ""
    @State private var nilIndex: Int? = nil
    @State private var classIndex = 0
    @State private var classKey = ""
    @State private var pagerIndex = 0
    @State private var pagerKey = ""
    @State private var cellIdKey = ""
    @State private var intList = 0
    @State private var intClass = 0
    @State private var intPager = 0
    @State private var dupKey = ""

    /// g0…g9 keyed z0…z9 but g1 keyed "3", g3 with no key, g6 and g8 keyed
    /// "k"; h0…h9 keyed w0…w9 but h2 keyed "k".
    static var dupRows: CollectionDataSource {
        func keys(_ prefix: String, _ keys: [String?]) -> [[String: Any]] {
            keys.enumerated().map { i, key in key.map { ["title": "\(prefix)\(i)", "key": $0] } ?? ["title": "\(prefix)\(i)"] }
        }
        var g: [String?] = (0..<10).map { "z\($0)" }
        g[1] = "3"; g[3] = nil; g[6] = "k"; g[8] = "k"
        var h: [String?] = (0..<10).map { "w\($0)" }
        h[2] = "k"
        return CollectionDataSource(sections: [
            ScrollRuleProbeView.section(cells: keys("g", g)),
            ScrollRuleProbeView.section(cells: keys("h", h))
        ])
    }

    /// ruleRows / ruleKeyed with no header or footer: the class-list shape's
    /// data sections, and a pager's pages.
    static func bare(_ source: CollectionDataSource) -> CollectionDataSource {
        CollectionDataSource(sections: source.sections.map { section in
            var bare = CollectionDataSection()
            bare.setCells(viewName: "", data: section.cells?.data ?? [])
            return bare
        })
    }

    /// Two sections whose cells carry a `cellId` — c0…c9, then c3, y1…y9.
    static var ruleCellIds: CollectionDataSource {
        let second = ["c3"] + (1..<10).map { "y\($0)" }
        return CollectionDataSource(sections: [
            ScrollRuleProbeView.section(cells: (0..<10).map { ["title": "a\($0)", "cellId": "c\($0)"] }),
            ScrollRuleProbeView.section(cells: (0..<10).map { ["title": "b\($0)", "cellId": second[$0]] })
        ])
    }

    static func classList(_ id: String, extra: String) -> String {
        ##"{"type": "Collection", "id": "\##(id)", "width": 200, "height": 84, "background": "#DDDDDD", "items": "@{rows}", "cellClasses": ["conformance_cell"], \##(extra)"scrollTo": "@{t}", "scrollAnchor": "top", "scrollAnimated": false}"##
    }

    static func twoSections(_ id: String, extra: String) -> String {
        ##"{"type": "Collection", "id": "\##(id)", "width": 200, "height": 84, "background": "#DDDDDD", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}, {"cell": "conformance_cell"}], \##(extra)"scrollTo": "@{t}", "scrollAnchor": "top", "scrollAnimated": false}"##
    }

    private func dynamic(_ json: String, data: [String: Any], frame: String) -> some View {
        Group {
            if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8)) {
                DynamicComponentBuilder(component: component, data: data)
            } else {
                Text("did not decode").accessibilityIdentifier("sp_decode_failed")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(frame)
    }

    private var rows: CollectionDataSource { ScrollRuleProbeView.ruleRows }
    private var keyed: CollectionDataSource { ScrollRuleProbeView.ruleKeyed }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "scroll route probe (codegen)" : "scroll route probe").accessibilityIdentifier("sp_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: third ? "probe_scroll_route3" : second ? "probe_scroll_route2" : "probe_scroll_route") {
                    Text("codegen routes").accessibilityIdentifier("sp_codegen")
                    generated
                }
            } else if third {
                HStack {
                    Button("dyn int list go 12") { intList = 12 }
                    Button("dyn int class go 12") { intClass = 12 }
                    Button("dyn int pager go 12") { intPager = 12 }
                }
                .font(.system(size: 9))
                HStack {
                    Button("dyn dup go k") { dupKey = "k" }
                    Button("dyn dup go 3") { dupKey = "3" }
                    Button("dyn dup go w5") { dupKey = "w5" }
                }
                .font(.system(size: 9))
                dynamic(Self.twoSections("dyn_route_int_list", extra: #""cellIdProperty": "key", "#),
                        data: ["rows": Self.bare(keyed), "t": intList], frame: "dyn_route_int_list")
                dynamic(Self.classList("dyn_route_int_class", extra: #""cellIdProperty": "key", "#),
                        data: ["rows": Self.bare(keyed), "t": intClass], frame: "dyn_route_int_class")
                dynamic(Self.twoSections("dyn_route_int_pager", extra: #""layout": "horizontal", "paging": true, "cellIdProperty": "key", "#),
                        data: ["rows": Self.bare(keyed), "t": intPager], frame: "dyn_route_int_pager")
                dynamic(Self.twoSections("dyn_route_dup", extra: #""cellIdProperty": "key", "#),
                        data: ["rows": Self.dupRows, "t": dupKey], frame: "dyn_route_dup")
            } else if second {
                HStack {
                    Button("dyn class go 6") { classIndex = 6 }
                    Button("dyn class go k3") { classKey = "k3" }
                    Button("dyn pager go 6") { pagerIndex = 6 }
                    Button("dyn pager go k3") { pagerKey = "k3" }
                    Button("dyn cellid go c3") { cellIdKey = "c3" }
                }
                .font(.system(size: 9))
                dynamic(Self.classList("dyn_route_class", extra: ""),
                        data: ["rows": Self.bare(rows), "t": classIndex], frame: "dyn_route_class")
                dynamic(Self.classList("dyn_route_class_key", extra: #""cellIdProperty": "key", "#),
                        data: ["rows": Self.bare(keyed), "t": classKey], frame: "dyn_route_class_key")
                dynamic(Self.twoSections("dyn_route_pager", extra: #""layout": "horizontal", "paging": true, "#),
                        data: ["rows": Self.bare(rows), "t": pagerIndex], frame: "dyn_route_pager")
                dynamic(Self.twoSections("dyn_route_pager_key", extra: #""layout": "horizontal", "paging": true, "cellIdProperty": "key", "#),
                        data: ["rows": Self.bare(keyed), "t": pagerKey], frame: "dyn_route_pager_key")
                dynamic(Self.twoSections("dyn_route_cellid", extra: ""),
                        data: ["rows": Self.ruleCellIds, "t": cellIdKey], frame: "dyn_route_cellid")
            } else {
                HStack {
                    Button("dyn flow go 6") { flowIndex = 6 }
                    Button("dyn flow go k3") { flowKey = "k3" }
                    Button("dyn list go 6") { listIndex = 6 }
                    Button("dyn list go k3") { listKey = "k3" }
                    Button("dyn nil go 6") { nilIndex = 6 }
                }
                .font(.system(size: 9))
                dynamic(Self.layout("dyn_route_flow", rows: "ruleRows", target: "t", extra: #""layout": "flow", "#),
                        data: ["ruleRows": rows, "t": flowIndex], frame: "dyn_route_flow")
                dynamic(Self.layout("dyn_route_flow_key", rows: "ruleKeyed", target: "t", extra: #""layout": "flow", "cellIdProperty": "key", "#),
                        data: ["ruleKeyed": keyed, "t": flowKey], frame: "dyn_route_flow_key")
                dynamic(Self.layout("dyn_route_list", rows: "ruleRows", target: "t", extra: #""listStyle": "plain", "#),
                        data: ["ruleRows": rows, "t": listIndex], frame: "dyn_route_list")
                dynamic(Self.layout("dyn_route_list_key", rows: "ruleKeyed", target: "t", extra: #""listStyle": "plain", "cellIdProperty": "key", "#),
                        data: ["ruleKeyed": keyed, "t": listKey], frame: "dyn_route_list_key")
                dynamic(Self.layout("dyn_route_initial", rows: "ruleRows", target: "t", extra: ""),
                        data: ["ruleRows": rows, "t": 6], frame: "dyn_route_initial")
                dynamic(Self.layout("dyn_route_nil", rows: "ruleRows", target: "t", extra: ""),
                        data: nilIndex.map { ["ruleRows": rows, "t": $0] } ?? ["ruleRows": rows], frame: "dyn_route_nil")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
