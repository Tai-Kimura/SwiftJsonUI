// Scaffolded — this file is yours to edit.
// Source:    LeafProbeAuto
// Generator: sjui g converter LeafProbeAuto --attributes="title:String"
// Re-running the generator keeps this file: it asks first, and
// --skip-existing keeps it without asking. Only --force replaces it.

import SwiftUI

struct LeafProbeAuto<Content: View>: View {
    let title: String
    let content: Content?

    init(title: String, @ViewBuilder content: () -> Content = { EmptyView() }) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Group {
            if let content = content {
                content
            } else {
                EmptyView()
            }
        }
    }
}

#if DEBUG
struct LeafProbeAuto_Previews: PreviewProvider {
    static var previews: some View {
        LeafProbeAuto(title: "Sample Text") {
            Text("Preview Content")
        }
    }
}
#endif
