//
//  ScrollHeightCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of ScrollHeightProbeView: ProbeLayouts/probe_scroll_height.json
//  as sjui generates it (ProbeScrollHeightGeneratedView), compiled only in the
//  codegen host.
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct ScrollHeightCodegenHalf: View {
    @State private var data = ProbeScrollHeightData()

    var body: some View {
        ProbeScrollHeightGeneratedView(data: $data)
    }
}
#endif
