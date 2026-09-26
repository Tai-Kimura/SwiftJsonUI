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
//  `-onClickProbe V`: each control twice — over a value of its own and bound
//  to the data — with an onValueChange and an onClick; every call is also
//  logged in order (`seq[…]`). The ruling: the control's update, then
//  onValueChange, then onClick, and only from the user's operation.
//  `oc_vm` moves every bound value from the view model: nothing is called.
//

import SwiftUI
import SwiftJsonUI

final class OnClickProbeCounts: ObservableObject {
    @Published var counts: [String: Int] = [:]
    @Published var log: [String] = []
    func bump(_ name: String) {
        counts[name, default: 0] += 1
        log.append(name)
    }
}

struct OnClickProbeView: View {
    @StateObject private var counts = OnClickProbeCounts()
    @State private var nData = OnClickNData()
    @State private var cData = OnClickCData()
    @State private var eData = OnClickEData()
    @State private var vData = OnClickVData()
    /// The dynamic path's bound values for gate V (its handlers are the
    /// closures below; the view model's values live here).
    @State private var dynV = OnClickVData()
    @State private var wired = false

    static func arg(_ name: String, _ fallback: String) -> String {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: name), i + 1 < a.count else { return fallback }
        return a[i + 1]
    }
    private let gate = Self.arg("-onClickProbe", "N")
    private let path = Self.arg("-ocPath", "dynamic")

    static let layouts: [String: String] = [
        "V": #"{"type":"View","orientation":"vertical","spacing":4,"width":"matchParent","data":[{"name":"onSwuV","class":"(() -> Void)?"},{"name":"onSwuC","class":"(() -> Void)?"},{"name":"onSwbV","class":"(() -> Void)?"},{"name":"onSwbC","class":"(() -> Void)?"},{"name":"onCbuV","class":"(() -> Void)?"},{"name":"onCbuC","class":"(() -> Void)?"},{"name":"onCbbV","class":"(() -> Void)?"},{"name":"onCbbC","class":"(() -> Void)?"},{"name":"onRvuV","class":"(() -> Void)?"},{"name":"onRvuC","class":"(() -> Void)?"},{"name":"onRvbV","class":"(() -> Void)?"},{"name":"onRvbC","class":"(() -> Void)?"},{"name":"onSeguV","class":"(() -> Void)?"},{"name":"onSeguC","class":"(() -> Void)?"},{"name":"onSegbV","class":"(() -> Void)?"},{"name":"onSegbC","class":"(() -> Void)?"},{"name":"onSluV","class":"(() -> Void)?"},{"name":"onSluC","class":"(() -> Void)?"},{"name":"onSlbV","class":"(() -> Void)?"},{"name":"onSlbC","class":"(() -> Void)?"},{"name":"onSbuV","class":"(() -> Void)?"},{"name":"onSbuC","class":"(() -> Void)?"},{"name":"onSbbV","class":"(() -> Void)?"},{"name":"onSbbC","class":"(() -> Void)?"},{"name":"onSbdV","class":"(() -> Void)?"},{"name":"onSbdC","class":"(() -> Void)?"},{"name":"swbOn","class":"Bool","defaultValue":false},{"name":"cbbOn","class":"Bool","defaultValue":false},{"name":"rvbSel","class":"String","defaultValue":"ba"},{"name":"segbIdx","class":"Int","defaultValue":0},{"name":"slbVal","class":"Double","defaultValue":0.2},{"name":"sbbIdx","class":"Int","defaultValue":0},{"name":"sbdDate","class":"String","defaultValue":"2026-01-02"}],"child":[{"type":"Switch","isOn":false,"id":"swuV","onValueChange":"@{onSwuV}","onClick":"@{onSwuC}"},{"type":"Switch","isOn":"@{swbOn}","id":"swbV","onValueChange":"@{onSwbV}","onClick":"@{onSwbC}"},{"type":"CheckBox","label":"cbu","isOn":false,"id":"cbuV","onValueChange":"@{onCbuV}","onClick":"@{onCbuC}"},{"type":"CheckBox","label":"cbb","isOn":"@{cbbOn}","id":"cbbV","onValueChange":"@{onCbbV}","onClick":"@{onCbbC}"},{"type":"Radio","items":["ua","ub"],"selectedValue":"ua","id":"rvuV","onValueChange":"@{onRvuV}","onClick":"@{onRvuC}"},{"type":"Radio","items":["ba","bb"],"selectedValue":"@{rvbSel}","id":"rvbV","onValueChange":"@{onRvbV}","onClick":"@{onRvbC}"},{"type":"Segment","items":["ux","uy"],"selectedIndex":0,"id":"seguV","onValueChange":"@{onSeguV}","onClick":"@{onSeguC}"},{"type":"Segment","items":["bx","by"],"selectedIndex":"@{segbIdx}","id":"segbV","onValueChange":"@{onSegbV}","onClick":"@{onSegbC}"},{"type":"Slider","minimumValue":0,"maximumValue":1,"value":0.2,"id":"sluV","onValueChange":"@{onSluV}","onClick":"@{onSluC}"},{"type":"Slider","minimumValue":0,"maximumValue":1,"value":"@{slbVal}","id":"slbV","onValueChange":"@{onSlbV}","onClick":"@{onSlbC}"},{"type":"SelectBox","height":40,"items":["up","uq"],"selectedIndex":0,"id":"sbuV","onValueChange":"@{onSbuV}","onClick":"@{onSbuC}"},{"type":"SelectBox","height":40,"items":["bp","bq"],"selectedIndex":"@{sbbIdx}","id":"sbbV","onValueChange":"@{onSbbV}","onClick":"@{onSbbC}"},{"type":"SelectBox","height":40,"selectItemType":"Date","datePickerMode":"date","dateStringFormat":"yyyy-MM-dd","selectedDate":"@{sbdDate}","id":"sbdV","onValueChange":"@{onSbdV}","onClick":"@{onSbdC}"}]}"#,
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
        if gate == "V" {
            out["swbOn"] = $dynV.swbOn
            out["cbbOn"] = $dynV.cbbOn
            out["rvbSel"] = $dynV.rvbSel
            out["segbIdx"] = $dynV.segbIdx
            out["slbVal"] = $dynV.slbVal
            out["sbbIdx"] = $dynV.sbbIdx
            out["sbdDate"] = $dynV.sbdDate
        }
        return out
    }

    /// The view model moves every bound value of gate V.
    private func moveTheModel() {
        func move(_ d: inout OnClickVData) {
            d.swbOn.toggle()
            d.cbbOn.toggle()
            d.rvbSel = d.rvbSel == "bb" ? "ba" : "bb"
            d.segbIdx = 1 - d.segbIdx
            d.slbVal = d.slbVal > 0.5 ? 0.1 : 0.9
            d.sbbIdx = 1 - d.sbbIdx
            d.sbdDate = "2026-01-05"
        }
        if path == "codegen" { move(&vData) } else { move(&dynV) }
    }
    static let handlerNames: [String: [String]] = [
        "V": ["onSwuV", "onSwuC", "onSwbV", "onSwbC", "onCbuV", "onCbuC", "onCbbV", "onCbbC", "onRvuV", "onRvuC", "onRvbV", "onRvbC", "onSeguV", "onSeguC", "onSegbV", "onSegbC", "onSluV", "onSluC", "onSlbV", "onSlbC", "onSbuV", "onSbuC", "onSbbV", "onSbbC", "onSbdV", "onSbdC"],
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
        vData.onSwuV = { c.bump("onSwuV") }
        vData.onSwuC = { c.bump("onSwuC") }
        vData.onSwbV = { c.bump("onSwbV") }
        vData.onSwbC = { c.bump("onSwbC") }
        vData.onCbuV = { c.bump("onCbuV") }
        vData.onCbuC = { c.bump("onCbuC") }
        vData.onCbbV = { c.bump("onCbbV") }
        vData.onCbbC = { c.bump("onCbbC") }
        vData.onRvuV = { c.bump("onRvuV") }
        vData.onRvuC = { c.bump("onRvuC") }
        vData.onRvbV = { c.bump("onRvbV") }
        vData.onRvbC = { c.bump("onRvbC") }
        vData.onSeguV = { c.bump("onSeguV") }
        vData.onSeguC = { c.bump("onSeguC") }
        vData.onSegbV = { c.bump("onSegbV") }
        vData.onSegbC = { c.bump("onSegbC") }
        vData.onSluV = { c.bump("onSluV") }
        vData.onSluC = { c.bump("onSluC") }
        vData.onSlbV = { c.bump("onSlbV") }
        vData.onSlbC = { c.bump("onSlbC") }
        vData.onSbuV = { c.bump("onSbuV") }
        vData.onSbuC = { c.bump("onSbuC") }
        vData.onSbbV = { c.bump("onSbbV") }
        vData.onSbbC = { c.bump("onSbbC") }
        vData.onSbdV = { c.bump("onSbdV") }
        vData.onSbdC = { c.bump("onSbdC") }
    }

    private var readout: String {
        "gate=\(gate) path=\(path) counts[" + counts.counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",") + "]"
            + " seq[" + counts.log.joined(separator: ",") + "]"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ready").accessibilityIdentifier("oc_ready")
            Text(readout).font(.system(size: 8)).lineLimit(1).accessibilityIdentifier("oc_readout")
            if gate == "V" {
                Button("move the model") { moveTheModel() }.font(.system(size: 12)).accessibilityIdentifier("oc_vm")
            }
            if path == "codegen" {
                switch gate {
                case "C": OnClickCCodegenPaste(data: $cData)
                case "E": OnClickECodegenPaste(data: $eData)
                case "V": OnClickVCodegenPaste(data: $vData)
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
