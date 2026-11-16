//
//  PaddingsOrderCodegenHalfDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/PaddingsOrderCodegenHalf.swift, for
//  the dynamic-only host, which has no generated ProbePaddingsOrderData.
//

import SwiftUI

struct PaddingsOrderCodegenHalf: View {
    var body: some View {
        Text("no codegen half in a dynamic-only build").accessibilityIdentifier("po_codegen_absent")
    }
}
