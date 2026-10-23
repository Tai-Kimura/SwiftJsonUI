//
//  ScrollHeightCodegenHalfDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/ScrollHeightCodegenHalf.swift, for the
//  dynamic-only host, which has no generated ProbeScrollHeightData.
//

import SwiftUI

struct ScrollHeightCodegenHalf: View {
    var body: some View {
        Text("no codegen half in a dynamic-only build").accessibilityIdentifier("sh_codegen_absent")
    }
}
