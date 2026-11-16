//
//  PagerHeightCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of PagerHeightProbeView: the pagers as sjui generates
//  them (ProbeLayouts/probe_pager_height.json → ProbePagerHeightGeneratedView),
//  with this view holding the generated view's data as an app's ViewModel
//  does. ProbePagerHeightData exists only in CodegenStaging, so this file is
//  compiled only in the codegen host (scripts/generate_project.rb).
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct PagerHeightCodegenHalf: View {
    @State private var data = ProbePagerHeightData()

    var body: some View {
        ProbePagerHeightGeneratedView(data: $data)
            .onAppear { data.rows = PagerHeightProbeView.rows() }
    }
}
#endif
