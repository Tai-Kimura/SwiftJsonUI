//
//  CellDataRefreshCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of CellDataRefreshProbeView: the two Collections as sjui
//  generates them (ProbeLayouts/probe_cell_data_refresh.json →
//  ProbeCellDataRefreshGeneratedView), their cells the ConformanceCellView
//  sjui build scaffolds, with this view holding the generated view's data as
//  an app's ViewModel does. Compiled only in the codegen host.
//

import SwiftUI
import SwiftJsonUI

struct CellDataRefreshCodegenHalf: View {
    let version: Int
    @State private var data = ProbeCellDataRefreshData()

    private func load(_ version: Int) {
        data.rows_cellid = CellDataRefreshProbeView.rows(prefix: "A", keyName: "cellId", version: version)
        data.rows_key = CellDataRefreshProbeView.rows(prefix: "K", keyName: "key", version: version)
        data.rows_tracked = CellDataRefreshProbeView.rows(prefix: "T", keyName: "cellId", version: version)
        data.rows_none = CellDataRefreshProbeView.rows(prefix: "N", keyName: nil, version: version)
    }

    var body: some View {
        ProbeCellDataRefreshGeneratedView(data: $data)
            .onAppear { load(version) }
            .onChange(of: version) { _, new in load(new) }
    }
}
