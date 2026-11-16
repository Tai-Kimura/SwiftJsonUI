//
//  BindFold.swift
//  SwiftJsonUI
//
//  `bind` is an alternative spelling of a component's own value attribute
//  (attribute_definitions.json common.bind), folded on the node a renderer
//  draws — after its style is merged and its responsive branch resolved
//  (jsonui-cli 1.9.0; shared/core/bind_fold.rb is the rule the codegen and
//  the validator fold by, and KotlinJsonUI Dynamic folds by it too):
//  - a lone `bind` becomes the first attribute `bind` stands for;
//  - beside any of them, `bind` is dropped (the author's value wins);
//  - on a section the table does not name, `bind` stays.
//  The table is common.bind.primaryValue, generated (JsonUIBindPrimaryValue).
//
//  JSONLayoutLoader folds the tree once, where it is about to decode it:
//  styles are merged and includes expanded by then, and a responsive branch
//  is resolved before decodeComponent(from:) is reached. It is not folded in
//  loadProcessedJSON, whose tree is resolved later: a branch's value would be
//  missed. shared/core/bind_fold_vectors.json holds the cases, copied into
//  Tests/SwiftJsonUITests/Fixtures and compared by CI.
//

import Foundation
#if DEBUG

enum BindFold {
    /// The tree with `bind` folded on every node: an object with a `type`,
    /// wherever it sits (`child` / `children`, a tab's or a section's inline
    /// node). A node the app draws with its own component
    /// (CustomComponentRegistry) is left as written, as the codegen asks the
    /// app's converters before it folds.
    static func fold(_ node: [String: Any]) -> [String: Any] {
        var node = node
        for (key, value) in node {
            node[key] = foldNested(value)
        }
        return foldNode(node)
    }

    private static func foldNested(_ value: Any) -> Any {
        switch value {
        case let object as [String: Any]:
            return object["type"] is String ? fold(object) : object.mapValues(foldNested)
        case let list as [Any]:
            return list.map(foldNested)
        default:
            return value
        }
    }

    /// One node, its `bind` folded; the node as it is when there is nothing
    /// to fold. The type is matched as written, a type-synonym resolved to
    /// its canonical section first (bind_fold.rb `fold`).
    static func foldNode(_ node: [String: Any]) -> [String: Any] {
        guard let bind = node["bind"], let type = node["type"] as? String else { return node }
        if CustomComponentRegistry.shared.adapter(for: type) != nil { return node }
        let section = TypeSynonyms.entries[type]?.canonical ?? type
        let values = JsonUIBindPrimaryValue.attributes(for: section, node: node)
        guard let first = values.first else { return node }
        var folded = node
        folded.removeValue(forKey: "bind")
        if !values.contains(where: { node[$0] != nil }) {
            folded[first] = bind
        }
        return folded
    }
}
#endif
