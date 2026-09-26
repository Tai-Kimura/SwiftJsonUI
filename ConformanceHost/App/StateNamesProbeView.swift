//
//  StateNamesProbeView.swift
//  ConformanceHost
//
//  Do two stateful controls with no id keep a state each? (ticket
//  sjui-codegen-state-declarations-collide-by-name: sjui build named an id-less
//  control's view-local state by its kind alone, so two of a kind shared one
//  state or did not compile; an id-less single Radio's value was "radio" on
//  both paths, so every id-less Radio of a group was the same option.) NOT
//  part of the conformance suite. Launch with `-stateNamesProbe
//  <dynamic|codegen>`: DynamicView over the layout (decoded through
//  JSONLayoutLoader.decodeComponent, the loader's own entry), or what sjui
//  build emits for it (StateNamesCodegenPaste).
//

import SwiftUI
import SwiftJsonUI

struct StateNamesProbeView: View {
    private let path = OnClickProbeView.arg("-stateNamesProbe", "dynamic")
    @State private var data = StateNamesData()

    static let layout = #"{"type":"View","orientation":"vertical","spacing":6,"width":"matchParent","child":[{"type":"Switch","isOn":false},{"type":"Switch","isOn":false},{"type":"CheckBox","label":"c1","isOn":false},{"type":"CheckBox","label":"c2","isOn":false},{"type":"Segment","items":["a1","a2"],"selectedIndex":0},{"type":"Segment","items":["b1","b2"],"selectedIndex":0},{"type":"Slider","value":0.2},{"type":"Slider","value":0.2},{"type":"TextField","height":36,"text":"t"},{"type":"TextField","height":36,"text":"t"},{"type":"Radio","group":"h","text":"h1"},{"type":"Radio","group":"h","text":"h2"},{"type":"Radio","items":["i1","i2"],"selectedValue":"i1"},{"type":"Radio","items":["j1","j2"],"selectedValue":"j1"},{"type":"Radio","group":"g","text":"g1","checked":true},{"type":"Radio","group":"g","text":"g2"}]}"#

    private var component: DynamicComponent? {
        guard let json = try? JSONSerialization.jsonObject(with: Data(Self.layout.utf8)) as? [String: Any] else { return nil }
        return JSONLayoutLoader.decodeComponent(from: json)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ready").accessibilityIdentifier("sn_ready")
            if path == "codegen" {
                StateNamesCodegenPaste(data: $data)
            } else if let component {
                DynamicView(component: component, viewId: "sn", data: [:])
            } else {
                Text("layout did not decode").accessibilityIdentifier("sn_decode_failed")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
    }
}
