//
//  ScrollHeightProbeView.swift
//  ConformanceHost
//
//  A horizontal ScrollView of height wrapContent in a vertical ScrollView is as
//  tall as its content (a row of three 28pt boxes), as KotlinJsonUI's
//  horizontalScroll row is. Its view (AdvancedKeyboardAvoidingScrollView) is a
//  GeometryReader around the ScrollView, framing a horizontal one at the
//  reader's height — and in a vertical ScrollView the reader is offered no
//  height (jsonui-cli ticket 2026-10-23-sjui-geometryreader-in-vertical-scroll-collapses,
//  found in the paging Collection's family). ScrollHeightProbeUITests reads the
//  frames. On the Dynamic renderer and — in the codegen host — as sjui
//  generates it (ProbeLayouts/probe_scroll_height.json; ScrollHeightCodegenHalf).
//  NOT part of the conformance suite; launch with `-scrollHeightProbe` or
//  `-scrollHeightProbeCodegen`.
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct ScrollHeightProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_sh_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "ScrollView", "id": "dyn_sh_scroll", "orientation": "vertical", "width": "matchParent", "height": 420, "child": [{"type": "View", "id": "dyn_sh_content", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "Label", "id": "dyn_sh_head", "text": "head", "fontSize": 14}, {"type": "ScrollView", "id": "dyn_sh_row", "orientation": "horizontal", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_sh_rowcontent", "orientation": "horizontal", "width": "wrapContent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_sh_box0", "width": 100, "height": 28, "background": "#3366CC"}, {"type": "View", "id": "dyn_sh_box1", "width": 100, "height": 28, "background": "#3366CC"}, {"type": "View", "id": "dyn_sh_box2", "width": 100, "height": 28, "background": "#3366CC"}]}]}, {"type": "Label", "id": "dyn_sh_foot", "text": "foot", "fontSize": 14}]}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "scroll height probe (codegen)" : "scroll height probe").accessibilityIdentifier("sh_ready")
            if codegen {
                ScrollHeightCodegenHalf()
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("sh_decode_failed")
            }
            Spacer()
        }
    }
}
#endif
