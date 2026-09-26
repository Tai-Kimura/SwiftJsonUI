//
//  TabEnabledProbeView.swift
//  ConformanceHost
//
//  Does a TabView with `enabled: false` still switch tabs when its tab bar is
//  tapped? (4f, 2026-09-26: measured yes on Android and web.) NOT part of the
//  conformance suite. Launch with `-tabEnabledProbe <E|N>` (enabled false /
//  enabled true, the control) and `-ocPath <dynamic|codegen>`: DynamicView
//  over the layout, or what `sjui build` (sjui_tools of jsonui-cli df223c03)
//  emits for it, pasted below unchanged.
//

import SwiftUI
import SwiftJsonUI

struct TabEnabledProbeView: View {
    private let gate = OnClickProbeView.arg("-tabEnabledProbe", "E")
    private let path = OnClickProbeView.arg("-ocPath", "dynamic")

    static let layouts: [String: String] = [
        "E": #"{"type":"TabView","id":"tabE","width":"matchParent","height":"matchParent","enabled":false,"tabs":[{"title":"One"},{"title":"Two"}]}"#,
        "N": #"{"type":"TabView","id":"tabN","width":"matchParent","height":"matchParent","enabled":true,"tabs":[{"title":"One"},{"title":"Two"}]}"#,
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("ready").accessibilityIdentifier("te_ready")
            if path == "codegen" {
                if gate == "N" { TabEnabledNCodegenPaste() } else { TabEnabledECodegenPaste() }
            } else if let layout = try? JSONDecoder().decode(DynamicComponent.self, from: Data((Self.layouts[gate] ?? "").utf8)) {
                DynamicView(component: layout, viewId: "te", data: [:])
            } else {
                Text("layout did not decode").accessibilityIdentifier("te_decode_failed")
            }
        }
    }
}

/// sjui build's body for tab_enabled_e.json (enabled: false).
struct TabEnabledECodegenPaste: View {
    var body: some View {
            TabView {
                Text("One")
                    .tabItem {
                        Label("One", systemImage: "circle")
                    }
                    .tag(0)
                Text("Two")
                    .tabItem {
                        Label("Two", systemImage: "circle")
                    }
                    .tag(1)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .disabled(true)
                .accessibilityIdentifier("tabE")
                .disabled(true)
    }
}

/// sjui build's body for tab_enabled_n.json (enabled: true).
struct TabEnabledNCodegenPaste: View {
    var body: some View {
            TabView {
                Text("One")
                    .tabItem {
                        Label("One", systemImage: "circle")
                    }
                    .tag(0)
                Text("Two")
                    .tabItem {
                        Label("Two", systemImage: "circle")
                    }
                    .tag(1)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("tabN")
    }
}
