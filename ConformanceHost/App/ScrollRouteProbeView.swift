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
//  The generated half: ProbeLayouts/probe_scroll_route.json (handlers:
//  ProbeLayouts/handlers/), built by scripts/generate_codegen_host.rb.
//

import SwiftUI
import SwiftJsonUI

struct ScrollRouteProbeView: View {
    let codegen: Bool

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
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_scroll_route") {
                    Text("codegen routes").accessibilityIdentifier("sp_codegen")
                    generated
                }
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
