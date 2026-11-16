//
//  SectionScrollProbeView.swift
//  ConformanceHost
//
//  A Collection of two sections, as sjui GENERATES it: a scrollTo reaches the
//  cell it names in the later section, and cells whose keys two sections
//  share are all drawn. NOT part of the conformance suite; launch with
//  `-sectionScrollProbe`. Its test (SectionScrollProbeUITests) is NOT opt-in;
//  in the dynamic host, which has no generated views, it only checks the
//  generated half is absent.
//
//  ProbeLayouts/probe_section_scroll.json, built by
//  scripts/generate_codegen_host.rb (its buttons' handlers:
//  ProbeLayouts/handlers/probe_section_scroll.json):
//  - `cg_scroll_index`: sections of ten cells each (A0…A9, B0…B9), 112pt
//    tall (four rows), scrollTo an Int, anchor top, not animated. "go index"
//    sets it to 13, B3's place among all the cells (4f round 9: `.id` was the
//    index within the section, so 13 named no cell).
//  - `cg_scroll_key`: the same with cellIdProperty `key` (a0…a9, b0…b9) and a
//    String scrollTo. "go key" sets it to "b3" — a later section's cell,
//    whose ForEach id carries its section: it must still answer its key.
//  - `cg_shared_keys`: two sections of five cells whose keys are the same
//    (k0…k4; titles x0…x4 and y0…y4), tall enough for all ten. Shared keys
//    were one id to the stack both sections share, which dropped the second
//    section's cells.
//

import SwiftUI
import SwiftJsonUI

struct SectionScrollProbeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("section scroll probe").accessibilityIdentifier("ss_ready")
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_section_scroll") {
                    Text("codegen shapes").accessibilityIdentifier("ss_codegen")
                    generated
                }
            }
            .padding()
        }
    }
}
