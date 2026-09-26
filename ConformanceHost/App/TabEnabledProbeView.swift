//
//  TabEnabledProbeView.swift
//  ConformanceHost
//
//  What a TabView's `enabled: false` stops: the tab items, not the tab shown
//  (4f's ruling, jsonui-cli 1.9.0 — the Compose and web forms). NOT part of
//  the conformance suite. Launch with `-tabEnabledProbe <E|N|U>` (enabled
//  false / enabled true, the control / userInteractionEnabled false, which
//  stops the tab view and what it shows) and `-ocPath <dynamic|codegen>`:
//  DynamicView over the layout, or what `sjui build` (sjui_tools of
//  jsonui-cli support4f/tap-rule-uie-round5, on b9d10daf) emits for it,
//  pasted below unchanged. Each tab shows a layout of its own (`view`):
//  te_one holds a Button, te_two a Text — the codegen draws them as
//  TeOneView / TeTwoView, the Dynamic runtime through an adapter registered
//  for the name.
//    E: {"type":"TabView","id":"tabE","width":"matchParent","height":"matchParent","enabled":false,"tabs":[{"title":"One","view":"te_one"},{"title":"Two","view":"te_two"}]}
//    N: the same with "enabled":true (id tabN); U: "userInteractionEnabled":false (id tabU)
//  `-ocPath candidate`: the forms the emit chose from (TabEnabledCandidates).
//

import SwiftUI
import SwiftJsonUI

/// What the Button in the first tab counted.
final class TabProbeLog: ObservableObject {
    static let shared = TabProbeLog()
    @Published var taps = 0
}

/// The first tab's layout: a Button that counts.
struct TeOneView: View {
    @ObservedObject private var log = TabProbeLog.shared
    var body: some View {
        VStack {
            Button("te_btn_one") { log.taps += 1 }.accessibilityIdentifier("te_btn_one")
            Text("taps=\(log.taps)").accessibilityIdentifier("te_taps")
        }
    }
}

/// The second tab's layout.
struct TeTwoView: View {
    var body: some View {
        Text("content-two").accessibilityIdentifier("te_content_two")
    }
}

struct TeTabAdapter: CustomComponentAdapter {
    let componentType: String
    func buildView(component: DynamicComponent, data: [String: Any], viewId: String?, parentOrientation: String?) -> AnyView {
        componentType == "te_one" ? AnyView(TeOneView()) : AnyView(TeTwoView())
    }
}

struct TabEnabledProbeView: View {
    private let gate = OnClickProbeView.arg("-tabEnabledProbe", "E")
    private let path = OnClickProbeView.arg("-ocPath", "dynamic")

    init() {
        // This launch only (-tabEnabledProbe): the tabs' layouts.
        CustomComponentRegistry.shared.registerAll([TeTabAdapter(componentType: "te_one"), TeTabAdapter(componentType: "te_two")])
    }

    static let tabs = #""tabs":[{"title":"One","view":"te_one"},{"title":"Two","view":"te_two"}]"#
    static let layouts: [String: String] = [
        "E": #"{"type":"TabView","id":"tabE","width":"matchParent","height":"matchParent","enabled":false,"# + tabs + "}",
        "N": #"{"type":"TabView","id":"tabN","width":"matchParent","height":"matchParent","enabled":true,"# + tabs + "}",
        "U": #"{"type":"TabView","id":"tabU","width":"matchParent","height":"matchParent","userInteractionEnabled":false,"# + tabs + "}",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("ready").accessibilityIdentifier("te_ready")
            if path == "candidate" {
                TabEnabledCandidates(kind: gate)
            } else if path == "codegen" {
                switch gate {
                case "N": TabEnabledNCodegenPaste()
                case "U": TabEnabledUCodegenPaste()
                default: TabEnabledECodegenPaste()
                }
            } else if let layout = try? JSONDecoder().decode(DynamicComponent.self, from: Data((Self.layouts[gate] ?? "").utf8)) {
                DynamicView(component: layout, viewId: "te", data: [:])
            } else {
                Text("layout did not decode").accessibilityIdentifier("te_decode_failed")
            }
        }
    }
}

/// sjui build's body for E (enabled: false).
struct TabEnabledECodegenPaste: View {
    var body: some View {
        TabView {
            TeOneView()
                .jsonuiTabItemsEnabled(false)
                .tabItem {
                    Label("One", systemImage: "circle")
                }
                .tag(0)
            TeTwoView()
                .jsonuiTabItemsEnabled(false)
                .tabItem {
                    Label("Two", systemImage: "circle")
                }
                .tag(1)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("tabE")
    }
}

/// sjui build's body for N (enabled: true).
struct TabEnabledNCodegenPaste: View {
    var body: some View {
        TabView {
            TeOneView()
                .tabItem {
                    Label("One", systemImage: "circle")
                }
                .tag(0)
            TeTwoView()
                .tabItem {
                    Label("Two", systemImage: "circle")
                }
                .tag(1)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("tabN")
    }
}

/// sjui build's body for U (userInteractionEnabled: false).
struct TabEnabledUCodegenPaste: View {
    var body: some View {
        TabView {
            TeOneView()
                .tabItem {
                    Label("One", systemImage: "circle")
                }
                .tag(0)
            TeTwoView()
                .tabItem {
                    Label("Two", systemImage: "circle")
                }
                .tag(1)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .environment(\.jsonuiInteractionStopped, true)
            .accessibilityIdentifier("tabU")
    }
}

// MARK: - candidates (measurement only, not emitted)

final class TabCandidateCounts: ObservableObject {
    @Published var taps = 0
    @Published var found = "?"
}

/// Finds the UITabBarController above a tab's content (the responder chain)
/// and sets its items' `isEnabled`.
struct TabItemsEnabledProbe: UIViewRepresentable {
    let enabled: Bool
    let counts: TabCandidateCounts
    var variant = ""
    func makeUIView(context: Context) -> Finder { Finder() }
    func updateUIView(_ view: Finder, context: Context) {
        view.enabled = enabled
        view.variant = variant
        view.counts = counts
        view.apply()
    }
    final class Finder: UIView {
        var enabled = true
        var variant = ""
        var counts: TabCandidateCounts?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }
        func apply() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                var responder: UIResponder? = self
                while let r = responder {
                    if let tbc = r as? UITabBarController {
                        if self.variant == "bar" {
                            tbc.tabBar.isUserInteractionEnabled = self.enabled
                        } else {
                            tbc.tabBar.items?.forEach { $0.isEnabled = self.enabled }
                        }
                        if self.variant == "traits" {
                            tbc.tabBar.items?.forEach { $0.accessibilityTraits = self.enabled ? .button : [.button, .notEnabled] }
                        }
                        self.counts?.found = "found \(type(of: tbc)) items=\(tbc.tabBar.items?.count ?? -1)"
                        return
                    }
                    responder = r.next
                }
                self.counts?.found = "not found"
            }
        }
    }
}

/// C0: what sjui emits today (the whole TabView disabled); C1: the selection
/// gated (a set is dropped); C2: the tab bar items disabled (UIKit); C12: both.
/// Tab One holds a Button: whether the content still works.
struct TabEnabledCandidates: View {
    let kind: String
    @StateObject private var counts = TabCandidateCounts()
    @State private var selection = 0

    @State private var walk = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("taps=\(counts.taps) sel=\(selection) \(counts.found)").accessibilityIdentifier("te_counts")
            Button("walk") { runWalk() }.accessibilityIdentifier("te_walk")
            Text(walk).font(.system(size: 6)).accessibilityIdentifier("te_walk_out")
            tabs
        }
    }

    /// The tab bar's elements as a screen reader reaches them (A11yActivator
    /// walks the key window): label, traits, notEnabled, responds; then
    /// "Two" is activated as VoiceOver's double tap does, and the touch it
    /// would send is left to the UI test.
    private func runWalk() {
        guard let window = A11yActivator.keyWindow() else { walk = "nowindow"; return }
        var seen = Set<ObjectIdentifier>()
        var stack: [NSObject] = [window]
        var out: [String] = []
        var two: NSObject?
        while let node = stack.popLast() {
            guard seen.insert(ObjectIdentifier(node)).inserted else { continue }
            if node.isAccessibilityElement, let label = node.accessibilityLabel, label == "One" || label == "Two" {
                let t = node.accessibilityTraits
                out.append("\(label):\(String(t.rawValue, radix: 16)):btn=\(t.contains(.button) ? 1 : 0):ne=\(t.contains(.notEnabled) ? 1 : 0):resp=\(node.accessibilityRespondsToUserInteraction ? 1 : 0):\(type(of: node))")
                if label == "Two" && two == nil { two = node }
            }
            stack += A11yActivator.children(node).reversed()
        }
        let returned = two?.accessibilityActivate() ?? false
        let p = two?.accessibilityActivationPoint ?? .zero
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            walk = out.joined(separator: " ") + " | activateTwo returned=\(returned) sel=\(selection) point=\(Int(p.x)),\(Int(p.y))"
        }
    }

    private var gated: SwiftUI.Binding<Int> {
        kind.contains("1") ? SwiftUI.Binding(get: { selection }, set: { _ in }) : $selection
    }

    @ViewBuilder private var tabs: some View {
        let view = TabView(selection: gated) {
            VStack {
                Text("content-one").accessibilityIdentifier("te_content_one")
                Button("btnOne") { counts.taps += 1 }.accessibilityIdentifier("te_btn_one")
            }
            .background(kind.contains("2") || kind == "C3" || kind == "C4" ? AnyView(TabItemsEnabledProbe(enabled: false, counts: counts, variant: kind == "C3" ? "traits" : (kind == "C4" ? "bar" : ""))) : AnyView(EmptyView()))
            .tabItem { Label("One", systemImage: "circle").disabled(kind == "C5") }
            .badge(counts.taps)
            .tag(0)
            Text("content-two").accessibilityIdentifier("te_content_two")
                .background(kind.contains("2") || kind == "C3" || kind == "C4" ? AnyView(TabItemsEnabledProbe(enabled: false, counts: counts, variant: kind == "C3" ? "traits" : (kind == "C4" ? "bar" : ""))) : AnyView(EmptyView()))
                .tabItem { Label("Two", systemImage: "circle").disabled(kind == "C5") }
                .tag(1)
        }
        if kind == "C0" {
            view.disabled(true).accessibilityIdentifier("tabC").disabled(true)
        } else {
            view.accessibilityIdentifier("tabC")
        }
    }
}
