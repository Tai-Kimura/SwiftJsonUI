//
//  PaddingsOrderProbeView.swift
//  ConformanceHost
//
//  A four-value `paddings` is [top, right, bottom, left] (the SSoT's
//  common.paddings). A wrapContent View with paddings [0, 40, 0, 4] holds a
//  20x20 child: the child sits 4 from the View's leading edge and 40 from its
//  trailing edge; one with [6, 0, 30, 0] sits 6 from the top. A width cannot
//  tell the two readings apart, so PaddingsOrderProbeUITests reads the
//  child's POSITION. Until jsonui-cli 1.9.14 sjui read [top, left, bottom,
//  right] (jsonui-cli ticket sjui-four-value-paddings-read-as-top-left-bottom-right).
//  On the Dynamic renderer and — in the codegen host — as sjui generates it
//  (ProbeLayouts/probe_paddings_order.json; PaddingsOrderCodegenHalf).
//  The UITest sets its own launch argument (`-paddingsOrderProbe` /
//  `-paddingsOrderProbeCodegen`).
//

import SwiftUI
import SwiftJsonUI

struct PaddingsOrderProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_po_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_po_lr", "width": "wrapContent", "height": "wrapContent", "background": "#DDDDDD", "paddings": [0, 40, 0, 4], "child": [{"type": "View", "id": "dyn_po_lr_child", "width": 20, "height": 20, "background": "#3366CC"}]}, {"type": "View", "id": "dyn_po_tb", "width": "wrapContent", "height": "wrapContent", "background": "#DDDDDD", "paddings": [6, 0, 30, 0], "child": [{"type": "View", "id": "dyn_po_tb_child", "width": 20, "height": 20, "background": "#3366CC"}]}], "spacing": 8}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "paddings order probe (codegen)" : "paddings order probe").accessibilityIdentifier("po_ready")
            if codegen {
                PaddingsOrderCodegenHalf()
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [:])
            } else {
                Text("did not decode").accessibilityIdentifier("po_decode_failed")
            }
            Spacer()
        }
    }
}
