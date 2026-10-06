//
//  IdBoxProbeView.swift
//  ConformanceHost
//
//  An element's id box is its layout box: inside the margin, including the
//  padding, moved by the offset (user ruling 2026-10-06, Android's result).
//  Until SwiftJsonUI 10.29.7 / jsonui-cli 1.9.18 two shapes missed it:
//    - a TextField's id sat on the inner field, inside the padding
//      (84 x 22 for a 100 x 40 field with padding 8; ticket ios-textfield-
//      id-box-excludes-its-padding);
//    - a container's id box was its 0.5pt accessibility anchor united with
//      its content, and the anchor sat before the offset, so the box began
//      at the margin (105 wide for a 100 wide View with offsetX 5; ticket
//      ios-container-id-box-starts-at-the-anchor-before-the-offset).
//  NOT part of the conformance suite; launch with `-idBoxProbe` (the Dynamic
//  half) or `-idBoxProbeCodegen` (the generated half). Its test
//  (IdBoxProbeUITests) is NOT opt-in.
//
//  Each type is the only child of a fixed 300 x 60 parent, with margins
//  (left 20, top 10), padding 8, offsetX 5, a fixed 100 x 40 size and a
//  background. The layout boxes are drawn as `frame:<id>` here, as the
//  fixture host draws them (jsonUIConformanceFrames).
//
//  The generated half: ProbeLayouts/probe_id_box.json.
//

import SwiftUI
import SwiftJsonUI

struct IdBoxProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_ib_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_ib_p_label", "width": 300, "height": 60, "child": [{"type": "Label", "text": "Label", "id": "dyn_ib_label", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_ib_p_button", "width": 300, "height": 60, "child": [{"type": "Button", "text": "Button", "id": "dyn_ib_button", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_ib_p_image", "width": 300, "height": 60, "child": [{"type": "Image", "srcName": "conformance_sample", "id": "dyn_ib_image", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_ib_p_textfield", "width": 300, "height": 60, "child": [{"type": "TextField", "hint": "Field", "id": "dyn_ib_textfield", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_ib_p_textview", "width": 300, "height": 60, "child": [{"type": "TextView", "hint": "Text", "id": "dyn_ib_textview", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_ib_p_view", "width": 300, "height": 60, "child": [{"type": "View", "orientation": "vertical", "id": "dyn_ib_view", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00", "child": [{"type": "Label", "text": "In"}]}]}, {"type": "View", "id": "dyn_ib_p_emptyview", "width": 300, "height": 60, "child": [{"type": "View", "id": "dyn_ib_emptyview", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00"}]}, {"type": "View", "id": "dyn_ib_p_scrollview", "width": 300, "height": 60, "child": [{"type": "ScrollView", "id": "dyn_ib_scrollview", "width": 100, "height": 40, "leftMargin": 20, "topMargin": 10, "padding": 8, "offsetX": 5, "background": "#FFDD00", "child": [{"type": "Label", "text": "In"}]}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "id box probe (codegen)" : "id box probe").accessibilityIdentifier("ib_ready")
            Group {
                if codegen {
                    if let generated = CodegenFixtureRegistry.probeView(named: "probe_id_box") {
                        generated
                    }
                } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                    DynamicComponentBuilder(component: component, data: [:])
                } else {
                    Text("did not decode").accessibilityIdentifier("ib_decode_failed")
                }
            }
            .jsonUIConformanceFrames()
            .environment(\.jsonuiConformanceFrameProbe, true)
            Spacer()
        }
        .padding(.horizontal)
    }
}
