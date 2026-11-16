//
//  AutoFocusDynamicProbeView.swift
//  ConformanceHost
//
//  `autoFocus` on the Dynamic runtime (jsonui-cli ticket
//  2026-10-23-dynamic-renderers-do-not-implement-autofocus): the same five
//  layouts as AutoFocusCodegenProbeView — a TextField and a TextView with an
//  id and without one, and a TextField without autoFocus (the control) —
//  drawn by DynamicComponentBuilder. NOT part of the conformance suite.
//  Launch with `-autoFocusDynamicProbe <variant>`.
//

import SwiftUI
import SwiftJsonUI

// Dynamic-mode probe: SwiftJsonUI compiles Dynamic mode (DynamicView,
// DynamicComponent, CustomComponentRegistry) in DEBUG only, so a Release
// build of this host carries no probe (it hosts the codegen face only).
#if DEBUG

struct AutoFocusDynamicProbeView: View {
    let variant: String

    static let layouts: [String: String] = [
        "tfNoId": #"{"type":"TextField","width":"matchParent","height":44,"autoFocus":true}"#,
        "tfId": #"{"type":"TextField","id":"email_field","width":"matchParent","height":44,"autoFocus":true}"#,
        "tvNoId": #"{"type":"TextView","width":"matchParent","height":120,"autoFocus":true}"#,
        "tvId": #"{"type":"TextView","id":"note_view","width":"matchParent","height":120,"autoFocus":true}"#,
        "tfNone": #"{"type":"TextField","id":"plain_field","width":"matchParent","height":44}"#,
    ]

    var body: some View {
        VStack {
            Text("af_probe_ready").accessibilityIdentifier("af_probe_ready")
            if let layout = Self.layouts[variant],
               let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("unknown variant \(variant)").accessibilityIdentifier("af_probe_unknown")
            }
        }
        .padding()
    }
}
#endif
