//
//  InteractionInputsProbeView.swift
//  ConformanceHost
//
//  What `userInteractionEnabled: false` stops on the types that read neither
//  it nor its binding before: a Button's action, a TextField's and a
//  TextView's focus, a SelectBox's sheet. NOT part of the conformance suite.
//  Launch with `-interactionInputsProbe`.
//
//  Left: what `jui build` (sjui_tools, JsonToSwiftUIConverter) emits for each,
//  with no gate and under `userInteractionEnabled: false`, pasted unchanged;
//  the `@FocusState` properties are the ones the emission names. Then what
//  `enabled` — false, and a binding resolving false — stops besides a tap:
//  an Image's tap, a long press, a pan. Below: the dynamic runtime's.
//

import SwiftUI
import SwiftJsonUI

final class InteractionInputsProbeData: ObservableObject {
    @Published var counts: [String: Int] = [:]
    @Published var tfPlain = ""
    @Published var tfUieFalse = ""
    @Published var tvPlain = ""
    @Published var tvUieFalse = ""
    @Published var cgTfPlainIsFocused = false
    @Published var cgTfUieFalseIsFocused = false
    @Published var cgTvPlainIsFocused = false
    @Published var cgTvUieFalseIsFocused = false
    @Published var sbPlain: String? = nil
    @Published var sbUieFalse: String? = nil
    @Published var dynText: [String: String] = [:]

    func bump(_ name: String) { counts[name, default: 0] += 1 }
    lazy var onBtnPlain: (() -> Void)? = { [weak self] in self?.bump("cgBtnPlain") }
    lazy var onBtnUieFalse: (() -> Void)? = { [weak self] in self?.bump("cgBtnUieFalse") }
    var gateClosed: Bool? = false
    lazy var onDragEnBound: (() -> Void)? = { [weak self] in self?.bump("cgDragEnBound") }
    lazy var onDragEnFalse: (() -> Void)? = { [weak self] in self?.bump("cgDragEnFalse") }
    lazy var onDragPlain: (() -> Void)? = { [weak self] in self?.bump("cgDragPlain") }
    lazy var onHoldEnBound: (() -> Void)? = { [weak self] in self?.bump("cgHoldEnBound") }
    lazy var onHoldEnFalse: (() -> Void)? = { [weak self] in self?.bump("cgHoldEnFalse") }
    lazy var onHoldPlain: (() -> Void)? = { [weak self] in self?.bump("cgHoldPlain") }
    lazy var onImgEnBound: (() -> Void)? = { [weak self] in self?.bump("cgImgEnBound") }
    lazy var onImgEnFalse: (() -> Void)? = { [weak self] in self?.bump("cgImgEnFalse") }
    lazy var onImgPlain: (() -> Void)? = { [weak self] in self?.bump("cgImgPlain") }
}

struct InteractionInputsProbeView: View {
    @StateObject private var data = InteractionInputsProbeData()
    @FocusState private var cgTfPlainIsFocused: Bool
    @FocusState private var cgTfUieFalseIsFocused: Bool

    static let dynamicRows: [String] = [
        ##"{"type": "View", "orientation": "horizontal", "spacing": 12, "child": [{"id": "dynBtnPlain", "type": "Button", "text": "DPlain", "onClick": "@{on_dynBtnPlain}"}, {"id": "dynTfPlain", "type": "TextField", "text": "@{dynTfPlain}", "hint": "tf", "width": 60}, {"id": "dynTvPlain", "type": "TextView", "text": "@{dynTvPlain}", "width": 60, "height": 40}, {"id": "dynSbPlain", "type": "SelectBox", "items": ["dxPlain", "dyPlain"], "width": 80}]}"##,
        ##"{"type": "View", "orientation": "horizontal", "spacing": 12, "child": [{"id": "dynBtnUieFalse", "type": "Button", "text": "DUieFalse", "onClick": "@{on_dynBtnUieFalse}", "userInteractionEnabled": false}, {"id": "dynTfUieFalse", "type": "TextField", "text": "@{dynTfUieFalse}", "hint": "tf", "width": 60, "userInteractionEnabled": false}, {"id": "dynTvUieFalse", "type": "TextView", "text": "@{dynTvUieFalse}", "width": 60, "height": 40, "userInteractionEnabled": false}, {"id": "dynSbUieFalse", "type": "SelectBox", "items": ["dxUieFalse", "dyUieFalse"], "width": 80, "userInteractionEnabled": false}]}"##,
        ##"{"type": "View", "orientation": "horizontal", "spacing": 8, "child": [{"id": "dynImgPlain", "type": "Image", "srcName": "probe_dot", "alt": "dyn img", "width": 40, "height": 30, "background": "#3366CC", "onClick": "@{on_dynImgPlain}"}, {"id": "dynImgEnFalse", "type": "Image", "srcName": "probe_dot", "alt": "dyn img", "width": 40, "height": 30, "background": "#3366CC", "onClick": "@{on_dynImgEnFalse}", "enabled": false}, {"id": "dynImgEnBound", "type": "Image", "srcName": "probe_dot", "alt": "dyn img", "width": 40, "height": 30, "background": "#3366CC", "onClick": "@{on_dynImgEnBound}", "enabled": "@{gate_closed}"}]}"##,
        ##"{"type": "View", "orientation": "horizontal", "spacing": 8, "child": [{"id": "dynHoldPlain", "type": "View", "width": 40, "height": 30, "background": "#3366CC", "onLongPress": "@{on_dynHoldPlain}"}, {"id": "dynHoldEnFalse", "type": "View", "width": 40, "height": 30, "background": "#3366CC", "onLongPress": "@{on_dynHoldEnFalse}", "enabled": false}, {"id": "dynHoldEnBound", "type": "View", "width": 40, "height": 30, "background": "#3366CC", "onLongPress": "@{on_dynHoldEnBound}", "enabled": "@{gate_closed}"}]}"##,
        ##"{"type": "View", "orientation": "horizontal", "spacing": 8, "child": [{"id": "dynDragPlain", "type": "View", "width": 80, "height": 30, "background": "#3366CC", "onPan": "@{on_dynDragPlain}"}, {"id": "dynDragEnFalse", "type": "View", "width": 80, "height": 30, "background": "#3366CC", "onPan": "@{on_dynDragEnFalse}", "enabled": false}, {"id": "dynDragEnBound", "type": "View", "width": 80, "height": 30, "background": "#3366CC", "onPan": "@{on_dynDragEnBound}", "enabled": "@{gate_closed}"}]}"##,
    ]

    private static let dynamicLayout: DynamicComponent? = {
        let json = #"{"type": "View", "orientation": "vertical", "spacing": 8, "child": ["# + dynamicRows.joined(separator: ", ") + "]}"
        return try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }()

    private var dynamicData: [String: Any] {
        let data = self.data
        var out: [String: Any] = [:]
        for id in ["dynBtnPlain", "dynBtnUieFalse"] { out["on_\(id)"] = { () -> Void in data.bump(id) } }
        out["gate_closed"] = false
        for kind in ["Img", "Hold", "Drag"] {
            for g in ["Plain", "EnFalse", "EnBound"] {
                let id = "dyn\(kind)\(g)"
                out["on_\(id)"] = { () -> Void in data.bump(id) }
            }
        }
        for key in ["dynTfPlain", "dynTfUieFalse", "dynTvPlain", "dynTvUieFalse"] {
            out[key] = SwiftUI.Binding<String>(get: { data.dynText[key] ?? "" }, set: { data.dynText[key] = $0 })
        }
        return out
    }

    private var readout: String {
        "counts[" + data.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",") + "]"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("interaction inputs probe").accessibilityIdentifier("inputs_probe_ready")
            Text(readout).font(.system(size: 6)).accessibilityIdentifier("inputs_readout")
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                                StateAwareButtonView(
                                    text: "BPlain",
                                    action: { data.onBtnPlain?() },
                                    isEnabled: true
                                )
                                    .accessibilityIdentifier("cgBtnPlain")
                                TextField("tf".localized(), text: $data.tfPlain)
                                    .focused($cgTfPlainIsFocused)
                                    .onChange(of: data.cgTfPlainIsFocused) { _, newValue in
                                    cgTfPlainIsFocused = newValue
                                }
                                    .onChange(of: cgTfPlainIsFocused) { _, newValue in
                                    data.cgTfPlainIsFocused = newValue
                                }
                                    .frame(width: 60)
                                    .accessibilityIdentifier("cgTfPlain")
                                TextViewWithPlaceholder(
                                    text: $data.tvPlain,
                                    isFocused: $data.cgTvPlainIsFocused
                                )
                                    .frame(width: 60, height: 40)
                                    .accessibilityIdentifier("cgTvPlain")
                                SelectBoxView(
                                    id: "cgSbPlain",
                                    selectItemType: .normal,
                                    items: ["xPlain", "yPlain"],
                                    selectedIndex: ["xPlain", "yPlain"].firstIndex(of: (data.sbPlain ?? "")),
                                )
                                    .frame(width: 80)
                                    .accessibilityIdentifier("cgSbPlain")
                        }
                        HStack(alignment: .top, spacing: 12) {
                                StateAwareButtonView(
                                    text: "BUieFalse",
                                    action: { data.onBtnUieFalse?() },
                                    isEnabled: true
                                )
                                    .allowsHitTesting(false)
                                    .accessibilityIdentifier("cgBtnUieFalse")
                                TextField("tf".localized(), text: $data.tfUieFalse)
                                    .focused($cgTfUieFalseIsFocused)
                                    .onChange(of: data.cgTfUieFalseIsFocused) { _, newValue in
                                    cgTfUieFalseIsFocused = newValue
                                }
                                    .onChange(of: cgTfUieFalseIsFocused) { _, newValue in
                                    data.cgTfUieFalseIsFocused = newValue
                                }
                                    .frame(width: 60)
                                    .allowsHitTesting(false)
                                    .accessibilityIdentifier("cgTfUieFalse")
                                TextViewWithPlaceholder(
                                    text: $data.tvUieFalse,
                                    isFocused: $data.cgTvUieFalseIsFocused
                                )
                                    .frame(width: 60, height: 40)
                                    .allowsHitTesting(false)
                                    .accessibilityIdentifier("cgTvUieFalse")
                                SelectBoxView(
                                    id: "cgSbUieFalse",
                                    selectItemType: .normal,
                                    items: ["xUieFalse", "yUieFalse"],
                                    selectedIndex: ["xUieFalse", "yUieFalse"].firstIndex(of: (data.sbUieFalse ?? "")),
                                )
                                    .frame(width: 80)
                                    .allowsHitTesting(false)
                                    .accessibilityIdentifier("cgSbUieFalse")
                        }
                }
                VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                                Image("probe_dot")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .accessibilityLabel(Text("img Plain"))
                                    .frame(width: 40, height: 30)
                                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                                    data.onImgPlain?()
                                                }
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityIdentifier("cgImgPlain")
                                Image("probe_dot")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .accessibilityLabel(Text("img EnFalse"))
                                    .frame(width: 40, height: 30)
                                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                                    data.onImgEnFalse?()
                                                }
                                    .disabled(true)
                                    .accessibilityIdentifier("cgImgEnFalse")
                                    .disabled(true)
                                Image("probe_dot")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .accessibilityLabel(Text("img EnBound"))
                                    .frame(width: 40, height: 30)
                                    .background(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                                    data.onImgEnBound?()
                                                }
                                    .accessibilityAddTraits(.isButton)
                                    .disabled(!((data.gateClosed ?? false)))
                                    .accessibilityIdentifier("cgImgEnBound")
                                    .disabled(!((data.gateClosed ?? false)))
                        }
                        HStack(alignment: .top, spacing: 8) {
                                Rectangle()
                                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .frame(width: 40, height: 30)
                                    .onLongPressGesture {
                                        data.onHoldPlain?()
                                    }
                                    .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("cgHoldPlain")
                                Rectangle()
                                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .frame(width: 40, height: 30)
                                    .onLongPressGesture {
                                        data.onHoldEnFalse?()
                                    }
                                    .disabled(true)
                                    .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("cgHoldEnFalse")
                                    .disabled(true)
                                Rectangle()
                                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .frame(width: 40, height: 30)
                                    .onLongPressGesture {
                                        data.onHoldEnBound?()
                                    }
                                    .disabled(!((data.gateClosed ?? false)))
                                    .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("cgHoldEnBound")
                                    .disabled(!((data.gateClosed ?? false)))
                        }
                        HStack(alignment: .top, spacing: 8) {
                                Rectangle()
                                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .frame(width: 80, height: 30)
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 10).onChanged { value in
                                            data.onDragPlain?()
                                        }
                                    )
                                    .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("cgDragPlain")
                                Rectangle()
                                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .frame(width: 80, height: 30)
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 10).onChanged { value in
                                            data.onDragEnFalse?()
                                        }
                                    )
                                    .disabled(true)
                                    .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("cgDragEnFalse")
                                    .disabled(true)
                                Rectangle()
                                    .fill(SwiftJsonUIConfiguration.shared.getColor(for: "#3366CC") ?? Color.black)
                                    .frame(width: 80, height: 30)
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 10).onChanged { value in
                                            data.onDragEnBound?()
                                        }
                                    )
                                    .disabled(!((data.gateClosed ?? false)))
                                    .overlay(alignment: .topLeading) {
                                        Color.clear
                                            .frame(width: 0.5, height: 0.5)
                                            .accessibilityElement(children: .ignore)
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("cgDragEnBound")
                                    .disabled(!((data.gateClosed ?? false)))
                        }
                }
                if let layout = Self.dynamicLayout {
                    DynamicComponentBuilder(component: layout, data: dynamicData)
                } else {
                    Text("layout did not decode").accessibilityIdentifier("inputs_decode_failed")
                }
            }
            Spacer()
        }
    }
}
