//
//  InteractionGateProbeView.swift
//  ConformanceHost
//
//  What `userInteractionEnabled: false` and a bound `enabled` stop on a view
//  with a tap of its own: its handler, its child's tap. NOT part of the
//  conformance suite. Launch with `-interactionGateProbe`.
//
//  Top: what `jui build` (sjui_tools, JsonToSwiftUIConverter) emits, pasted
//  unchanged — `.allowsHitTesting` outside the view's gestures — and, last,
//  the parent under `userInteractionEnabled: false` as it was emitted with
//  `.allowsHitTesting` before `.contentShape` + `.onTapGesture` (parUieOld,
//  kidUieOld): a View with onClick holding a child with its own onClick —
//  no gate (the control), `userInteractionEnabled: false`, bound
//  `userInteractionEnabled` resolving false, bound `enabled` resolving false
//  without an id; a Label with onClick under `userInteractionEnabled: false`
//  and under a bound `enabled` without an id; a View with onLongPress, no
//  gate (the control) and `userInteractionEnabled: false`.
//
//  and a Switch with no gate (the control) and under `userInteractionEnabled:
//  false`.
//
//  Bottom: the dynamic runtime's View / Label / Switch with the same gates,
//  and a container holding a child with a tap of its own.
//
//  Every handler counts its calls into a label the UI test reads.
//

import SwiftUI
import SwiftJsonUI

final class InteractionGateProbeData: ObservableObject {
    @Published var counts: [String: Int] = [:]
    @Published var swUiePlain = false
    @Published var swUieFalse = false
    @Published var dynSw: [String: Bool] = [:]

    func bump(_ name: String) { counts[name, default: 0] += 1 }

    // The codegen rows' data surface.
    var gateClosed: Bool? = false
    lazy var onKidEnBoundNoId: (() -> Void)? = { [weak self] in self?.bump("kidEnBoundNoId") }
    lazy var onKidPlain: (() -> Void)? = { [weak self] in self?.bump("kidPlain") }
    lazy var onKidUieBound: (() -> Void)? = { [weak self] in self?.bump("kidUieBound") }
    lazy var onKidUieFalse: (() -> Void)? = { [weak self] in self?.bump("kidUieFalse") }
    lazy var onLblEnBoundNoId: (() -> Void)? = { [weak self] in self?.bump("lblEnBoundNoId") }
    lazy var onLblUieFalse: (() -> Void)? = { [weak self] in self?.bump("lblUieFalse") }
    lazy var onLpPlain: (() -> Void)? = { [weak self] in self?.bump("lpPlain") }
    lazy var onLpUieFalse: (() -> Void)? = { [weak self] in self?.bump("lpUieFalse") }
    lazy var onParEnBoundNoId: (() -> Void)? = { [weak self] in self?.bump("parEnBoundNoId") }
    lazy var onParPlain: (() -> Void)? = { [weak self] in self?.bump("parPlain") }
    lazy var onParUieBound: (() -> Void)? = { [weak self] in self?.bump("parUieBound") }
    lazy var onParUieFalse: (() -> Void)? = { [weak self] in self?.bump("parUieFalse") }
    lazy var onParUieOld: (() -> Void)? = { [weak self] in self?.bump("parUieOld") }
    lazy var onKidUieOld: (() -> Void)? = { [weak self] in self?.bump("kidUieOld") }
}

struct InteractionGateProbeView: View {
    @StateObject private var data = InteractionGateProbeData()

    /// The dynamic rows, each with its ids: leaves with onClick or
    /// onLongPress, a container holding a child with a tap of its own, and
    /// Switches.
    static let dynamicRows: [String] = [
        ##"{"id": "dynViewPlain", "type": "View", "onClick": "@{on_dynViewPlain}", "width": 80, "height": 30, "background": "#3366CC"}"##,
        ##"{"id": "dynViewUieFalse", "type": "View", "onClick": "@{on_dynViewUieFalse}", "width": 80, "height": 30, "background": "#3366CC", "userInteractionEnabled": false}"##,
        ##"{"id": "dynViewUieBound", "type": "View", "onClick": "@{on_dynViewUieBound}", "width": 80, "height": 30, "background": "#3366CC", "userInteractionEnabled": "@{gate_closed}"}"##,
        ##"{"id": "dynViewEnBound", "type": "View", "onClick": "@{on_dynViewEnBound}", "width": 80, "height": 30, "background": "#3366CC", "enabled": "@{gate_closed}"}"##,
        ##"{"id": "dynLblUieFalse", "type": "Label", "text": "dynLblUieFalse", "onClick": "@{on_dynLblUieFalse}", "userInteractionEnabled": false}"##,
        ##"{"id": "dynLpPlain", "type": "View", "onLongPress": "@{on_dynLpPlain}", "width": 80, "height": 30, "background": "#3366CC"}"##,
        ##"{"id": "dynLpUieFalse", "type": "View", "onLongPress": "@{on_dynLpUieFalse}", "width": 80, "height": 30, "background": "#3366CC", "userInteractionEnabled": false}"##,
        ##"{"id": "dynParUieFalse", "type": "View", "onClick": "@{on_dynParUieFalse}", "padding": 16, "background": "#DDDDDD", "userInteractionEnabled": false, "child": [{"id": "dynKidUieFalse", "type": "View", "onClick": "@{on_dynKidUieFalse}", "width": 80, "height": 30, "background": "#3366CC"}]}"##,
        ##"{"id": "dynSwPlain", "type": "Switch", "isOn": "@{dynSwPlain}"}"##,
        ##"{"id": "dynSwUieFalse", "type": "Switch", "isOn": "@{dynSwUieFalse}", "userInteractionEnabled": false}"##,
    ]
    static let dynamicHandlers = ["dynViewPlain", "dynViewUieFalse", "dynViewUieBound", "dynViewEnBound", "dynLblUieFalse",
                                  "dynLpPlain", "dynLpUieFalse", "dynParUieFalse", "dynKidUieFalse"]

    private static let dynamicLayout: DynamicComponent? = {
        let json = #"{"type": "View", "orientation": "vertical", "spacing": 8, "child": ["#
            + dynamicRows.joined(separator: ", ") + "]}"
        return try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }()

    private var dynamicData: [String: Any] {
        var out: [String: Any] = ["gate_closed": false]
        let data = self.data
        for id in Self.dynamicHandlers {
            out["on_\(id)"] = { () -> Void in data.bump(id) }
        }
        for sw in ["dynSwPlain", "dynSwUieFalse"] {
            out[sw] = SwiftUI.Binding<Bool>(get: { data.dynSw[sw] ?? false }, set: { data.dynSw[sw] = $0 })
        }
        return out
    }

    private var readout: String {
        "counts[" + data.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",") + "] " +
            "sw[swUiePlain=\(data.swUiePlain),swUieFalse=\(data.swUieFalse),dynSwPlain=\(data.dynSw["dynSwPlain"] ?? false)," +
            "dynSwUieFalse=\(data.dynSw["dynSwUieFalse"] ?? false)]"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("interaction gate probe").accessibilityIdentifier("gate_probe_ready")
            Text(readout).font(.system(size: 6)).accessibilityIdentifier("gate_readout")
            // codegen at the left, the dynamic runtime at the right: one
            // column each did not fit the screen
            HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidPlain?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kidPlain")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onParPlain?()
                            }
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("parPlain")
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidUieFalse?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kidUieFalse")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onParUieFalse?()
                            }
                        .allowsHitTesting(false)
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("parUieFalse")
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidUieBound?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kidUieBound")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onParUieBound?()
                            }
                        .allowsHitTesting((data.gateClosed ?? false))
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("parUieBound")
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidEnBoundNoId?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kidEnBoundNoId")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onParEnBoundNoId?()
                            }
                        .disabled(!((data.gateClosed ?? false)))
                    PartialAttributedText(
                        "lblUieFalse",
                        textAlignment: .leading
                    )
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onLblUieFalse?()
                            }
                        .accessibilityAddTraits(.isButton)
                        .allowsHitTesting(false)
                        .accessibilityIdentifier("lblUieFalse")
                    PartialAttributedText(
                        "lblEnBoundNoId",
                        textAlignment: .leading
                    )
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onLblEnBoundNoId?()
                            }
                        .accessibilityAddTraits(.isButton)
                        .disabled(!((data.gateClosed ?? false)))
                    Rectangle()
                        .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                        .frame(width: 80, height: 30)
                        .onLongPressGesture {
                            data.onLpPlain?()
                        }
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("lpPlain")
                    Rectangle()
                        .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                        .frame(width: 80, height: 30)
                        .onLongPressGesture {
                            data.onLpUieFalse?()
                        }
                        .allowsHitTesting(false)
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("lpUieFalse")
                    Toggle(isOn: $data.swUiePlain) {
                        Text("")
                    }
                        .labelsHidden()
                        .accessibilityIdentifier("swUiePlain")
                    Toggle(isOn: $data.swUieFalse) {
                        Text("")
                    }
                        .labelsHidden()
                        .allowsHitTesting(false)
                        .accessibilityIdentifier("swUieFalse")
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidPlain?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kidPlain")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onParPlain?()
                            }
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("parPlain")
                    ZStack(alignment: .topLeading) {
                        Group {
                            Rectangle()
                                .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                .frame(width: 80, height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                                data.onKidUieOld?()
                                            }
                                .accessibilityAddTraits(.isButton)
                                .overlay(alignment: .topLeading) {
                                    Color.clear
                                        .frame(width: 0.5, height: 0.5)
                                        .accessibilityElement(children: .ignore)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("kidUieOld")
                        }
                    }
                        .padding(16)
                        .background(SwiftJsonUIConfiguration.shared.getColor(for: "#DDDDDD") ?? Color.black)
                        .allowsHitTesting(false)
                        .contentShape(Rectangle())
                        .onTapGesture {
                                data.onParUieOld?()
                            }
                        .overlay(alignment: .topLeading) {
                            Color.clear
                                .frame(width: 0.5, height: 0.5)
                                .accessibilityElement(children: .ignore)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("parUieOld")
            }
            if let layout = Self.dynamicLayout {
                DynamicComponentBuilder(component: layout, data: dynamicData)
            } else {
                Text("layout did not decode").accessibilityIdentifier("gate_decode_failed")
            }
            }
        }
    }
}
