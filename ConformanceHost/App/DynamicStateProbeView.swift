//
//  DynamicStateProbeView.swift
//  ConformanceHost
//
//  Does what the user chose in a Dynamic control survive a data change that
//  does not concern it, and does the control follow its bound value when the
//  view model changes it? (ticket kjui-dynamic-stateful-components-reset-on-
//  unrelated-data: KotlinJsonUI's Dynamic reset every stateful control on any
//  data change; this measures SwiftJsonUI's.) NOT part of the conformance
//  suite. Launch with `-dynamicStateProbe <form>`:
//
//    static    literal values, no binding
//    plain     `@{key}` over plain values in the data — nothing writes back
//    binding   `@{key}` over SwiftUI.Binding values the model owns
//
//  Buttons outside the dynamic tree: `dsp_unrelated` changes a key no control
//  reads (a Label in the tree shows it, so the test sees the new data
//  arrived); `dsp_vm_chosen` / `dsp_vm_declared` set every bound value to the
//  one the test chooses / the declared one. `dsp_readout` shows the model's
//  values.
//

import SwiftUI
import SwiftJsonUI

final class DynamicStateProbeData: ObservableObject {
    @Published var unrelated = 0
    @Published var values: [String: Any] = DynamicStateProbeView.declared
}

struct DynamicStateProbeView: View {
    @StateObject private var data = DynamicStateProbeData()

    static let declared: [String: Any] = [
        "sw_on": false, "tg_on": false, "cb_on": false, "rv_sel": "ra", "seg_sel": 0,
        "tab_sel": 0, "sl_val": 0.2, "sb_idx": 0, "sbi_sel": "pp",
    ]
    static let chosen: [String: Any] = [
        "sw_on": true, "tg_on": true, "cb_on": true, "rv_sel": "rb", "seg_sel": 1,
        "tab_sel": 1, "sl_val": 0.8, "sb_idx": 1, "sbi_sel": "qq",
    ]

    static var form: String {
        let arguments = ProcessInfo.processInfo.arguments
        guard let at = arguments.firstIndex(of: "-dynamicStateProbe"), at + 1 < arguments.count else { return "static" }
        return arguments[at + 1]
    }

    private static func layout(_ form: String) -> DynamicComponent? {
        let bound = form != "static"
        func v(_ literal: String, _ key: String) -> String { bound ? #""@{\#(key)}""# : literal }
        let items = [
            #"{"type": "Label", "id": "unrelated_shown", "text": "@{unrelated}"}"#,
            #"{"type": "Switch", "id": "sw", "isOn": \#(v("false", "sw_on"))}"#,
            #"{"type": "Toggle", "id": "tg", "isOn": \#(v("false", "tg_on"))}"#,
            #"{"type": "CheckBox", "id": "cb", "label": "cbl", "isOn": \#(v("false", "cb_on"))}"#,
            #"{"type": "Radio", "id": "rv", "items": ["ra", "rb"], "selectedValue": \#(v(#""ra""#, "rv_sel"))}"#,
            #"{"type": "Segment", "id": "seg", "items": ["sx", "sy"], "selectedIndex": \#(v("0", "seg_sel"))}"#,
            #"{"type": "View", "width": "matchParent", "height": 130, "child": [{"type": "TabView", "id": "tab", "#
                + #""tabs": [{"title": "ta"}, {"title": "tb"}], "selectedIndex": \#(v("0", "tab_sel"))}]}"#,
            #"{"type": "Slider", "id": "sl", "minimumValue": 0, "maximumValue": 1, "value": \#(v("0.2", "sl_val"))}"#,
            #"{"type": "SelectBox", "id": "sb", "height": 40, "items": ["pp", "qq"], "selectedIndex": \#(v("0", "sb_idx"))}"#,
            #"{"type": "SelectBox", "id": "sbi", "height": 40, "items": ["pp", "qq"], "selectedItem": \#(v(#""pp""#, "sbi_sel"))}"#,
        ]
        let json = #"{"type": "View", "orientation": "vertical", "spacing": 8, "width": "matchParent", "child": ["#
            + items.joined(separator: ", ") + "]}"
        return try? JSONDecoder().decode(DynamicComponent.self, from: Data(json.utf8))
    }

    private let form = Self.form
    private let dynamicLayout = Self.layout(Self.form)

    private var dynamicData: [String: Any] {
        let data = self.data
        var out: [String: Any] = ["unrelated": "u\(data.unrelated)"]
        switch form {
        case "plain":
            for (key, value) in data.values { out[key] = value }
        case "binding":
            func bind<T>(_ key: String, _ fallback: T) -> SwiftUI.Binding<T> {
                SwiftUI.Binding(get: { data.values[key] as? T ?? fallback }, set: { data.values[key] = $0 })
            }
            out["sw_on"] = bind("sw_on", false)
            out["tg_on"] = bind("tg_on", false)
            out["cb_on"] = bind("cb_on", false)
            out["rv_sel"] = bind("rv_sel", "")
            out["seg_sel"] = bind("seg_sel", 0)
            out["tab_sel"] = bind("tab_sel", 0)
            out["sl_val"] = bind("sl_val", 0.0)
            out["sb_idx"] = bind("sb_idx", 0)
            out["sbi_sel"] = bind("sbi_sel", "")
        default:
            break
        }
        return out
    }

    private var readout: String {
        let values = data.values.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        return "form=\(form) unrelated=\(data.unrelated) values[\(values)]"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button("unrel") { data.unrelated += 1 }.accessibilityIdentifier("dsp_unrelated")
                Button("vmC") { data.values = Self.chosen }.accessibilityIdentifier("dsp_vm_chosen")
                Button("vmD") { data.values = Self.declared }.accessibilityIdentifier("dsp_vm_declared")
                Text("ready").accessibilityIdentifier("dsp_ready")
            }
            Text(readout).font(.system(size: 8)).accessibilityIdentifier("dsp_readout")
            if let layout = dynamicLayout {
                DynamicComponentBuilder(component: layout, data: dynamicData)
            } else {
                Text("layout did not decode").accessibilityIdentifier("dsp_decode_failed")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
    }
}
