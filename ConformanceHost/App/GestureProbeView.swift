//
//  GestureProbeView.swift
//  ConformanceHost
//
//  Manual gesture-delegation probe (04a-design.md §2) — NOT part of the
//  conformance suite. Launch the app with `-gestureProbe`.
//
//  Layout: a parent NavigationStack pushes a detail screen that hosts a
//  full-width isolated embed, so the interactivePop edge regions of the
//  parent stack and the embed's private stack geometrically overlap at
//  the screen's leading edge — the scenario the "edge swipe routes to the
//  geometrically-hit NavigationStack, delegated to the OS" contract is
//  about. The host button drives the embed's stack through
//  EmbedNavigatorRegistry (the production imperative-access API).
//

import SwiftUI
import SwiftJsonUI

struct GestureProbeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("probe-root")
                    .accessibilityIdentifier("probe-root")
                NavigationLink("go-detail") {
                    ProbeDetailView()
                }
                .accessibilityIdentifier("go-detail")
            }
        }
    }
}

private struct ProbeDetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("detail-marker")
                .accessibilityIdentifier("detail-marker")
            Button("push-embed") {
                EmbedNavigatorRegistry.shared.navigator(for: "probe-pane")?
                    .push(screen: "probe_pushed")
            }
            .accessibilityIdentifier("push-embed")
            EmbedContainer(
                embedId: "probe-pane",
                screen: "probe_root",
                navigationMode: .isolated,
                isolatedNavigation: .automatic,
                destinationResolver: { _ in
                    AnyView(
                        Text("embed-pushed")
                            .accessibilityIdentifier("embed-pushed")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                }
            ) {
                Text("embed-root-probe")
                    .accessibilityIdentifier("embed-root-probe")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarBackButtonHidden(false)
    }
}
