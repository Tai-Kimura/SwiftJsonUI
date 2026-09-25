//
//  CanTapGateProbeView.swift
//  ConformanceHost
//
//  What `canTap` stops: the onClick / onclick handler's call, and nothing
//  else — not a child's tap, not a control's own operation (a Switch's
//  value, a Radio's selection, a CheckBox's check). NOT part of the
//  conformance suite. Launch with `-canTapGateProbe`.
//
//  Top: what `jui build` (sjui_tools, JsonToSwiftUIConverter) emits for a
//  View with a bound canTap holding a child with its own tap, and for a
//  Switch with onClick and a bound canTap — the gate shut (`gateClosed`)
//  and open (`gateOpen`) — pasted unchanged. The bound gate is
//  `.gesture(TapGesture()…, including: c ? .all : .subviews)`. And a Switch
//  with onClick and no canTap (`.onTapGesture`), the control. And the parent
//  as jsonui-cli 6ab928bf emitted it under the same shut binding —
//  `.allowsHitTesting(c)`, placed before `.contentShape` + `.onTapGesture`:
//  measured, it stopped the child's tap and not the parent's (par_old,
//  kid_old).
//
//  Bottom: the dynamic runtime's Button, IconLabel, Radio and CheckBox with
//  onClick under no canTap, `canTap: false`, and a binding resolving false
//  and true.
//
//  Every handler counts its calls into a label the UI test reads.
//

import SwiftUI
import SwiftJsonUI

final class CanTapGateProbeData: ObservableObject {
    @Published var counts: [String: Int] = [:]
    @Published var swClosed = false
    @Published var swOpen = false
    @Published var swPlain = false
    @Published var groups: [String: String] = [:]
    @Published var checks: [String: Bool] = [:]

    func bump(_ name: String) { counts[name, default: 0] += 1 }

    // The codegen rows' data surface.
    var gateClosed: Bool? = false
    var gateOpen: Bool? = true
    lazy var onParClosed: (() -> Void)? = { [weak self] in self?.bump("par_closed") }
    lazy var onKidClosed: (() -> Void)? = { [weak self] in self?.bump("kid_closed") }
    lazy var onParOpen: (() -> Void)? = { [weak self] in self?.bump("par_open") }
    lazy var onKidOpen: (() -> Void)? = { [weak self] in self?.bump("kid_open") }
    lazy var onSwClosed: (() -> Void)? = { [weak self] in self?.bump("sw_closed") }
    lazy var onSwOpen: (() -> Void)? = { [weak self] in self?.bump("sw_open") }
    lazy var onSwPlain: (() -> Void)? = { [weak self] in self?.bump("sw_plain") }
    lazy var onParOld: (() -> Void)? = { [weak self] in self?.bump("par_old") }
    lazy var onKidOld: (() -> Void)? = { [weak self] in self?.bump("kid_old") }
}

struct CanTapGateProbeView: View {
    @StateObject private var data = CanTapGateProbeData()

    static let gates = ["none", "false", "bclosed", "bopen"]
    static let kinds = ["btn", "icl", "radio", "check"]

    private static func gate(_ g: String) -> String {
        switch g {
        case "false": return #", "canTap": false"#
        case "bclosed": return #", "canTap": "@{gate_closed}""#
        case "bopen": return #", "canTap": "@{gate_open}""#
        default: return ""
        }
    }

    private static func item(_ kind: String, _ g: String) -> String {
        let id = "dyn_\(kind)_\(g)"
        let tap = #""onClick": "@{on_\#(id)}""# + gate(g)
        switch kind {
        case "btn": return #"{"type": "Button", "id": "\#(id)", "text": "B", \#(tap)}"#
        case "icl": return #"{"type": "IconLabel", "id": "\#(id)", "text": "I", \#(tap)}"#
        case "radio": return #"{"type": "Radio", "id": "\#(id)", "group": "grp_\#(g)", "text": "R", \#(tap)}"#
        default: return #"{"type": "CheckBox", "id": "\#(id)", "isOn": "@{chk_\#(g)}", \#(tap)}"#
        }
    }

    private static let dynamicLayout: DynamicComponent? = {
        let rows = kinds.map { kind in
            #"{"type": "View", "orientation": "horizontal", "spacing": 12, "child": ["#
                + gates.map { item(kind, $0) }.joined(separator: ", ") + "]}"
        }
        let json = #"{"type": "View", "orientation": "vertical", "spacing": 8, "child": ["#
            + rows.joined(separator: ", ") + "]}"
        return try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }()

    private var dynamicData: [String: Any] {
        var out: [String: Any] = ["gate_closed": false, "gate_open": true]
        let data = self.data
        for kind in Self.kinds {
            for g in Self.gates {
                let id = "dyn_\(kind)_\(g)"
                out["on_\(id)"] = { () -> Void in data.bump(id) }
            }
        }
        for g in Self.gates {
            out["grp_\(g)"] = SwiftUI.Binding<String>(
                get: { data.groups["grp_\(g)"] ?? "" }, set: { data.groups["grp_\(g)"] = $0 })
            out["chk_\(g)"] = SwiftUI.Binding<Bool>(
                get: { data.checks["chk_\(g)"] ?? false }, set: { data.checks["chk_\(g)"] = $0 })
        }
        return out
    }

    private var readout: String {
        let counts = data.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let groups = data.groups.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let checks = data.checks.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        return "counts[\(counts)] sw[closed=\(data.swClosed),open=\(data.swOpen),plain=\(data.swPlain)] groups[\(groups)] checks[\(checks)]"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("can tap gate probe").accessibilityIdentifier("cantap_probe_ready")
            Text(readout).font(.system(size: 6)).accessibilityIdentifier("cantap_readout")
            VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidClosed?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kid_closed")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .contentShape(Rectangle())
                        .gesture(TapGesture().onEnded {
                                data.onParClosed?()
                            }, including: (data.gateClosed ?? false) ? .all : .subviews)
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("par_closed")
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidOpen?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kid_open")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .contentShape(Rectangle())
                        .gesture(TapGesture().onEnded {
                                data.onParOpen?()
                            }, including: (data.gateOpen ?? false) ? .all : .subviews)
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("par_open")
                    Toggle(isOn: $data.swClosed) {
                        Text("")
                    }
                        .labelsHidden()
                        .contentShape(Rectangle())
                        .gesture(TapGesture().onEnded {
                                data.onSwClosed?()
                            }, including: (data.gateClosed ?? false) ? .all : .subviews)
                        .accessibilityIdentifier("sw_closed")
                    Toggle(isOn: $data.swOpen) {
                        Text("")
                    }
                        .labelsHidden()
                        .contentShape(Rectangle())
                        .gesture(TapGesture().onEnded {
                                data.onSwOpen?()
                            }, including: (data.gateOpen ?? false) ? .all : .subviews)
                        .accessibilityIdentifier("sw_open")
                    Toggle(isOn: $data.swPlain) {
                        Text("")
                    }
                        .labelsHidden()
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onSwPlain?()
                            }
                        .accessibilityIdentifier("sw_plain")
            }
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidOld?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kid_old")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .allowsHitTesting((data.gateClosed ?? false))
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onParOld?()
                            }
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("par_old")
            if let layout = Self.dynamicLayout {
                DynamicComponentBuilder(component: layout, data: dynamicData)
            } else {
                Text("layout did not decode").accessibilityIdentifier("cantap_decode_failed")
            }
        }
    }
}
