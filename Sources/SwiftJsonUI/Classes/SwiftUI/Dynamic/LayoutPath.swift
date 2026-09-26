//
//  LayoutPath.swift
//  SwiftJsonUI
//
//  A node's position in its layout, as a name — for a node that needs a name
//  the layout does not give it: an id-less Radio's value in its group. The
//  rule sjui build and kjui build run (jsonui-cli shared/core/layout_path.rb),
//  table-tested here against shared/core/layout_path_vectors.json, copied
//  byte-identical into Tests/SwiftJsonUITests/Fixtures and compared by CI's
//  vendored-fixture step — so a node is named alike on both iOS paths.
//
//  An explicit `id` wins; this is the name when there is none. The root is
//  `0`; each step appends `_<index>` of the node in its parent's child list:
//  `child` then `children`, counted as one list, every entry (object or not)
//  taking its index. The tree stamped is the include-expanded, style-merged
//  one — the one JSONLayoutLoader decodes — so an include takes the one index
//  of the root it expands to. The same on every load, unique within the view;
//  a node inserted before a node or before one of its ancestors moves its
//  path, nothing after it does, and a layout variant file has its own root.
//

import Foundation
#if DEBUG

enum LayoutPath {
    /// The key a node's path is written under (JsonUIShared::LayoutPath::KEY).
    static let key = "_layoutPath"

    /// The tree with every object node's path written under `key`, `path`
    /// being the root's.
    static func stamp(_ node: [String: Any], path: String = "0") -> [String: Any] {
        var node = node
        node[key] = path
        var index = 0
        for field in ["child", "children"] {
            switch node[field] {
            case let list as [Any]:
                var stamped: [Any] = []
                for entry in list {
                    if let child = entry as? [String: Any] {
                        stamped.append(stamp(child, path: "\(path)_\(index)"))
                    } else {
                        stamped.append(entry)
                    }
                    index += 1
                }
                node[field] = stamped
            case let single as [String: Any]:
                node[field] = stamp(single, path: "\(path)_\(index)")
                index += 1
            default:
                break
            }
        }
        return node
    }

    static func isStamped(_ node: [String: Any]) -> Bool {
        node[key] != nil
    }

    /// The viewId a component's handlers are handed: its id, else the type it
    /// is drawn as with its first letter lowercased, `_`, and its position —
    /// `switch_0_1`, `selectBox_0_3` — the name every path gives it
    /// (JsonUIShared::LayoutPath.view_id; 4f's ruling, 1.9.0). An id-less
    /// component's viewId was a per-kind word (`toggle`, `selectBox`,
    /// `textEditor`), the same for every one of the kind.
    static func viewId(of component: DynamicComponent) -> String {
        viewId(id: component.id, type: component.type, path: path(of: component))
    }

    /// The same name for a layout node as written (the shared vectors).
    static func viewId(of node: [String: Any]) -> String {
        viewId(id: node["id"] as? String, type: node["type"] as? String, path: node[key] as? String ?? "0")
    }

    static func viewId(id: String?, type: String?, path: String) -> String {
        if let id { return id }
        let drawn = drawnType(type ?? "")
        return drawn.prefix(1).lowercased() + drawn.dropFirst() + "_" + path
    }

    /// The type a spelling is drawn as: a section declared as an alias of
    /// another (`_alias_of`, generated as JsonUIComponentAliases) as that
    /// section, a synonym as its `render_as` else its `canonical`
    /// (TypeSynonyms), anything else as written — the rule of the shared
    /// function, held to it by the vectors' `view_id_cases`.
    static func drawnType(_ type: String) -> String {
        JsonUIComponentAliases.canonical(for: type) ?? TypeSynonyms.drawnAs(type)
    }

    /// A component's path, or `0` — a component decoded from a tree nothing
    /// stamped is its own root.
    static func path(of component: DynamicComponent) -> String {
        // Written as the literal `key` holds, so the raw-read guard
        // (scripts/check_attr_read_discipline.py) sees this read.
        component.rawAttribute("_layoutPath") as? String ?? "0"
    }
}

#endif // DEBUG
