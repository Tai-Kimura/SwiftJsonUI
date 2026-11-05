//
//  LabelHeightProbeView.swift
//  ConformanceHost
//
//  A Label of height wrapContent keeps all its lines: a stack divides a finite
//  height among its children, and a child whose text needs more than its share
//  shrank with room left on the screen (jsonui-cli ticket
//  sjui-label-matchparent-wrapcontent-truncates-in-scroll). Under a node that
//  bounds the height the text stays inside it, and `lines` limits it, as
//  before. LabelHeightProbeUITests reads the frames. On the Dynamic renderer
//  and — in the codegen host — as sjui generates it
//  (ProbeLayouts/probe_label_height.json; LabelHeightCodegenHalf).
//  NOT part of the conformance suite; launch with `-labelHeightProbe` or
//  `-labelHeightProbeCodegen`.
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct LabelHeightProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "SafeAreaView", "id": "dyn_lh_root", "width": "matchParent", "height": "matchParent", "orientation": "vertical", "child": [{"type": "ScrollView", "id": "dyn_lh_scroll", "width": "matchParent", "weight": 1, "orientation": "vertical", "child": [{"type": "View", "id": "dyn_lh_page", "width": "matchParent", "height": "wrapContent", "orientation": "vertical", "child": [{"type": "View", "width": "matchParent", "height": 120, "background": "#CCCCCC"}, {"type": "View", "id": "dyn_lh_content", "width": "matchParent", "height": "wrapContent", "orientation": "vertical", "gravity": "center", "leftMargin": 24, "rightMargin": 24, "topMargin": 16, "child": [{"type": "Label", "id": "dyn_lh_title", "width": "wrapContent", "height": "wrapContent", "text": "Title", "fontSize": 24, "textAlign": "center"}, {"type": "Label", "id": "dyn_lh_text", "width": "matchParent", "height": "wrapContent", "text": "Would you like to continue (outside the listed regions, the rules of the place you live in apply)? Would you like to continue (outside the listed regions, the rules of the place you live in apply)?", "fontSize": 15, "textAlign": "center", "topMargin": 8}, {"type": "View", "id": "dyn_lh_question_box", "width": "matchParent", "height": "wrapContent", "orientation": "vertical", "topMargin": 16, "child": [{"type": "Label", "id": "dyn_lh_question", "width": "matchParent", "height": "wrapContent", "text": "Would you like to continue (outside the listed regions, the rules of the place you live in apply)?", "fontSize": 18, "textAlign": "center", "font": "bold"}, {"type": "View", "width": "matchParent", "height": 56, "background": "#CCCCCC", "topMargin": 16}]}, {"type": "Label", "id": "dyn_lh_margined", "width": "matchParent", "height": "wrapContent", "text": "Would you like to continue (outside the listed regions, the rules of the place you live in apply)? Would you like to continue (outside the listed regions, the rules of the place you live in apply)?", "fontSize": 16, "textAlign": "center", "topMargin": 32}, {"type": "View", "id": "dyn_lh_box", "width": 200, "height": 44, "topMargin": 16, "background": "#FFCC66", "child": [{"type": "Label", "id": "dyn_lh_boxed", "width": "wrapContent", "height": "wrapContent", "text": "Would you like to continue (outside the listed regions, the rules of the place you live in apply)? Would you like to continue (outside the listed regions, the rules of the place you live in apply)? Would you like to continue (outside the listed regions, the rules of the place you live in apply)?", "fontSize": 16, "textAlign": "center"}]}, {"type": "Label", "id": "dyn_lh_one_line", "width": "matchParent", "height": "wrapContent", "text": "Would you like to continue (outside the listed regions, the rules of the place you live in apply)? Would you like to continue (outside the listed regions, the rules of the place you live in apply)? Would you like to continue (outside the listed regions, the rules of the place you live in apply)?", "fontSize": 16, "textAlign": "center", "lines": 1, "topMargin": 16}]}]}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(codegen ? "label height probe (codegen)" : "label height probe").accessibilityIdentifier("lh_ready")
            if codegen {
                LabelHeightCodegenHalf()
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("lh_decode_failed")
            }
        }
    }
}
#endif
