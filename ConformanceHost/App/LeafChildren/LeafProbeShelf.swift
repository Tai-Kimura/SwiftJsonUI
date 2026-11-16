// Scaffolded — this file is yours to edit.
// Source:    LeafProbeShelf
// Generator: sjui g converter LeafProbeShelf --attributes="title:String" --container
// Re-running the generator keeps this file: it asks first, and
// --skip-existing keeps it without asking. Only --force replaces it.

import SwiftUI

struct LeafProbeShelf<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        content
    }
}

#if DEBUG
struct LeafProbeShelf_Previews: PreviewProvider {
    static var previews: some View {
        LeafProbeShelf(title: "Sample Text") {
            Text("Preview Content")
        }
    }
}
#endif
