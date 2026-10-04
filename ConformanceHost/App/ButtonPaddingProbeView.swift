//
//  ButtonPaddingProbeView.swift
//  ConformanceHost
//
//  A Button's padding is its content padding: a wrapContent Button grows by
//  it, around the same label. Six Buttons titled "Go": a control with none,
//  paddingLeft / paddingRight 22, padding 10, paddingStart / paddingEnd 5 / 6,
//  topPadding 3 with paddingBottom 4, and paddings [1, 2, 3, 4] ([top, right,
//  bottom, left]). ButtonPaddingProbeUITests reads each frame against the
//  control's. Until jsonui-cli 1.9.14 sjui emitted no padding for
//  paddingLeft / paddingRight alone (a consumer's label ran to its border —
//  jsonui-cli ticket sjui-button-drops-padding-left-right), nor for padding,
//  paddingStart / paddingEnd or topPadding. On the Dynamic renderer and — in
//  the codegen host — as sjui generates it (ProbeLayouts/probe_button_padding.json;
//  ButtonPaddingCodegenHalf, compiled only in the codegen host). NOT part of
//  the conformance suite's fixtures; the UITest sets its own launch argument
//  (`-buttonPaddingProbe` / `-buttonPaddingProbeCodegen`).
//

import SwiftUI
import SwiftJsonUI

struct ButtonPaddingProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_bp_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "Button", "id": "dyn_bp_ctl", "width": "wrapContent", "height": "wrapContent", "text": "Go", "fontSize": 16, "background": "#DDDDDD", "topMargin": 6}, {"type": "Button", "id": "dyn_bp_lr", "width": "wrapContent", "height": "wrapContent", "text": "Go", "fontSize": 16, "background": "#DDDDDD", "topMargin": 6, "paddingLeft": 22, "paddingRight": 22}, {"type": "Button", "id": "dyn_bp_uni", "width": "wrapContent", "height": "wrapContent", "text": "Go", "fontSize": 16, "background": "#DDDDDD", "topMargin": 6, "padding": 10}, {"type": "Button", "id": "dyn_bp_se", "width": "wrapContent", "height": "wrapContent", "text": "Go", "fontSize": 16, "background": "#DDDDDD", "topMargin": 6, "paddingStart": 5, "paddingEnd": 6}, {"type": "Button", "id": "dyn_bp_tb", "width": "wrapContent", "height": "wrapContent", "text": "Go", "fontSize": 16, "background": "#DDDDDD", "topMargin": 6, "topPadding": 3, "paddingBottom": 4}, {"type": "Button", "id": "dyn_bp_p4", "width": "wrapContent", "height": "wrapContent", "text": "Go", "fontSize": 16, "background": "#DDDDDD", "topMargin": 6, "paddings": [1, 2, 3, 4]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "button padding probe (codegen)" : "button padding probe").accessibilityIdentifier("bp_ready")
            if codegen {
                // CodegenOnly/ in the codegen host; a stub in the dynamic-only one.
                ButtonPaddingCodegenHalf()
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("bp_decode_failed")
            }
            Spacer()
        }
    }
}
