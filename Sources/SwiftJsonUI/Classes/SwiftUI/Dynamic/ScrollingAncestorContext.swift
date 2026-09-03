//
//  ScrollingAncestorContext.swift
//  SwiftJsonUI
//
//  Whether the view being rendered sits under something that scrolls — the
//  one fact a flow Collection needs to decide whether it has bounds of its
//  own to scroll inside (CollectionConverter.flowDefersToScrollingAncestor).
//
//  Carried as SwiftUI environment rather than derived from the JSON tree. A
//  Collection cell is a separate layout file rendered through DynamicView;
//  the environment crosses that boundary, a tree walk cannot — which is the
//  static codegen's known limit (sjui 912739e2: a layout used as a cell has
//  no ancestor in its own file). Set by DynamicScrollViewContainer on its
//  content and by CollectionConverter on the cells, headers and footers of a
//  vertically scrolling Collection. A mark only ever adds: nothing clears it,
//  so a non-scrolling Collection inside a ScrollView keeps the ScrollView's
//  mark on its cells.
//

import SwiftUI

#if DEBUG

private struct ScrollingAncestorKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// True inside a scrolling container rendered by the dynamic path —
    /// ScrollView content, or the cells of a vertically scrolling Collection.
    var jsonuiScrollingAncestor: Bool {
        get { self[ScrollingAncestorKey.self] }
        set { self[ScrollingAncestorKey.self] = newValue }
    }
}

/// Marks the content as sitting under a scrolling ancestor when `active`;
/// otherwise leaves whatever the environment already says.
struct ScrollingAncestorMark: ViewModifier {
    let active: Bool
    @Environment(\.jsonuiScrollingAncestor) private var inherited

    func body(content: Content) -> some View {
        content.environment(\.jsonuiScrollingAncestor, inherited || active)
    }
}

/// Renders one of two fully built shapes depending on the environment — the
/// decision the converter cannot make from the component alone. Both shapes
/// are built up front (view values, not rendered trees); only the chosen one
/// has a body evaluated.
struct ScrollingAncestorSwitch: View {
    let underScrollingAncestor: AnyView
    let otherwise: AnyView
    @Environment(\.jsonuiScrollingAncestor) private var inside

    var body: some View {
        if inside {
            underScrollingAncestor
        } else {
            otherwise
        }
    }
}

#endif
