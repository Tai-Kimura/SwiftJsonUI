//
//  TapArityProbeView.swift
//  ConformanceHost
//
//  A handler that takes no value — a tap (onClick, the onclick selector), a
//  control's onClick from its operation, a Button's, a long press, onAppear,
//  onDisappear — called as its declared closure type asks (4f's ruling on
//  control-onclick-is-called-differently-on-every-path, 1.9.0): `()` with no
//  argument, `(String)` with the viewId (the id, else the drawn type and the
//  position: `view_0_0`, `image_0_2`, …). Every node here is id-less, its
//  handler declared `(String)`; one View's `()` beside them. NOT part of the
//  conformance suite. Launch with `-tapArityProbe` and `-taPath
//  <dynamic|codegen>`: DynamicView over the layout, or what sjui build emits
//  for it (TapArityCodegenPaste). `ta_hide` hides the last row (onDisappear).
//

import SwiftUI
import SwiftJsonUI

final class TapArityLog: ObservableObject {
    /// One log for the process: the codegen path's handlers are wired when
    /// its data is made, before any onAppear can run.
    static let shared = TapArityLog()
    @Published var calls: [String] = []
    func record(_ call: String) { calls.append(call) }
}

struct TapArityProbeView: View {
    @ObservedObject private var log = TapArityLog.shared
    @State private var data = TapArityProbeView.wired()
    @State private var shown = "visible"
    private let path = OnClickProbeView.arg("-taPath", "dynamic")

    static let layout = ##"{"type":"View","orientation":"vertical","spacing":4,"width":"matchParent","data":[{"name":"tS","class":"((String) -> Void)?"},{"name":"iS","class":"((String) -> Void)?"},{"name":"lS","class":"((String) -> Void)?"},{"name":"sS","class":"((String) -> Void)?"},{"name":"bS","class":"((String) -> Void)?"},{"name":"wS","class":"((String) -> Void)?"},{"name":"pS","class":"((String) -> Void)?"},{"name":"aS","class":"((String) -> Void)?"},{"name":"dS","class":"((String) -> Void)?"},{"name":"t0","class":"(() -> Void)?"},{"name":"shown","class":"String","defaultValue":"visible"},{"name":"txt0","class":"String","defaultValue":"tap tS"},{"name":"txt1","class":"String","defaultValue":"tap t0"},{"name":"txt2","class":"String","defaultValue":"img iS"},{"name":"txt3","class":"String","defaultValue":"tap lS"},{"name":"txt4","class":"String","defaultValue":"tap sS"},{"name":"txt5","class":"String","defaultValue":"tap bS"},{"name":"txt6","class":"String","defaultValue":"press pS"},{"name":"txt7","class":"String","defaultValue":"appear aS"},{"name":"txt8","class":"String","defaultValue":"gone dS"}],"child":[{"type":"View","width":"matchParent","height":34,"background":"#E4E4E4","child":[{"type":"Label","text":"@{txt0}","fontSize":12}],"onClick":"@{tS}"},{"type":"View","width":"matchParent","height":34,"background":"#E4E4E4","child":[{"type":"Label","text":"@{txt1}","fontSize":12}],"onClick":"@{t0}"},{"type":"Image","srcName":"probe_none","width":60,"height":30,"background":"#C8C8FF","alt":"@{txt2}","onClick":"@{iS}"},{"type":"Label","text":"@{txt3}","fontSize":12,"height":30,"onClick":"@{lS}"},{"type":"View","width":"matchParent","height":34,"background":"#E4E4E4","child":[{"type":"Label","text":"@{txt4}","fontSize":12}],"onclick":"sS"},{"type":"Button","text":"@{txt5}","height":34,"onClick":"@{bS}"},{"type":"Switch","isOn":false,"onClick":"@{wS}"},{"type":"View","width":"matchParent","height":34,"background":"#E4E4E4","child":[{"type":"Label","text":"@{txt6}","fontSize":12}],"onLongPress":"@{pS}"},{"type":"View","width":"matchParent","height":34,"background":"#E4E4E4","child":[{"type":"Label","text":"@{txt7}","fontSize":12}],"onAppear":"aS"},{"type":"View","width":"matchParent","height":34,"background":"#E4E4E4","child":[{"type":"Label","text":"@{txt8}","fontSize":12}],"onDisappear":"dS","visibility":"@{shown}"}]}"##

    private var layout: DynamicComponent? {
        try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8))
    }

    /// The words the layout binds its texts to (seeded by `defaultValue`).
    static let texts: [String: String] = ["txt0": "tap tS", "txt1": "tap t0", "txt2": "img iS", "txt3": "tap lS", "txt4": "tap sS", "txt5": "tap bS", "txt6": "press pS", "txt7": "appear aS", "txt8": "gone dS"]

    static let takesTheViewId = ["tS", "iS", "lS", "sS", "bS", "wS", "pS", "aS", "dS"]

    private var dynamicData: [String: Any] {
        let l = log
        var out: [String: Any] = [:]
        for n in Self.takesTheViewId { out[n] = { (id: String) -> Void in l.record("\(n)(\(id))") } }
        out["t0"] = { () -> Void in l.record("t0()") }
        out["shown"] = shown
        for (key, words) in Self.texts { out[key] = words }
        return out
    }

    private static func wired() -> TapArityData {
        var data = TapArityData()
        let l = TapArityLog.shared
        data.tS = { l.record("tS(\($0))") }
        data.iS = { l.record("iS(\($0))") }
        data.lS = { l.record("lS(\($0))") }
        data.sS = { l.record("sS(\($0))") }
        data.bS = { l.record("bS(\($0))") }
        data.wS = { l.record("wS(\($0))") }
        data.pS = { l.record("pS(\($0))") }
        data.aS = { l.record("aS(\($0))") }
        data.dS = { l.record("dS(\($0))") }
        data.t0 = { l.record("t0()") }
        return data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ready").accessibilityIdentifier("ta_ready")
            Text("calls[" + log.calls.joined(separator: "|") + "]")
                .font(.system(size: 8)).lineLimit(1).accessibilityIdentifier("ta_readout")
            Button("hide the last row") {
                shown = "gone"
                data.shown = "gone"
            }.font(.system(size: 12)).accessibilityIdentifier("ta_hide")
            if path == "codegen" {
                TapArityCodegenPaste(data: $data)
            } else if let layout {
                DynamicView(component: layout, viewId: "ta", data: dynamicData)
            } else {
                Text("layout did not decode").accessibilityIdentifier("ta_decode_failed")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
    }
}
