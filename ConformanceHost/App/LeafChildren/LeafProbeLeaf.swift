// Scaffolded — this file is yours to edit.
// Source:    LeafProbeLeaf
// Generator: sjui g converter LeafProbeLeaf --attributes="title:String" --no-container
// Re-running the generator keeps this file: it asks first, and
// --skip-existing keeps it without asking. Only --force replaces it.

import SwiftUI

struct LeafProbeLeaf: View {
    let title: String

    init(title: String) {
        self.title = title
    }

    // The one edit to the scaffold (LeafChildrenProbeView): a body the test
    // can see, so "drawn" and "refused" are told apart.
    var body: some View {
        Text(title)
    }
}

#if DEBUG
struct LeafProbeLeaf_Previews: PreviewProvider {
    static var previews: some View {
        LeafProbeLeaf(title: "Sample Text")
    }
}
#endif
