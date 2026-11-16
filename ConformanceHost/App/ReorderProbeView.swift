//
//  ReorderProbeView.swift
//  ConformanceHost
//
//  A reorderable Collection drawn through Dynamic (ticket jui-collection-drag-to-reorder), for
//  ReorderProbeUITests: rows A–F of conformance_cell_within (its `within_badge` is the handle when the variant
//  declares one), a header and a footer of conformance_cell, and the order the VM holds shown in `reorder_order`.
//  Launch with `-reorderProbe <variant>`:
//
//    none    the A6 shape: a ScrollView, a View, the Collection with lazy "none" (its VStack is the container)
//    lazy    the Collection's own ScrollView + LazyVStack (CollectionStackView)
//    handle  none, with reorderHandle "within_badge"
//    locked  none, with reorderLockedProperty "locked" (row C is locked)
//    list    a sectioned Collection with listStyle: List.onMove
//

import SwiftUI
import SwiftJsonUI

#if DEBUG

struct ReorderProbeView: View {
    let variant: String
    @State private var rows = ["A", "B", "C", "D", "E", "F"]
    @State private var log = "none"

    private var collection: String {
        var extra = ""
        switch variant {
        case "lazy": extra = #", "lazy": "lazy""#
        case "handle": extra = #", "lazy": "none", "reorderHandle": "within_badge""#
        case "locked": extra = #", "lazy": "none", "reorderLockedProperty": "locked""#
        case "list": extra = #", "listStyle": "plain", "height": 420"#
        default: extra = #", "lazy": "none""#
        }
        return #"{"type": "Collection", "id": "reorder_list", "width": "matchParent", "height": "wrapContent", "#
            + #""items": "@{rows}", "cellIdProperty": "cellId", "reorderable": true, "onReorder": "@{onReorder}", "#
            + #""sections": [{"header": "conformance_cell", "cell": "conformance_cell_within", "footer": "conformance_cell"}]"#
            + extra + "}"
    }

    private var layout: String {
        if variant == "lazy" || variant == "list" {
            return #"{"type": "View", "id": "reorder_root", "orientation": "vertical", "width": "matchParent", "height": "matchParent", "child": ["#
                + collection + "]}"
        }
        return #"{"type": "ScrollView", "id": "reorder_scroll", "orientation": "vertical", "width": "matchParent", "height": "matchParent", "child": [{"type": "View", "orientation": "vertical", "width": "matchParent", "height": "wrapContent", "child": [{"type": "Label", "id": "reorder_before", "text": "before", "width": "wrapContent", "height": "wrapContent"}, "#
            + collection + #", {"type": "Label", "id": "reorder_after", "text": "after", "width": "wrapContent", "height": 1200}]}]}"#
    }

    private var data: [String: Any] {
        var section = CollectionDataSection()
        section.setHeader(viewName: "", data: ["title": "head"])
        section.setCells(viewName: "", data: rows.map { ["title": $0, "cellId": $0, "locked": $0 == "C"] })
        section.setFooter(viewName: "", data: ["title": "foot"])
        let onReorder: (Int, Int, Int) -> Void = { section, from, to in
            log = "\(section):\(from)->\(to)"
            rows.insert(rows.remove(at: from), at: to)
        }
        return ["rows": CollectionDataSource(sections: [section]), "onReorder": onReorder]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rows.joined()).accessibilityIdentifier("reorder_order")
            Text(log).accessibilityIdentifier("reorder_log")
            if let component = try? JSONDecoder().decode(DynamicComponent.self, from: Data(layout.utf8)) {
                DynamicComponentBuilder(component: component, data: data)
            } else {
                Text("layout did not decode").accessibilityIdentifier("reorder_error")
            }
        }
    }
}

#endif
