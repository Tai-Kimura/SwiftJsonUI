// Scaffolded — this file is yours to edit.
// Source:    LeafProbeShelf
// Generator: sjui g converter LeafProbeShelf --container --attributes title:String
// Re-running the generator keeps this file: it asks first, and
// --skip-existing keeps it without asking. Only --force replaces it.

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct LeafProbeShelfAdapter: CustomComponentAdapter {
    var componentType: String { "LeafProbeShelf" }

    func buildView(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String?,
        parentOrientation: String?
    ) -> AnyView {
        // Use DynamicBindingHelper.resolveValue for Binding-safe value extraction
        let title: String = DynamicBindingHelper.resolveValue(component.rawData["title"], data: data) ?? ""

        // Build the content from child components
        let content = VStack(alignment: .leading, spacing: 0) {
            if let children = component.childComponents {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(
                        component: child,
                        data: data,
                        viewId: viewId,
                        isWeightedChild: false,
                        parentOrientation: "vertical"
                    )
                }
            }
        }

        let result = AnyView(
            LeafProbeShelf(
                title: title
            ) {
                content
            }
        )
        return DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)
    }
}

#endif
