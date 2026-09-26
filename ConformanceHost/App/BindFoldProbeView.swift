//
//  BindFoldProbeView.swift
//  ConformanceHost
//
//  `bind` folded on the node drawn (jsonui-cli 1.9.0, bind (B)): a Date
//  SelectBox's lone `bind` is its selectedDate; a CheckBox's `bind` beside a
//  literal `isOn: false` is dropped (the literal is the value); a CheckBox's
//  lone `bind` is its isOn. NOT part of the conformance suite. Launch with
//  `-bindFoldProbe` and `-bfPath <dynamic|codegen>`: DynamicView over the
//  layout below, or what sjui build (jsonui-cli rel/v1.8.121 b0937f2f) emits
//  for it, pasted unchanged.
//
//  The readout is the data the layout binds: `day`, and `on` — which only a
//  CheckBox bound to it writes when tapped.
//

import SwiftUI
import SwiftJsonUI

struct BindFoldProbeData {
    var day: String = "2026-01-02"
    var on: Bool = true
}

struct BindFoldProbeView: View {
    /// The codegen path's data (the emission reads `data.day`, `$data.on`).
    @State private var data = BindFoldProbeData()
    /// The dynamic path's bound values.
    @State private var dyn = BindFoldProbeData()
    /// The state the emission names for the literal CheckBox.
    @State private var bfCheckIsOn = false
    private let path = OnClickProbeView.arg("-bfPath", "dynamic")

    static let layout = ##"{"type":"View","orientation":"vertical","spacing":12,"width":"matchParent","data":[{"name":"day","class":"String","defaultValue":"2026-01-02"},{"name":"on","class":"Bool","defaultValue":true}],"child":[{"type":"SelectBox","id":"bfDate","width":220,"height":44,"selectItemType":"Date","datePickerMode":"date","dateStringFormat":"yyyy-MM-dd","bind":"@{day}"},{"type":"CheckBox","id":"bfCheck","label":"literal","isOn":false,"bind":"@{on}"},{"type":"CheckBox","id":"bfCheckLone","label":"lone","bind":"@{on}"}]}"##

    private var readout: String {
        let d = path == "codegen" ? data : dyn
        return "day=\(d.day),on=\(d.on)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("bind fold probe \(path)").accessibilityIdentifier("bf_ready")
            Text(readout).accessibilityIdentifier("bf_readout")
            if path == "codegen" {
                VStack(alignment: .leading, spacing: 12) {
                        SelectBoxView(
                            id: "bfDate",
                            selectItemType: .date,
                            datePickerMode: .date,
                            dateStringFormat: "yyyy-MM-dd",
                            selectedDate: data.day.toDate(format: "yyyy-MM-dd"),
                            onValueChange: { newValue in
                                data.day = newValue
                            }
                        )
                            .frame(width: 220, height: 44)
                            .accessibilityIdentifier("bfDate")
                        CheckBoxView(
                            isOn: $bfCheckIsOn,
                            label: "literal",
                        )
                            .accessibilityIdentifier("bfCheck")
                        CheckBoxView(
                            isOn: $data.on,
                            label: "lone",
                        )
                            .accessibilityIdentifier("bfCheckLone")
                }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else if let layout = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicView(component: layout, viewId: "bf", data: ["day": $dyn.day, "on": $dyn.on])
            } else {
                Text("decode failed").accessibilityIdentifier("bf_decode_failed")
            }
            Spacer(minLength: 0)
        }
    }
}
