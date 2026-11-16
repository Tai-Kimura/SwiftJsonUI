//
//  CellDataRefreshCodegenHalfDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/CellDataRefreshCodegenHalf.swift, for
//  the dynamic-only host, which has no generated ProbeCellDataRefreshData.
//  scripts/generate_project.rb includes EITHER this OR the CodegenOnly file.
//

import SwiftUI

struct CellDataRefreshCodegenHalf: View {
    let version: Int

    var body: some View {
        Text("no codegen half in a dynamic-only build").accessibilityIdentifier("cdr_codegen_absent")
    }
}
