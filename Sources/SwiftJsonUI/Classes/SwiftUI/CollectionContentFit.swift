//
//  CollectionContentFit.swift
//  SwiftJsonUI
//
//  A Collection's scroll container sized to its content along its scroll
//  axis, up to what its parent offers — past that it scrolls inside that
//  bound (4f ruling 2026-09-27, the user's "size to content": wrapContent
//  is "size to content, up to the parent's bound, then scroll", as web and
//  Compose draw it). A SwiftUI ScrollView takes every point it is offered,
//  so a wrapContent Collection with few cells filled its parent: 120 of a
//  120pt parent, the space below its cells empty, the views after it pushed
//  to the parent's end (measured on the ConformanceHost, sjui codegen and
//  the Dynamic renderer alike).
//
//  The scroll container is asked for its size with the scroll axis left
//  open — a ScrollView's ideal size there is its content's — and given the
//  smaller of that and the parent's bound. With no bound (inside another
//  ScrollView) it is its content: the page scrolls, not the list. The
//  measure lays out every cell once, which a wrapContent Collection is for:
//  a long feed bounded by its parent is declared matchParent or a size.
//

import SwiftUI

public struct CollectionContentFit: Layout {
    public let axis: Axis

    public init(axis: Axis) {
        self.axis = axis
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let view = subviews.first else { return .zero }
        switch axis {
        case .vertical:
            let content = view.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)).height
            let height = proposal.height.map { min(content, $0) } ?? content
            let width = view.sizeThatFits(ProposedViewSize(width: proposal.width, height: height)).width
            return CGSize(width: width, height: height)
        case .horizontal:
            let content = view.sizeThatFits(ProposedViewSize(width: nil, height: proposal.height)).width
            let width = proposal.width.map { min(content, $0) } ?? content
            let height = view.sizeThatFits(ProposedViewSize(width: width, height: proposal.height)).height
            return CGSize(width: width, height: height)
        }
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
    }
}
