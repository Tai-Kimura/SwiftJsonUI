//
//  TextViewInsetProbeView.swift
//  ConformanceHost
//
//  Where a TextView's text starts, for `padding: 8` and for none, in Dynamic
//  and in codegen. A TextView's `padding` is its container inset: Dynamic
//  read it so, codegen dropped it until jsonui-cli 1.9.18 (its text sat at
//  the editor's default inset), and the inset beyond the editor's own went
//  outside the editor, shrinking its id box, until SwiftJsonUI 10.29.7
//  (ticket ios-a-textviews-id-box-shrinks-by-its-container-inset). NOT part
//  of the conformance suite; launch with `-textViewInsetProbe` (the Dynamic
//  half) or `-textViewInsetProbeCodegen` (the generated half). Its test
//  (TextViewInsetProbeUITests) is NOT opt-in.
//
//  The generated half: ProbeLayouts/probe_textview_inset.json.
//

import SwiftUI
import SwiftJsonUI

struct TextViewInsetProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_tvi_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_tvi_p_pad", "width": 300, "height": 80, "child": [{"type": "TextView", "id": "dyn_tvi_pad", "text": "WWW", "fontColor": "#000000", "fontSize": 16, "width": 120, "height": 60, "background": "#FFDD00", "padding": 8}]}, {"type": "View", "id": "dyn_tvi_p_nopad", "width": 300, "height": 80, "child": [{"type": "TextView", "id": "dyn_tvi_nopad", "text": "WWW", "fontColor": "#000000", "fontSize": 16, "width": 120, "height": 60, "background": "#FFDD00"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "textview inset probe (codegen)" : "textview inset probe").accessibilityIdentifier("tvi_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_textview_inset") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("tvi_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
