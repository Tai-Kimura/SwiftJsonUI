//
//  DisabledColoursProbeView.swift
//  ConformanceHost
//
//  The disabled colours follow a bound `enabled` (jsonui-cli ticket
//  2026-10-23-bound-enabled-disabled-colors-three-faces): a View's
//  disabledBackground and a Label's disabledFontColor showed only for a literal
//  `enabled: false`, so a bound `enabled` that turned false left the base colour.
//  The generated half only (the defect was sjui's): ProbeLayouts/
//  probe_disabled_colours.json, `on` true, then false through the `off` button
//  (ProbeLayouts/handlers/probe_disabled_colours.json). Launch with
//  `-disabledColoursProbeCodegen`; its test is DisabledColoursProbeUITests.
//

import SwiftUI
import SwiftJsonUI

struct DisabledColoursProbeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("disabled colours probe (codegen)").accessibilityIdentifier("dc_ready")
            if let generated = CodegenFixtureRegistry.probeView(named: "probe_disabled_colours") {
                generated
            } else {
                Text("no generated view").accessibilityIdentifier("dc_missing")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
