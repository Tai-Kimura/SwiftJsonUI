//
//  PaddingsOrderCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of PaddingsOrderProbeView: the two padded Views as sjui
//  generates them (ProbeLayouts/probe_paddings_order.json →
//  ProbePaddingsOrderGeneratedView). Compiled only in the codegen host.
//

import SwiftUI
import SwiftJsonUI

struct PaddingsOrderCodegenHalf: View {
    @State private var data = ProbePaddingsOrderData()

    var body: some View {
        ProbePaddingsOrderGeneratedView(data: $data)
    }
}
