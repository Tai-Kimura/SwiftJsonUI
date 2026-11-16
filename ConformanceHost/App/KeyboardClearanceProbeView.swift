//
//  KeyboardClearanceProbeView.swift
//  ConformanceHost
//
//  How far above the ScrollView's visible bottom does a focused field stop
//  once the keyboard is up? NOT part of the conformance suite. Launch with
//  `-keyboardClearanceProbe footer|bare` and `-keyboardClearancePadding N`.
//
//  Reported 2026-09-22 from a real device: in the footer shape (a vertical
//  stack of a weight-1 ScrollView and a fixed footer, the field inside the
//  scroll) the focused field's bottom sat ON the footer's top — 40px under
//  it, measured on the screenshot, because the field's decorated container
//  extends below the text area SwiftUI aligns. `additionalPadding` (default
//  20) existed in KeyboardAvoidanceConfiguration and reached nothing.
//
//  Two shapes, because the clearance is defined against the VISIBLE BOTTOM
//  and that edge is a different thing in each:
//
//    footer   ScrollView ends at the footer's top; the footer takes the
//             keyboard's safe area.          edge = footer.minY
//    bare     ScrollView meets the keyboard.  edge = keyboard.minY
//

import SwiftUI
import SwiftJsonUI

struct KeyboardClearanceProbeView: View {
    @State private var text = ""

    private var padding: CGFloat {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-keyboardClearancePadding"), i + 1 < args.count,
           let v = Double(args[i + 1]) {
            return CGFloat(v)
        }
        return 20
    }

    private var footer: Bool {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-keyboardClearanceProbe"), i + 1 < args.count {
            return args[i + 1] == "footer"
        }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            AdvancedKeyboardAvoidingScrollView(
                .vertical, showsIndicators: true,
                configuration: KeyboardAvoidanceConfiguration(additionalPadding: padding)
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<7, id: \.self) { i in
                        Text("filler_\(i)").frame(height: 80)
                            .accessibilityIdentifier("filler_\(i)")
                    }
                    // Decorated like a generated field: the text area sits
                    // inside a padded container that extends below it.
                    // No identifier on the container: an identifier on a
                    // SwiftUI container overwrites every descendant's own
                    // (measured in OffsetHitTargetProbeView), and this probe
                    // needs the FIELD's frame, not the container's.
                    TextField("probe", text: $text)
                        .frame(height: 44)
                        .accessibilityIdentifier("probe_field")
                        .padding(.vertical, 24)
                        .background(Color.yellow)
                    ForEach(7..<20, id: \.self) { i in
                        Text("filler_\(i)").frame(height: 80)
                            .accessibilityIdentifier("filler_\(i)")
                    }
                }
            }
            if footer {
                Color.blue.frame(height: 56)
                    .accessibilityIdentifier("probe_footer")
            }
        }
    }
}
