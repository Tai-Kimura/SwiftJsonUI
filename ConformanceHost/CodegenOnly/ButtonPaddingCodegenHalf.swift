//
//  ButtonPaddingCodegenHalf.swift
//  ConformanceHost
//
//  The codegen half of ButtonPaddingProbeView: the six Buttons as sjui
//  generates them (ProbeLayouts/probe_button_padding.json →
//  ProbeButtonPaddingGeneratedView). Compiled only in the codegen host.
//

import SwiftUI
import SwiftJsonUI

struct ButtonPaddingCodegenHalf: View {
    @State private var data = ProbeButtonPaddingData()

    var body: some View {
        ProbeButtonPaddingGeneratedView(data: $data)
    }
}
