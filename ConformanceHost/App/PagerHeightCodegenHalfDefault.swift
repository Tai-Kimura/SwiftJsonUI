//
//  PagerHeightCodegenHalfDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/PagerHeightCodegenHalf.swift, for the
//  dynamic-only host, which has no generated ProbePagerHeightData.
//  scripts/generate_project.rb includes EITHER this OR the CodegenOnly file.
//

import SwiftUI

struct PagerHeightCodegenHalf: View {
    var body: some View {
        Text("no codegen half in a dynamic-only build").accessibilityIdentifier("ph_codegen_absent")
    }
}
