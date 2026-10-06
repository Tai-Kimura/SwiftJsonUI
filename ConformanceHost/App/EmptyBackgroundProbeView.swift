//
//  EmptyBackgroundProbeView.swift
//  ConformanceHost
//
//  An empty View with a background paints its whole box, padding included
//  (the padding is the element: user ruling 2026-10-06). Until SwiftJsonUI
//  10.29.7 / jsonui-cli 1.9.18 both renderers drew the colour as the fill of a
//  Rectangle and applied the padding outside it, so a 100 x 40 empty View with
//  padding 8 painted only the inner 84 x 24 (ticket ios-an-empty-view-with-a-
//  background-paints-only-inside-its-padding). NOT part of the conformance
//  suite; launch with `-emptyBackgroundProbe` (the Dynamic half) or
//  `-emptyBackgroundProbeCodegen` (the generated half). Its test
//  (EmptyBackgroundProbeUITests) is NOT opt-in.
//
//  `*_eb_pad`: 100 x 40, padding 8, #FFDD00. Control `*_eb_nopad`: the same
//  without the padding. Each is the only child of a fixed 300 x 60 parent.
//
//  The generated half: ProbeLayouts/probe_empty_background.json.
//

import SwiftUI
import SwiftJsonUI

struct EmptyBackgroundProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_eb_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_eb_p_pad", "width": 300, "height": 60, "child": [{"type": "View", "id": "dyn_eb_pad", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00", "padding": 8}]}, {"type": "View", "id": "dyn_eb_p_nopad", "width": 300, "height": 60, "child": [{"type": "View", "id": "dyn_eb_nopad", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "background": "#FFDD00"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "empty background probe (codegen)" : "empty background probe").accessibilityIdentifier("eb_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_empty_background") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("eb_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
