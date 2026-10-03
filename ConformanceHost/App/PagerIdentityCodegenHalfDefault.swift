//
//  PagerIdentityCodegenHalfDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/PagerIdentityCodegenHalf.swift, for
//  the dynamic-only host, which has no generated ProbePagerIdentityData.
//  scripts/generate_project.rb includes EITHER this OR the CodegenOnly file.
//  Launched with `-pagerIdentityProbeCodegen` here, the probe says so instead
//  of drawing a pager.
//

import SwiftUI

struct PagerIdentityCodegenHalf: View {
    @SwiftUI.Binding var version: Int

    var body: some View {
        Text("no codegen half in a dynamic-only build").accessibilityIdentifier("pid_codegen_absent")
    }
}
