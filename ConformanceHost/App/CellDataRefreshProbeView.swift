//
//  CellDataRefreshProbeView.swift
//  ConformanceHost
//
//  A cell whose key stays fixed while its data changes shows the new data.
//  Two Collections of three cells, neither with autoChangeTrackingId:
//  cellIdProperty "cellId" (keys a0…a2 under "cellId") and cellIdProperty
//  "key" (keys k0…k2, no "cellId" in the data). "bump" rewrites every
//  cell's title ("A0 v1", …) and keeps every key. Android redraws the cells;
//  iOS's generated cell scaffold is Equatable on its "cellId" and its view
//  model sets data only when that key changes, so a fixed "cellId" kept the
//  old title (jsonui-cli ticket ios-cell-ignores-data-change-when-cellid-is-
//  fixed-android-updates: 0 of 8 on a consumer's tabs). The "key" list is
//  the control: no "cellId" in the data, so the scaffold's key is the whole
//  value and changes with it. A third, cellIdProperty "cellId" with
//  autoChangeTrackingId (keys t0…t2), reads the enriched route, whose data
//  already carries a content-derived "cellId". CellDataRefreshProbeUITests taps bump and reads
//  the titles. On the Dynamic renderer and — in the codegen host — as sjui
//  generates it (ProbeLayouts/probe_cell_data_refresh.json;
//  CellDataRefreshCodegenHalf, compiled only in the codegen host). NOT part
//  of the conformance suite; launch with `-cellDataRefreshProbe` or
//  `-cellDataRefreshProbeCodegen`.
//

import SwiftUI
import SwiftJsonUI

struct CellDataRefreshProbeView: View {
    let codegen: Bool

    static let layout = ##"{"type": "View", "id": "dyn_cdr_root", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "Collection", "id": "dyn_cdr_cellid", "layout": "vertical", "width": "matchParent", "height": 150, "items": "@{rows_cellid}", "cellIdProperty": "cellId", "sections": [{"cell": "conformance_cell"}]}, {"type": "Collection", "id": "dyn_cdr_key", "layout": "vertical", "width": "matchParent", "height": 150, "items": "@{rows_key}", "cellIdProperty": "key", "sections": [{"cell": "conformance_cell"}]}, {"type": "Collection", "id": "dyn_cdr_tracked", "layout": "vertical", "width": "matchParent", "height": 150, "items": "@{rows_tracked}", "cellIdProperty": "cellId", "sections": [{"cell": "conformance_cell"}], "autoChangeTrackingId": true}], "data": [{"name": "rows_cellid", "class": "CollectionDataSource", "defaultValue": {"sections": [{"cells": []}]}}, {"name": "rows_key", "class": "CollectionDataSource", "defaultValue": {"sections": [{"cells": []}]}}, {"name": "rows_tracked", "class": "CollectionDataSource", "defaultValue": {"sections": [{"cells": []}]}}]}"##

    @State private var version = 0

    /// Three cells; the keys never change, the titles carry `version`.
    static func rows(prefix: String, keyName: String, version: Int) -> CollectionDataSource {
        let cells: [[String: Any]] = (0..<3).map { i in
            [keyName: "\(prefix.lowercased())\(i)", "title": "\(prefix)\(i) v\(version)"]
        }
        var section = CollectionDataSection()
        section.setCells(viewName: "conformance_cell", data: cells)
        return CollectionDataSource(sections: [section])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(codegen ? "cell data refresh probe (codegen)" : "cell data refresh probe").accessibilityIdentifier("cdr_ready")
            Button("bump") { version += 1 }.accessibilityIdentifier("cdr_bump")
            Text("version \(version)").accessibilityIdentifier("cdr_version")
            if codegen {
                // CodegenOnly/ in the codegen host; a stub in the dynamic-only one.
                CellDataRefreshCodegenHalf(version: version)
            } else if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(Self.layout.utf8)) {
                DynamicComponentBuilder(component: component, data: [
                    "rows_cellid": Self.rows(prefix: "A", keyName: "cellId", version: version),
                    "rows_key": Self.rows(prefix: "K", keyName: "key", version: version),
                    "rows_tracked": Self.rows(prefix: "T", keyName: "cellId", version: version)
                ])
            } else {
                Text("did not decode").accessibilityIdentifier("cdr_decode_failed")
            }
            Spacer()
        }
    }
}
