//
//  WrapCap.swift
//  SwiftJsonUI
//
//  A wrapContent box stops at its parent's size (user ruling 2026-10-05,
//  attribute_semantics wrapContentCap: "親の大きさが固定や matchparent ならその
//  大きさまで"). SwiftUI lets a container whose children have fixed sizes
//  report their size whatever it is offered: a lazy-none flow Collection, a
//  stack or an overlay of a 168-high child in a 100-high parent was 168 on
//  iOS, where Android stops the box at 100 and the content runs past it.
//
//  The child is measured with the offer it would have had, and on a capped
//  axis the box reports no more than that offer; the content is placed with
//  the same offer, so it lays out exactly as before and only the box's size
//  changes — and only when the content was larger than the offer. An axis the
//  parent leaves open (a ScrollView's content axis: no offer) is not capped.
//

import SwiftUI

public struct WrapCap: Layout {
    public let width: Bool
    public let height: Bool

    public init(width: Bool, height: Bool) {
        self.width = width
        self.height = height
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let view = subviews.first else { return .zero }
        let size = view.sizeThatFits(proposal)
        return CGSize(
            width: width ? capped(size.width, by: proposal.width) : size.width,
            height: height ? capped(size.height, by: proposal.height) : size.height
        )
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: proposal)
    }

    private func capped(_ content: CGFloat, by offer: CGFloat?) -> CGFloat {
        guard let offer, offer.isFinite else { return content }
        return min(content, offer)
    }
}

public extension View {
    /// Caps a wrapContent box at its parent's offer on the named axes
    /// (WrapCap). No-op when neither axis is named.
    @ViewBuilder
    func wrapCap(width: Bool, height: Bool) -> some View {
        if width || height {
            WrapCap(width: width, height: height) { self }
        } else {
            self
        }
    }
}
