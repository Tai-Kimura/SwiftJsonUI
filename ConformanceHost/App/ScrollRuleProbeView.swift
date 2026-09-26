//
//  ScrollRuleProbeView.swift
//  ConformanceHost
//
//  What a Collection's scrollTo names across sections, and how a sectioned
//  grid lays out its headers and footers, on the Dynamic renderer and — in
//  the codegen host — as sjui GENERATES it (4f round 10, 2026-09-27;
//  jsonui-cli 1.9.0, the SSoT's Collection.scrollTo). NOT part of the
//  conformance suite; launch with `-scrollRuleProbe` (the lists) or
//  `-sectionGridProbe` (the grid). Its test (ScrollRuleProbeUITests) is NOT
//  opt-in: in the dynamic host, which has no generated views, it asks the
//  Dynamic half only.
//
//  - `*_rule_index`: a list of two sections — a header, five cells A0…A4
//    and a footer; a header and eight cells B0…B7 — 84pt tall (three rows),
//    scrollTo an Int, anchor top, not animated. "go 6" names the seventh
//    CELL, B1: headers and footers are not counted. Dynamic handed the 6 to
//    ScrollViewProxy as it was, against String cell ids.
//  - `*_rule_key`: two sections of ten cells with cellIdProperty `key`; the
//    first's keys k0…k9 (a0…a9), the second's k3, x1…x9 (b0…b9). "go k3"
//    names the FIRST cell, in section order, whose key is k3: a3, not b0.
//  - `*_rule_grid` (`-sectionGridProbe`): a grid of two columns, 200 × 200,
//    lineSpacing 4, columnSpacing 10; a section of a header, A0…A2 and a
//    footer, then one of a header, B0 and B1. A header or footer is a
//    full-width row with the view at its start, the rows spaced 4.
//
//  The generated half: ProbeLayouts/probe_scroll_rule.json and
//  probe_section_grid.json (handlers: ProbeLayouts/handlers/), built by
//  scripts/generate_codegen_host.rb.
//

import SwiftUI
import SwiftJsonUI

struct ScrollRuleProbeView: View {
    let grid: Bool

    static let indexLayout = ##"{"type": "Collection", "id": "dyn_rule_index", "width": 200, "height": 84, "background": "#DDDDDD", "items": "@{ruleRows}", "sections": [{"cell": "conformance_cell", "header": "conformance_cell", "footer": "conformance_cell"}, {"cell": "conformance_cell", "header": "conformance_cell"}], "scrollTo": "@{ruleIndex}", "scrollAnchor": "top", "scrollAnimated": false}"##
    static let keyLayout = ##"{"type": "Collection", "id": "dyn_rule_key", "width": 200, "height": 84, "background": "#DDDDDD", "items": "@{ruleKeyed}", "sections": [{"cell": "conformance_cell"}, {"cell": "conformance_cell"}], "cellIdProperty": "key", "scrollTo": "@{ruleKey}", "scrollAnchor": "top", "scrollAnimated": false}"##
    static let gridLayout = ##"{"type": "Collection", "id": "dyn_rule_grid", "width": 200, "height": 200, "background": "#DDDDDD", "items": "@{gridRows}", "sections": [{"cell": "conformance_cell", "header": "conformance_cell", "footer": "conformance_cell"}, {"cell": "conformance_cell", "header": "conformance_cell"}], "columns": 2, "lineSpacing": 4, "columnSpacing": 10}"##

    static func section(header: String? = nil, cells: [[String: Any]], footer: String? = nil) -> CollectionDataSection {
        var section = CollectionDataSection()
        if let header { section.setHeader(viewName: "", data: ["title": header]) }
        section.setCells(viewName: "", data: cells)
        if let footer { section.setFooter(viewName: "", data: ["title": footer]) }
        return section
    }

    static var ruleRows: CollectionDataSource {
        CollectionDataSource(sections: [
            section(header: "H0", cells: (0..<5).map { ["title": "A\($0)"] }, footer: "F0"),
            section(header: "H1", cells: (0..<8).map { ["title": "B\($0)"] })
        ])
    }

    static var ruleKeyed: CollectionDataSource {
        let second = ["k3"] + (1..<10).map { "x\($0)" }
        return CollectionDataSource(sections: [
            section(cells: (0..<10).map { ["title": "a\($0)", "key": "k\($0)"] }),
            section(cells: (0..<10).map { ["title": "b\($0)", "key": second[$0]] })
        ])
    }

    static var gridRows: CollectionDataSource {
        CollectionDataSource(sections: [
            section(header: "H0", cells: ["A0", "A1", "A2"].map { ["title": $0] }, footer: "F0"),
            section(header: "H1", cells: ["B0", "B1"].map { ["title": $0] })
        ])
    }

    @State private var ruleIndex = 0
    @State private var ruleKey = ""

    private func dynamic(_ json: String, data: [String: Any], frame: String) -> some View {
        Group {
            if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8)) {
                DynamicComponentBuilder(component: component, data: data)
            } else {
                Text("did not decode").accessibilityIdentifier("sr_decode_failed")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(frame)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(grid ? "section grid probe" : "scroll rule probe").accessibilityIdentifier("sr_ready")
            if grid {
                dynamic(Self.gridLayout, data: ["gridRows": Self.gridRows], frame: "dyn_grid_frame")
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_section_grid") {
                    Text("codegen grid").accessibilityIdentifier("sr_codegen")
                    generated
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("cg_grid_frame")
                }
            } else {
                Button("dyn go 6") { ruleIndex = 6 }
                dynamic(Self.indexLayout, data: ["ruleRows": Self.ruleRows, "ruleIndex": ruleIndex], frame: "dyn_index_frame")
                Button("dyn go k3") { ruleKey = "k3" }
                dynamic(Self.keyLayout, data: ["ruleKeyed": Self.ruleKeyed, "ruleKey": ruleKey], frame: "dyn_key_frame")
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_scroll_rule") {
                    Text("codegen lists").accessibilityIdentifier("sr_codegen")
                    generated
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("cg_lists_frame")
                }
            }
            Spacer()
        }
        .padding()
    }
}
