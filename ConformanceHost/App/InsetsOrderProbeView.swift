//
//  InsetsOrderProbeView.swift
//  ConformanceHost
//
//  A Collection's `insets` is read as `paddings` reads them (the SSoT's
//  Collection.insets, jsonui-cli 1.9.0): 1, 2 or 4 values, an array or a
//  `|` string; one, every side; two, [vertical, horizontal]; four, [top,
//  right, bottom, left]; any other value pads nothing. Until jsonui-cli
//  1.9.0 sjui read four as [top, left, bottom, right] (`[0, 30, 0, 0]` put
//  the cells 30pt in, where Dynamic put them at the start), a value it could
//  not parse as 0, and on a horizontal row applied the horizontal sides
//  twice; and the Dynamic renderer padded the list, row and flow routes from
//  OUTSIDE the scroll, which shrank it (a 270pt scroll 30pt in) where the
//  SSoT and the codegen pad the content inside it. The List routes (a
//  sectioned Collection with a listStyle, and the class-list shape) and the
//  pager pad inside their scroll too, from jsonui-cli 1.9.0 / SwiftJsonUI
//  10.29.0 (`-insetsRoutesProbe`, ProbeLayouts/probe_insets_routes.json):
//  until then sjui's Lists read no insets, and Dynamic's Lists and both
//  pagers were padded from outside (a 270pt scroll). On the Dynamic renderer
//  and — in the codegen host — as sjui generates it. NOT part of the conformance suite; launch with
//  `-insetsOrderProbe` (the Dynamic half) or `-insetsOrderProbeCodegen`
//  (the generated half). Its test (InsetsOrderProbeUITests) is NOT opt-in.
//
//  Each Collection is 300 × 44 (a List 300 × 100) with 60 × 28 cells
//  (conformance_cell, i0 and i1), in a View of its size; the test reads where the first cell sits in
//  that View. The rows and their
//  expectations are in InsetsOrderProbeUITests.
//
//  The generated half: ProbeLayouts/probe_insets_order.json.
//

import SwiftUI
import SwiftJsonUI

struct InsetsOrderProbeView: View {
    let codegen: Bool
    var routes = false

    static let layout = ##"{"type": "View", "id": "dyn_io_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 6, "child": [{"type": "View", "id": "dyn_io_v_start30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_start30", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [0, 0, 0, 30]}]}, {"type": "View", "id": "dyn_io_v_end30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_end30", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [0, 30, 0, 0]}]}, {"type": "View", "id": "dyn_io_v_string_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_string", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": "0|0|0|30"}]}, {"type": "View", "id": "dyn_io_v_two_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_two", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [4, 20]}]}, {"type": "View", "id": "dyn_io_v_one_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_one", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [10]}]}, {"type": "View", "id": "dyn_io_v_unreadable_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_unreadable", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": "a|b"}]}, {"type": "View", "id": "dyn_io_v_three_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_three", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [1, 2, 3]}]}, {"type": "View", "id": "dyn_io_h_start30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_h_start30", "layout": "horizontal", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [0, 0, 0, 30]}]}, {"type": "View", "id": "dyn_io_h_end30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_h_end30", "layout": "horizontal", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [0, 30, 0, 0]}]}, {"type": "View", "id": "dyn_io_v_eager_start30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_v_eager_start30", "layout": "vertical", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [0, 0, 0, 30], "lazy": "eager"}]}, {"type": "View", "id": "dyn_io_flow_start30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_flow_start30", "layout": "flow", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "insets": [0, 0, 0, 30]}]}]}"##

    /// The List routes and the pager (`-insetsRoutesProbe`): a launch of
    /// their own, so the column stays within the screen.
    static let routesLayout = ##"{"type": "View", "id": "dyn_ir_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "spacing": 6, "child": [{"type": "View", "id": "dyn_io_list_none_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_list_none", "layout": "vertical", "width": 300, "height": 100, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "listStyle": "plain"}]}, {"type": "View", "id": "dyn_io_list_start30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_list_start30", "layout": "vertical", "width": 300, "height": 100, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "listStyle": "plain", "insets": [0, 0, 0, 30]}]}, {"type": "View", "id": "dyn_io_list_top10_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_list_top10", "layout": "vertical", "width": 300, "height": 100, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "listStyle": "plain", "insets": [10, 0, 0, 0]}]}, {"type": "View", "id": "dyn_io_listclass_none_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_listclass_none", "layout": "vertical", "width": 300, "height": 100, "background": "#CCE0FF", "items": "@{rows}", "cellClasses": ["conformance_cell"]}]}, {"type": "View", "id": "dyn_io_listclass_start30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_listclass_start30", "layout": "vertical", "width": 300, "height": 100, "background": "#CCE0FF", "items": "@{rows}", "cellClasses": ["conformance_cell"], "insets": [0, 0, 0, 30]}]}, {"type": "View", "id": "dyn_io_pager_start30_box", "orientation": "vertical", "width": 300, "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_io_pager_start30", "layout": "horizontal", "width": 300, "height": 44, "background": "#CCE0FF", "items": "@{rows}", "sections": [{"cell": "conformance_cell"}], "paging": true, "insets": [0, 0, 0, 30]}]}]}"##

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "insets order probe (codegen)" : "insets order probe").accessibilityIdentifier("io_ready")
            if codegen {
                if let generated = CodegenFixtureRegistry.probeView(named: routes ? "probe_insets_routes" : "probe_insets_order") {
                    generated
                }
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data((routes ? Self.routesLayout : Self.layout).utf8)) {
                DynamicComponentBuilder(component: component, data: ["rows": CollectionDataSource(sections: [
                    ScrollRuleProbeView.section(cells: [["title": "i0"], ["title": "i1"]])
                ])])
            } else {
                Text("did not decode").accessibilityIdentifier("io_decode_failed")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
