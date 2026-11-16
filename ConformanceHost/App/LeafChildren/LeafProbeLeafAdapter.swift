// Scaffolded — this file is yours to edit.
// Source:    LeafProbeLeaf
// Generator: sjui g converter LeafProbeLeaf --no-container --attributes title:String
// Re-running the generator keeps this file: it asks first, and
// --skip-existing keeps it without asking. Only --force replaces it.

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct LeafProbeLeafAdapter: CustomComponentAdapter {
    var componentType: String { "LeafProbeLeaf" }

    // A leaf (--no-container): a layout that gives it children is refused.
    var acceptsChildren: Bool { false }

    func buildView(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?,
        parentOrientation: String?
    ) -> AnyView {
        // Use DynamicBindingHelper.resolveValue for Binding-safe value extraction
        let title: String = DynamicBindingHelper.resolveValue(component.rawData["title"], data: data) ?? ""

        return DynamicModifierHelper.applyStandardModifiers(
            AnyView(
                LeafProbeLeaf(
                    title: title
                )
            ),
            component: component,
            data: data
        )
    }
}

#endif
