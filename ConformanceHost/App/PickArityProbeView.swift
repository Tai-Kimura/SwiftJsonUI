//
//  PickArityProbeView.swift
//  ConformanceHost
//
//  What a SelectBox's onValueChange is handed, by the parameters the data
//  declares for it — 4f's ruling on control-onclick-is-called-differently-on-
//  every-path (1.9.0): `(String)` the picked item, even with selectedIndex
//  bound; `(String, Int)` the viewId and the index; `(String, String)` the
//  viewId and the item — each over an item binding (…i), an index binding
//  (…x) and nothing bound (…n); a date picker's `(String)` and
//  `(String, String)`; and two boxes without an id, whose viewId is the drawn
//  type and the position (`selectBox_0_11`, `selectBox_0_12`); last, a date
//  picker whose handler takes an index, which neither path calls. NOT part of the
//  conformance suite. Launch with `-pickArityProbe` and `-paPath
//  <dynamic|codegen>`: DynamicView over the layout, or what sjui build emits
//  for it (PickArityCodegenPaste). Every call is logged with its arguments.
//

import SwiftUI
import SwiftJsonUI

final class PickArityLog: ObservableObject {
    @Published var calls: [String] = []
    func record(_ call: String) { calls.append(call) }
}

struct PickArityProbeView: View {
    @StateObject private var log = PickArityLog()
    /// The codegen path's data, and the dynamic path's bound values.
    @State private var data = PickArityData()
    @State private var dyn = PickArityData()
    @State private var wired = false
    private let path = OnClickProbeView.arg("-paPath", "dynamic")

    static let layout = #"{"type":"View","orientation":"vertical","spacing":3,"width":"matchParent","data":[{"name":"pSi","class":"((String) -> Void)?"},{"name":"pSx","class":"((String) -> Void)?"},{"name":"pSn","class":"((String) -> Void)?"},{"name":"pIi","class":"((String, Int) -> Void)?"},{"name":"pIx","class":"((String, Int) -> Void)?"},{"name":"pIn","class":"((String, Int) -> Void)?"},{"name":"pNi","class":"((String, String) -> Void)?"},{"name":"pNx","class":"((String, String) -> Void)?"},{"name":"pNn","class":"((String, String) -> Void)?"},{"name":"dS","class":"((String) -> Void)?"},{"name":"dN","class":"((String, String) -> Void)?"},{"name":"aI","class":"((String, Int) -> Void)?"},{"name":"aN","class":"((String, String) -> Void)?"},{"name":"dI","class":"((String, Int) -> Void)?"},{"name":"dayI","class":"String","defaultValue":"2026-01-02"},{"name":"selS","class":"String","defaultValue":""},{"name":"idxS","class":"Int","defaultValue":0},{"name":"selI","class":"String","defaultValue":""},{"name":"idxI","class":"Int","defaultValue":0},{"name":"selN","class":"String","defaultValue":""},{"name":"idxN","class":"Int","defaultValue":0},{"name":"dayS","class":"String","defaultValue":"2026-01-02"},{"name":"dayN","class":"String","defaultValue":"2026-01-02"}],"child":[{"type":"SelectBox","width":"matchParent","height":36,"id":"sbSi","items":["Si1","Si2"],"onValueChange":"@{pSi}","selectedItem":"@{selS}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbSx","items":["Sx1","Sx2"],"onValueChange":"@{pSx}","selectedIndex":"@{idxS}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbSn","items":["Sn1","Sn2"],"onValueChange":"@{pSn}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbIi","items":["Ii1","Ii2"],"onValueChange":"@{pIi}","selectedItem":"@{selI}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbIx","items":["Ix1","Ix2"],"onValueChange":"@{pIx}","selectedIndex":"@{idxI}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbIn","items":["In1","In2"],"onValueChange":"@{pIn}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbNi","items":["Ni1","Ni2"],"onValueChange":"@{pNi}","selectedItem":"@{selN}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbNx","items":["Nx1","Nx2"],"onValueChange":"@{pNx}","selectedIndex":"@{idxN}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbNn","items":["Nn1","Nn2"],"onValueChange":"@{pNn}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbDS","selectItemType":"Date","datePickerMode":"date","dateStringFormat":"yyyy-MM-dd","selectedDate":"@{dayS}","onValueChange":"@{dS}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbDN","selectItemType":"Date","datePickerMode":"date","dateStringFormat":"yyyy-MM-dd","selectedDate":"@{dayN}","onValueChange":"@{dN}"},{"type":"SelectBox","width":"matchParent","height":36,"items":["aI1","aI2"],"selectedIndex":0,"onValueChange":"@{aI}"},{"type":"SelectBox","width":"matchParent","height":36,"items":["aN1","aN2"],"selectedIndex":0,"onValueChange":"@{aN}"},{"type":"SelectBox","width":"matchParent","height":36,"id":"sbDI","selectItemType":"Date","datePickerMode":"date","dateStringFormat":"yyyy-MM-dd","selectedDate":"@{dayI}","onValueChange":"@{dI}"}]}"#

    private var layout: DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8))
    }

    static let takesTheItem = ["pSi", "pSx", "pSn", "dS"]
    static let takesTheIndex = ["pIi", "pIx", "pIn", "aI", "dI"]
    static let takesTheItemNamed = ["pNi", "pNx", "pNn", "dN", "aN"]

    /// Each handler with the closure type the layout declares for it, logging
    /// what it is handed.
    private var dynamicData: [String: Any] {
        let l = log
        var out: [String: Any] = [:]
        for n in Self.takesTheItem { out[n] = { (item: String) -> Void in l.record("\(n)(\(item))") } }
        for n in Self.takesTheIndex { out[n] = { (id: String, index: Int) -> Void in l.record("\(n)(\(id),\(index))") } }
        for n in Self.takesTheItemNamed { out[n] = { (id: String, item: String) -> Void in l.record("\(n)(\(id),\(item))") } }
        out["selS"] = $dyn.selS
        out["selI"] = $dyn.selI
        out["selN"] = $dyn.selN
        out["idxS"] = $dyn.idxS
        out["idxI"] = $dyn.idxI
        out["idxN"] = $dyn.idxN
        out["dayS"] = $dyn.dayS
        out["dayN"] = $dyn.dayN
        out["dayI"] = $dyn.dayI
        return out
    }

    private func wire() {
        guard !wired else { return }
        wired = true
        let l = log
        data.pSi = { l.record("pSi(\($0))") }
        data.pSx = { l.record("pSx(\($0))") }
        data.pSn = { l.record("pSn(\($0))") }
        data.dS = { l.record("dS(\($0))") }
        data.pIi = { l.record("pIi(\($0),\($1))") }
        data.pIx = { l.record("pIx(\($0),\($1))") }
        data.pIn = { l.record("pIn(\($0),\($1))") }
        data.aI = { l.record("aI(\($0),\($1))") }
        data.dI = { l.record("dI(\($0),\($1))") }
        data.pNi = { l.record("pNi(\($0),\($1))") }
        data.pNx = { l.record("pNx(\($0),\($1))") }
        data.pNn = { l.record("pNn(\($0),\($1))") }
        data.dN = { l.record("dN(\($0),\($1))") }
        data.aN = { l.record("aN(\($0),\($1))") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ready").accessibilityIdentifier("pa_ready")
            Text("calls[" + log.calls.joined(separator: "|") + "]")
                .font(.system(size: 8)).lineLimit(1).accessibilityIdentifier("pa_readout")
            if path == "codegen" {
                PickArityCodegenPaste(data: $data)
            } else if let layout {
                DynamicView(component: layout, viewId: "pa", data: dynamicData)
            } else {
                Text("layout did not decode").accessibilityIdentifier("pa_decode_failed")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .onAppear { wire() }
    }
}
