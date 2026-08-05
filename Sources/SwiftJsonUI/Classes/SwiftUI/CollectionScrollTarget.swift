//
//  CollectionScrollTarget.swift
//  SwiftJsonUI
//
//  What a `scrollTo` request names.
//
//  The attribute is declared as a PLAIN VALUE, not a Combine publisher:
//  `String` when `cellIdProperty` is set (scroll to that cell id), `Int`
//  otherwise (scroll to that index). 49-E withdrew the publisher spelling
//  on 2026-08-05 — naming a Swift transport in a cross-platform declaration
//  is what made kjui's map_to_kotlin_type pass `PassthroughSubject` through
//  verbatim and kill the Kotlin build. How the request travels is each
//  platform's own business; the declaration only says what it names.
//
//  Equatable on purpose: `.onChange(of:)` fires on a CHANGE, so re-sending
//  the same value does not re-scroll. That is publisher behaviour a plain
//  value cannot express, and giving it up is part of the same decision.
//

import SwiftUI

public enum CollectionScrollTarget: Equatable {
    /// Scroll to the cell whose id matches — the `cellIdProperty` spelling.
    case cellId(String)
    /// Scroll to the item at this index.
    case index(Int)

    /// Applies the scroll. Both cases carry a value SwiftUI's ScrollViewProxy
    /// can address directly, so the split is only about which one the layout
    /// declared.
    public func scroll(with proxy: ScrollViewProxy, anchor: UnitPoint) {
        switch self {
        case .cellId(let id):
            proxy.scrollTo(id, anchor: anchor)
        case .index(let index):
            proxy.scrollTo(index, anchor: anchor)
        }
    }
}
