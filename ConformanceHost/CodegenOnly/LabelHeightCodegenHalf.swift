//
//  LabelHeightCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of LabelHeightProbeView: ProbeLayouts/probe_label_height.json
//  and probe_label_height_noscroll.json as sjui generates them, compiled only in
//  the codegen host.
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct LabelHeightCodegenHalf: View {
    let noScroll: Bool
    @State private var data = ProbeLabelHeightData()
    @State private var noScrollData = ProbeLabelHeightNoscrollData()

    var body: some View {
        if noScroll {
            ProbeLabelHeightNoscrollGeneratedView(data: $noScrollData)
        } else {
            ProbeLabelHeightGeneratedView(data: $data)
        }
    }
}
#endif
