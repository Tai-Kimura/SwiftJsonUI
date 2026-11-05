//
//  LabelHeightCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of LabelHeightProbeView: ProbeLayouts/probe_label_height.json
//  as sjui generates it (ProbeLabelHeightGeneratedView), compiled only in the
//  codegen host.
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct LabelHeightCodegenHalf: View {
    @State private var data = ProbeLabelHeightData()

    var body: some View {
        ProbeLabelHeightGeneratedView(data: $data)
    }
}
#endif
