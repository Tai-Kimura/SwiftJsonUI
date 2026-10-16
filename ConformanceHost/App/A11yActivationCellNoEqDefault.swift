//
//  A11yActivationCellNoEqDefault.swift
//  ConformanceHost
//
//  Compile-time default for CodegenOnly/A11yActivationCellNoEq.swift, for the
//  dynamic-only host, which has no generated A11yActivationCellView (nor the
//  generated rows it is the contrast for). scripts/generate_project.rb
//  includes EITHER this OR the CodegenOnly file.
//

import SwiftUI

// Stands in for the codegen half of a Dynamic-mode probe: DEBUG only, with the probe.
#if DEBUG

struct A11yActivationCellNoEq: View {
    @ObservedObject var data: A11yActivationProbeData

    var body: some View { EmptyView() }
}
#endif
