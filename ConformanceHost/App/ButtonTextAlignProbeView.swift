//
//  ButtonTextAlignProbeView.swift
//  ConformanceHost
//
//  A Button's text is placed across it by textAlign — Left at the start,
//  Right at the end, Center or none in the middle — and its gravity does not
//  move it sideways (the SSoT, 4f ruling 2026-09-27: textAlign owns a
//  Button's horizontal, default centre; a leaf's gravity positions its
//  content vertically only). Until SwiftJsonUI 10.29.0 / jsonui-cli 1.9.0
//  the text stood in the middle whatever textAlign said. On the Dynamic
//  renderer and — in the codegen host — as sjui generates it. NOT part of
//  the conformance suite; launch with `-buttonTextAlignProbe` (the Dynamic
//  half) or `-buttonTextAlignProbeCodegen` (the generated half). Its test
//  (ButtonTextAlignProbeUITests) is NOT opt-in.
//
//  Each row is a white View around one grey 44pt-tall Button with black
//  text "Go"; the test reads where the text's ink sits across the button.
//
//  The generated half: ProbeLayouts/probe_button_text_align.json.
//

import SwiftUI
import SwiftJsonUI

struct ButtonTextAlignProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_bt_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 6, "child": [{"type": "View", "id": "dyn_bt_w200_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"id": "dyn_bt_w200_left_button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "type": "Button", "width": 200, "textAlign": "Left"}]}, {"type": "View", "id": "dyn_bt_w200_right", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"id": "dyn_bt_w200_right_button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "type": "Button", "width": 200, "textAlign": "Right"}]}, {"type": "View", "id": "dyn_bt_mw_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"id": "dyn_bt_mw_left_button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "type": "Button", "width": "matchParent", "textAlign": "Left"}]}, {"type": "View", "id": "dyn_bt_mw_right", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"id": "dyn_bt_mw_right_button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "type": "Button", "width": "matchParent", "textAlign": "Right"}]}, {"type": "View", "id": "dyn_bt_w200_center", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"id": "dyn_bt_w200_center_button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "type": "Button", "width": 200, "textAlign": "Center"}]}, {"type": "View", "id": "dyn_bt_w200_none", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"id": "dyn_bt_w200_none_button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "type": "Button", "width": 200}]}, {"type": "View", "id": "dyn_bt_w200_gravity_left", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "background": "#FFFFFF", "child": [{"id": "dyn_bt_w200_gravity_left_button", "text": "Go", "fontColor": "#000000", "background": "#DDDDDD", "height": 44, "type": "Button", "width": 200, "gravity": "left"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "button text align probe (codegen)" : "button text align probe").accessibilityIdentifier("bt_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: "probe_button_text_align") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("bt_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
