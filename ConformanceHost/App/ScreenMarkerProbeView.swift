//
//  ScreenMarkerProbeView.swift
//  ConformanceHost
//
//  Screen-marker measurement probe (screen-identity track, Phase 0) — NOT
//  part of the conformance suite. Launch the app with `-screenMarkerProbe`.
//
//  Two questions decide the design of the marker, and neither can be
//  answered by reading SwiftUI's documentation:
//
//  1. WHAT SHAPE is safe? Making a screen root an accessibility container
//     merges single-child subtrees and drops the inner element's
//     identifier (measured on a real device, 2026-07-21). This probe
//     renders both candidate shapes side by side over identical content so
//     the difference is observable: an overlay LEAF marker vs a CONTAINER
//     marker wrapping the same subtree.
//
//  2. WHICH PREDICATE means "displayed"? A pushed-away screen can stay in
//     the hierarchy, and accessibility containers report isHittable ==
//     false even while fully visible. The probe therefore exposes five
//     navigation shapes — push, sheet, fullScreenCover, tab switch and
//     split pane — and leaves BOTH screens' markers in place so the UI
//     test can record exists / isHittable / frame for the covered screen
//     and the covering one.
//
//  The probe asserts nothing on its own: it is an instrument. The UI test
//  (ScreenMarkerProbeUITests) records the measurements.
//

import SwiftUI
import SwiftJsonUI

// MARK: - Marker shapes under test

/// Candidate A — a zero-ish LEAF in an overlay. Adds one accessibility
/// element beside the content and never wraps it.
private struct LeafMarker: ViewModifier {
    let screenId: String

    func body(content: Content) -> some View {
        content.overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 0.5, height: 0.5)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("__screen_\(screenId)")
        }
    }
}

/// Candidate B — the shape used for id-bearing containers today: wrap the
/// subtree in an accessibility container and label it.
private struct ContainerMarker: ViewModifier {
    let screenId: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("__screen_\(screenId)")
    }
}

private extension View {
    func leafMarker(_ screenId: String) -> some View { modifier(LeafMarker(screenId: screenId)) }
    func containerMarker(_ screenId: String) -> some View { modifier(ContainerMarker(screenId: screenId)) }
}

// MARK: - Content shared by every probe screen

/// A screen body shaped like a real generated view: a root container that
/// carries its own identifier, plus nested identified children. The single
/// deep child is the merge hazard — a container marker can absorb it.
private struct ProbeScreenBody: View {
    let screenId: String
    let childCount: Int

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<childCount, id: \.self) { index in
                Text("\(screenId)-child-\(index)")
                    .accessibilityIdentifier("\(screenId)_child_\(index)")
            }
        }
        // Mirrors what code generation emits for an id-bearing container:
        // an identifier alone would turn the VStack into ONE element and
        // swallow the children, so the container treatment comes with it.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(screenId)_root_view")
    }
}

// MARK: - Probe root

struct ScreenMarkerProbeView: View {
    @State private var showSheet = false
    @State private var showCover = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 12) {
                    // Shape A and shape B over identical content, so a
                    // clobbered child id is attributable to the shape.
                    ProbeScreenBody(screenId: "leafhost", childCount: 2)
                        .leafMarker("leafhost")
                    ProbeScreenBody(screenId: "containerhost", childCount: 1)
                        .containerMarker("containerhost")

                    // The LIBRARY's real modifier, so the runtime spelling of the
            // identifier is measured rather than assumed — codegen passes a
            // bare screen id and the modifier forms `__screen_<id>`.
            ProbeScreenBody(screenId: "libhost", childCount: 1)
                .jsonUIScreenMarker("lib_probe")

            NavigationLink("go-pushed") { PushedScreen() }
                        .accessibilityIdentifier("go_pushed")
                    Button("open-sheet") { showSheet = true }
                        .accessibilityIdentifier("open_sheet")
                    Button("open-cover") { showCover = true }
                        .accessibilityIdentifier("open_cover")
                }
                .leafMarker("probe_home")
            }
            .tabItem { Text("home") }
            .tag(0)

            NavigationStack {
                ProbeScreenBody(screenId: "second_tab", childCount: 2)
                    .leafMarker("second_tab")
            }
            .tabItem { Text("second") }
            .tag(1)
        }
        .sheet(isPresented: $showSheet) {
            ProbeScreenBody(screenId: "sheet_screen", childCount: 2)
                .leafMarker("sheet_screen")
        }
        .fullScreenCover(isPresented: $showCover) {
            VStack(spacing: 12) {
                ProbeScreenBody(screenId: "cover_screen", childCount: 2)
                Button("close-cover") { showCover = false }
                    .accessibilityIdentifier("close_cover")
            }
            .leafMarker("cover_screen")
        }
    }
}

private struct PushedScreen: View {
    var body: some View {
        ProbeScreenBody(screenId: "pushed_screen", childCount: 2)
            .leafMarker("pushed_screen")
    }
}

/// Side-by-side panes: both screens are genuinely displayed at once, which
/// is why the assertion's meaning is "this screen is displayed", never
/// "only this screen is displayed".
struct ScreenMarkerSplitProbeView: View {
    var body: some View {
        HStack(spacing: 0) {
            ProbeScreenBody(screenId: "left_pane", childCount: 2)
                .leafMarker("left_pane")
            ProbeScreenBody(screenId: "right_pane", childCount: 2)
                .leafMarker("right_pane")
        }
    }
}
