//
//  CellIdBoxProbeView.swift
//  ConformanceHost
//
//  A Collection cell's boxes: the item address `{collectionId}_item_0` and,
//  where the cell root declares one, the root's own id, against what the
//  cell draws. The cells are jsonui-cli's conformance_cell_inset_bare_single
//  (no root id) and conformance_cell_inset_single (root id cell_inset_root):
//  one child Label, a fixed 100 x 40 size, leftMargin 20, topMargin 10,
//  padding 8, offsetX 5 and a background (fixtures Collection/cellIdBox__*,
//  which put them in the host's Layouts). The single-child merge anchor sat
//  outside a cell root's offset and margins in codegen, and the Dynamic
//  wrapper has none (ticket ios-container-id-box-starts-at-the-anchor-
//  before-the-offset, family section). NOT part of the conformance suite;
//  launch with `-cellIdBoxProbe` (the Dynamic half) or
//  `-cellIdBoxProbeCodegen` (the generated half). Its test
//  (CellIdBoxProbeUITests) is NOT opt-in.
//
//  The generated half: ProbeLayouts/probe_cell_id_box.json.
//

import SwiftUI
import SwiftJsonUI

struct CellIdBoxProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_cib_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "View", "id": "dyn_cib_p_bare", "width": 300, "height": 80, "child": [{"type": "Collection", "id": "dyn_cib_bare", "width": 200, "height": 70, "layout": "flow", "sections": [{"cell": "conformance_cell_inset_bare_single"}], "items": "@{one}"}]}, {"type": "View", "id": "dyn_cib_p_id", "width": 300, "height": 80, "child": [{"type": "Collection", "id": "dyn_cib_id", "width": 200, "height": 70, "layout": "flow", "sections": [{"cell": "conformance_cell_inset_single"}], "items": "@{one}"}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "cell id box probe (codegen)" : "cell id box probe").accessibilityIdentifier("cib_ready")
            Group {
                if codegen {
                    if let generated = CodegenFixtureRegistry.probeView(named: "probe_cell_id_box") {
                        generated
                    }
                } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                    DynamicComponentBuilder(component: component, data: [
                        "one": CollectionDataSource(sections: [ScrollRuleProbeView.section(cells: [["title": "c0"]])])
                    ])
                } else {
                    Text("did not decode").accessibilityIdentifier("cib_decode_failed")
                }
            }
            .jsonUIConformanceFrames()
            .environment(\.jsonuiConformanceFrameProbe, true)
            Spacer()
        }
        .padding(.horizontal)
    }
}
