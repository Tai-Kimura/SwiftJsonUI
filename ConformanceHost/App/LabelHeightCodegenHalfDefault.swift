//
//  LabelHeightCodegenHalfDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/LabelHeightCodegenHalf.swift, for the
//  dynamic-only host, which has no generated ProbeLabelHeightData.
//

import SwiftUI

struct LabelHeightCodegenHalf: View {
    var body: some View {
        Text("no codegen half in a dynamic-only build").accessibilityIdentifier("lh_codegen_absent")
    }
}
