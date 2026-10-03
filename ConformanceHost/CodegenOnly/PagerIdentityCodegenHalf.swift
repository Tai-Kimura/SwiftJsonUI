//
//  PagerIdentityCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of PagerIdentityProbeView: the pager as sjui generates
//  it (ProbeLayouts/probe_pager_identity.json → ProbePagerIdentityGeneratedView),
//  with this view holding the generated view's data as an app's ViewModel
//  does. ProbePagerIdentityData exists only in CodegenStaging, so this file
//  is compiled only in the codegen host: scripts/generate_project.rb adds
//  CodegenOnly/ with the staging sources and drops its App/ default
//  (PagerIdentityCodegenHalfDefault.swift), as it does the fixture registry's.
//

import SwiftUI
import SwiftJsonUI

struct PagerIdentityCodegenHalf: View {
    @SwiftUI.Binding var version: Int
    @State private var data = ProbePagerIdentityData()

    var body: some View {
        ProbePagerIdentityGeneratedView(data: $data)
            .onAppear {
                data.rows = PagerIdentityProbeView.rows(version: 0, page: 0)
                data.onPageChanged = { newPage in
                    version += 1
                    data.rows = PagerIdentityProbeView.rows(version: version, page: newPage)
                }
            }
    }
}
