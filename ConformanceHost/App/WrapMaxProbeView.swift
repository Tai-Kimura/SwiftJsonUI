//
//  WrapMaxProbeView.swift
//  ConformanceHost
//
//  A wrapContent axis with a max sizes to its content, capped by the max
//  (the user's ruling, 2026-09-27). `.frame(maxWidth:)` takes the width it is
//  offered up to the max, so until SwiftJsonUI 10.29.0 / jsonui-cli 1.9.0 a
//  wrapContent chip with maxWidth 160 and the text "chip" was 160 wide on iOS
//  where Compose drew 57dp and the web 58.4px. On the Dynamic renderer and —
//  in the codegen host — as sjui generates it. NOT part of the conformance
//  suite; launch with `-wrapMaxProbe` (the Dynamic half) or
//  `-wrapMaxProbeCodegen` (the generated half). Its test (WrapMaxProbeUITests)
//  is NOT opt-in.
//
//  In a 520pt-tall column:
//  - `*_wm_chip`: "chip", wrapContent, maxWidth 160, minHeight 36, paddings
//    [5, 16], 13pt medium — its text's width. It was 160.
//  - `*_wm_long`: a long text, wrapContent, maxWidth 160 — 160 wide, wrapped
//    onto several lines (the control a fixedSize would break).
//  - `*_wm_box`: a 200-wide View of wrapContent height, maxHeight 300, one
//    label — its label's height. It took the height it was offered.
//  - control `*_wm_fill`: matchParent, maxWidth 160 — 160, as before.
//
//  The generated half: ProbeLayouts/probe_wrap_max.json.
//

import SwiftUI
import SwiftJsonUI

struct WrapMaxProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_wm_root", "orientation": "vertical", "width": "matchParent", "height": 520, "spacing": 8, "child": [{"type": "Label", "id": "dyn_wm_chip", "text": "chip", "width": "wrapContent", "maxWidth": 160, "minHeight": 36, "paddings": [5, 16], "fontSize": 13, "font": "medium", "background": "#CCE0FF", "fontColor": "#000000"}, {"type": "Label", "id": "dyn_wm_long", "text": "a longer label that has to wrap at the max width it declares", "width": "wrapContent", "maxWidth": 160, "fontSize": 13, "background": "#CCE0FF", "fontColor": "#000000"}, {"type": "View", "id": "dyn_wm_box", "orientation": "vertical", "width": 200, "maxHeight": 300, "background": "#CCE0FF", "child": [{"type": "Label", "id": "dyn_wm_box_label", "text": "in a box", "fontColor": "#000000"}]}, {"type": "Label", "id": "dyn_wm_fill", "text": "chip", "width": "matchParent", "maxWidth": 160, "background": "#CCE0FF", "fontColor": "#000000"}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "wrap max probe (codegen)" : "wrap max probe").accessibilityIdentifier("wm_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_wrap_max") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("wm_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
