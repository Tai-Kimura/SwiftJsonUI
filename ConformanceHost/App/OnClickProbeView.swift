//
//  OnClickProbeView.swift
//  ConformanceHost
//
//  How many times a control's onClick is called, and from what — ticket
//  control-onclick-is-called-differently-on-every-path (the ruling: once, from
//  the control's own operation, after its update; `canTap: false` stops the
//  call, `enabled: false` the operation and so the call; a TextField / TextView
//  never calls it). NOT part of the conformance suite. Launch with
//  `-onClickProbe <N|C|E>` (no gate / canTap false / enabled false) and
//  `-ocPath <dynamic|codegen>`: DynamicView over the layout, or what sjui build
//  emits for it (OnClickCodegenPaste). Every handler counts its calls into the
//  readout.
//

import SwiftUI
import SwiftJsonUI

final class OnClickProbeCounts: ObservableObject {
    @Published var counts: [String: Int] = [:]
    func bump(_ name: String) { counts[name, default: 0] += 1 }
}

struct OnClickProbeView: View {
    @StateObject private var counts = OnClickProbeCounts()
    @State private var nData = OnClickNData()
    @State private var cData = OnClickCData()
    @State private var eData = OnClickEData()
    @State private var wired = false

    static func arg(_ name: String, _ fallback: String) -> String {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: name), i + 1 < a.count else { return fallback }
        return a[i + 1]
    }
    private let gate = Self.arg("-onClickProbe", "N")
    private let path = Self.arg("-ocPath", "dynamic")

    static let layouts: [String: String] = [
        "N": #"{"type":"View","orientation":"vertical","spacing":6,"width":"matchParent","data":[{"name":"onSwN","class":"(() -> Void)?"},{"name":"onCbN","class":"(() -> Void)?"},{"name":"onRvN","class":"(() -> Void)?"},{"name":"onRgaN","class":"(() -> Void)?"},{"name":"onRgbN","class":"(() -> Void)?"},{"name":"onSegN","class":"(() -> Void)?"},{"name":"onSlN","class":"(() -> Void)?"},{"name":"onSbN","class":"(() -> Void)?"},{"name":"onTfN","class":"(() -> Void)?"},{"name":"onTvN","class":"(() -> Void)?"},{"name":"onSwlN","class":"(() -> Void)?"}],"child":[{"type":"Switch","isOn":false,"id":"swN","onClick":"@{onSwN}"},{"type":"CheckBox","label":"cbl","isOn":false,"id":"cbN","onClick":"@{onCbN}"},{"type":"Radio","items":["ra","rb"],"selectedValue":"ra","id":"rvN","onClick":"@{onRvN}"},{"type":"Radio","group":"grpN","text":"rg1","checked":true,"id":"rgaN","onClick":"@{onRgaN}"},{"type":"Radio","group":"grpN","text":"rg2","id":"rgbN","onClick":"@{onRgbN}"},{"type":"Segment","items":["sx","sy"],"selectedIndex":0,"id":"segN","onClick":"@{onSegN}"},{"type":"Slider","minimumValue":0,"maximumValue":1,"value":0.2,"id":"slN","onClick":"@{onSlN}"},{"type":"SelectBox","height":40,"items":["pp","qq"],"selectedIndex":0,"id":"sbN","onClick":"@{onSbN}"},{"type":"TextField","height":40,"text":"t0","id":"tfN","onClick":"@{onTfN}"},{"type":"TextView","height":50,"text":"v0","id":"tvN","onClick":"@{onTvN}"},{"type":"Switch","isOn":false,"text":"swl label","id":"swlN","onClick":"@{onSwlN}"}]}"#,
        "C": #"{"type":"View","orientation":"vertical","spacing":6,"width":"matchParent","data":[{"name":"onSwC","class":"(() -> Void)?"},{"name":"onCbC","class":"(() -> Void)?"},{"name":"onRvC","class":"(() -> Void)?"},{"name":"onRgaC","class":"(() -> Void)?"},{"name":"onRgbC","class":"(() -> Void)?"},{"name":"onSegC","class":"(() -> Void)?"},{"name":"onSlC","class":"(() -> Void)?"},{"name":"onSbC","class":"(() -> Void)?"},{"name":"onTfC","class":"(() -> Void)?"},{"name":"onTvC","class":"(() -> Void)?"},{"name":"onSwlC","class":"(() -> Void)?"}],"child":[{"type":"Switch","isOn":false,"id":"swC","onClick":"@{onSwC}","canTap":false},{"type":"CheckBox","label":"cbl","isOn":false,"id":"cbC","onClick":"@{onCbC}","canTap":false},{"type":"Radio","items":["ra","rb"],"selectedValue":"ra","id":"rvC","onClick":"@{onRvC}","canTap":false},{"type":"Radio","group":"grpC","text":"rg1","checked":true,"id":"rgaC","onClick":"@{onRgaC}","canTap":false},{"type":"Radio","group":"grpC","text":"rg2","id":"rgbC","onClick":"@{onRgbC}","canTap":false},{"type":"Segment","items":["sx","sy"],"selectedIndex":0,"id":"segC","onClick":"@{onSegC}","canTap":false},{"type":"Slider","minimumValue":0,"maximumValue":1,"value":0.2,"id":"slC","onClick":"@{onSlC}","canTap":false},{"type":"SelectBox","height":40,"items":["pp","qq"],"selectedIndex":0,"id":"sbC","onClick":"@{onSbC}","canTap":false},{"type":"TextField","height":40,"text":"t0","id":"tfC","onClick":"@{onTfC}","canTap":false},{"type":"TextView","height":50,"text":"v0","id":"tvC","onClick":"@{onTvC}","canTap":false},{"type":"Switch","isOn":false,"text":"swl label","id":"swlC","onClick":"@{onSwlC}","canTap":false}]}"#,
        "E": #"{"type":"View","orientation":"vertical","spacing":6,"width":"matchParent","data":[{"name":"onSwE","class":"(() -> Void)?"},{"name":"onCbE","class":"(() -> Void)?"},{"name":"onRvE","class":"(() -> Void)?"},{"name":"onRgaE","class":"(() -> Void)?"},{"name":"onRgbE","class":"(() -> Void)?"},{"name":"onSegE","class":"(() -> Void)?"},{"name":"onSlE","class":"(() -> Void)?"},{"name":"onSbE","class":"(() -> Void)?"},{"name":"onTfE","class":"(() -> Void)?"},{"name":"onTvE","class":"(() -> Void)?"},{"name":"onSwlE","class":"(() -> Void)?"}],"child":[{"type":"Switch","isOn":false,"id":"swE","onClick":"@{onSwE}","enabled":false},{"type":"CheckBox","label":"cbl","isOn":false,"id":"cbE","onClick":"@{onCbE}","enabled":false},{"type":"Radio","items":["ra","rb"],"selectedValue":"ra","id":"rvE","onClick":"@{onRvE}","enabled":false},{"type":"Radio","group":"grpE","text":"rg1","checked":true,"id":"rgaE","onClick":"@{onRgaE}","enabled":false},{"type":"Radio","group":"grpE","text":"rg2","id":"rgbE","onClick":"@{onRgbE}","enabled":false},{"type":"Segment","items":["sx","sy"],"selectedIndex":0,"id":"segE","onClick":"@{onSegE}","enabled":false},{"type":"Slider","minimumValue":0,"maximumValue":1,"value":0.2,"id":"slE","onClick":"@{onSlE}","enabled":false},{"type":"SelectBox","height":40,"items":["pp","qq"],"selectedIndex":0,"id":"sbE","onClick":"@{onSbE}","enabled":false},{"type":"TextField","height":40,"text":"t0","id":"tfE","onClick":"@{onTfE}","enabled":false},{"type":"TextView","height":50,"text":"v0","id":"tvE","onClick":"@{onTvE}","enabled":false},{"type":"Switch","isOn":false,"text":"swl label","id":"swlE","onClick":"@{onSwlE}","enabled":false}]}"#,
    ]

    private var layout: DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data((Self.layouts[gate] ?? "").utf8))
    }

    /// The handlers the layout names, each counting into the readout.
    private var dynamicData: [String: Any] {
        let c = counts
        var out: [String: Any] = [:]
        for name in (Self.handlerNames[gate] ?? []) { out[name] = { () -> Void in c.bump(name) } }
        return out
    }
    static let handlerNames: [String: [String]] = [
        "N": ["onSwN", "onCbN", "onRvN", "onRgaN", "onRgbN", "onSegN", "onSlN", "onSbN", "onTfN", "onTvN", "onSwlN"],
        "C": ["onSwC", "onCbC", "onRvC", "onRgaC", "onRgbC", "onSegC", "onSlC", "onSbC", "onTfC", "onTvC", "onSwlC"],
        "E": ["onSwE", "onCbE", "onRvE", "onRgaE", "onRgbE", "onSegE", "onSlE", "onSbE", "onTfE", "onTvE", "onSwlE"],
    ]

    private func wire() {
        guard !wired else { return }
        wired = true
        let c = counts
        nData.onSwN = { c.bump("onSwN") }
        nData.onCbN = { c.bump("onCbN") }
        nData.onRvN = { c.bump("onRvN") }
        nData.onRgaN = { c.bump("onRgaN") }
        nData.onRgbN = { c.bump("onRgbN") }
        nData.onSegN = { c.bump("onSegN") }
        nData.onSlN = { c.bump("onSlN") }
        nData.onSbN = { c.bump("onSbN") }
        nData.onTfN = { c.bump("onTfN") }
        nData.onTvN = { c.bump("onTvN") }
        nData.onSwlN = { c.bump("onSwlN") }
        cData.onSwC = { c.bump("onSwC") }
        cData.onCbC = { c.bump("onCbC") }
        cData.onRvC = { c.bump("onRvC") }
        cData.onRgaC = { c.bump("onRgaC") }
        cData.onRgbC = { c.bump("onRgbC") }
        cData.onSegC = { c.bump("onSegC") }
        cData.onSlC = { c.bump("onSlC") }
        cData.onSbC = { c.bump("onSbC") }
        cData.onTfC = { c.bump("onTfC") }
        cData.onTvC = { c.bump("onTvC") }
        cData.onSwlC = { c.bump("onSwlC") }
        eData.onSwE = { c.bump("onSwE") }
        eData.onCbE = { c.bump("onCbE") }
        eData.onRvE = { c.bump("onRvE") }
        eData.onRgaE = { c.bump("onRgaE") }
        eData.onRgbE = { c.bump("onRgbE") }
        eData.onSegE = { c.bump("onSegE") }
        eData.onSlE = { c.bump("onSlE") }
        eData.onSbE = { c.bump("onSbE") }
        eData.onTfE = { c.bump("onTfE") }
        eData.onTvE = { c.bump("onTvE") }
        eData.onSwlE = { c.bump("onSwlE") }
    }

    private var readout: String {
        "gate=\(gate) path=\(path) counts[" + counts.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",") + "]"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ready").accessibilityIdentifier("oc_ready")
            Text(readout).font(.system(size: 8)).accessibilityIdentifier("oc_readout")
            if path == "codegen" {
                switch gate {
                case "C": OnClickCCodegenPaste(data: $cData)
                case "E": OnClickECodegenPaste(data: $eData)
                default: OnClickNCodegenPaste(data: $nData)
                }
            } else if let layout {
                DynamicView(component: layout, viewId: "oc", data: dynamicData)
            } else {
                Text("layout did not decode").accessibilityIdentifier("oc_decode_failed")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .onAppear { wire() }
    }
}
