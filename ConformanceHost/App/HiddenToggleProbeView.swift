// Scratch probe (not committed): the library's three hide wrappers around a
// container with an identifier, toggled at runtime, and an opacity-0 control.
import SwiftUI
import SwiftJsonUI

// Dynamic-mode probe: SwiftJsonUI compiles Dynamic mode (DynamicView,
// DynamicComponent, CustomComponentRegistry) in DEBUG only, so a Release
// build of this host carries no probe (it hosts the codegen face only).
#if DEBUG

struct HiddenToggleProbeView: View {
    @State private var hidden = true
    @State private var visibility = "invisible"

    private func box(_ id: String) -> some View {
        VStack(spacing: 2) {
            Text("text of \(id)")
            Image(systemName: "star.fill").accessibilityLabel(Text("star of \(id)"))
            Rectangle().fill(Color.gray).frame(width: 60, height: 20)
            Rectangle().fill(Color.blue).frame(width: 60, height: 20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("hidden toggle probe").accessibilityIdentifier("htp_ready")
            Button("toggle") {
                hidden.toggle()
                visibility = hidden ? "invisible" : "visible"
            }.accessibilityIdentifier("htp_toggle")
            VisibilityWrapper(visibility) { box("htp_wrapper") }
            ReactiveVisibilityWrapper(visibility: $visibility) { box("htp_reactive_vis") }
            ReactiveHiddenWrapper(isHidden: $hidden, content: AnyView(box("htp_reactive_hidden")))
            box("htp_opacity0").opacity(0)
        }
    }
}
#endif
