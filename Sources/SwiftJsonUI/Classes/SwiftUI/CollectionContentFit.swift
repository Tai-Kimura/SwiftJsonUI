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
    /// Size to the content along `axis` (the scroll axis).
    public let along: Bool
    /// Size to the content across `axis` too: a horizontal row of
    /// wrapContent height is its cells' height, not the height it is offered
    /// — a LazyHStack takes all of it, so until SwiftJsonUI 10.29.0 such a
    /// row filled its parent (120 of a 120pt parent; the eager row, an
    /// HStack, was its cells' 28). As `along`, capped by the parent's bound.
    public let across: Bool

    public init(axis: Axis, along: Bool = true, across: Bool = false) {
        self.axis = axis
        self.along = along
        self.across = across
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let view = subviews.first else { return .zero }
        switch axis {
        case .vertical:
            let height: CGFloat? = along
                ? capped(view.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)).height, by: proposal.height)
                : proposal.height
            let width = across
                ? capped(view.sizeThatFits(ProposedViewSize(width: nil, height: height)).width, by: proposal.width)
                : view.sizeThatFits(ProposedViewSize(width: proposal.width, height: height)).width
            return CGSize(width: width, height: height ?? view.sizeThatFits(ProposedViewSize(width: width, height: nil)).height)
        case .horizontal:
            let width: CGFloat? = along
                ? capped(view.sizeThatFits(ProposedViewSize(width: nil, height: proposal.height)).width, by: proposal.width)
                : proposal.width
            let height = across
                ? capped(view.sizeThatFits(ProposedViewSize(width: width, height: nil)).height, by: proposal.height)
                : view.sizeThatFits(ProposedViewSize(width: width, height: proposal.height)).height
            return CGSize(width: width ?? view.sizeThatFits(ProposedViewSize(width: nil, height: height)).width, height: height)
        }
    }

    private func capped(_ content: CGFloat, by bound: CGFloat?) -> CGFloat {
        bound.map { min(content, $0) } ?? content
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
    }
}

public extension View {
    /// Sizes the view to its content along `axis`, capped by what its parent
    /// offers — the modifier sjui emits after the bounds frame of a
    /// wrapContent axis with a max (and the Dynamic renderer applies there):
    /// `.frame(maxWidth:)` takes the width it is offered up to the max, so a
    /// wrapContent chip with maxWidth 160 and the text "chip" was 160 wide
    /// where Compose and the web drew it its text's width (the user's ruling,
    /// 2026-09-27). The frame's ideal size is the content's clamped to the
    /// max, so a longer text still wraps at the max. SwiftJsonUI 10.29.0.
    func contentFit(_ axis: Axis) -> some View {
        CollectionContentFit(axis: axis) { self }
    }
}
