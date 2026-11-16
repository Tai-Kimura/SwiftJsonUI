//
//  ButtonPaddingCodegenHalfDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/ButtonPaddingCodegenHalf.swift, for
//  the dynamic-only host, which has no generated ProbeButtonPaddingData.
//  scripts/generate_project.rb includes EITHER this OR the CodegenOnly file.
//

import SwiftUI

struct ButtonPaddingCodegenHalf: View {
    var body: some View {
        Text("no codegen half in a dynamic-only build").accessibilityIdentifier("bp_codegen_absent")
    }
}
