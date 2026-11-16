import SwiftUI

/// `distribution: "fill"` — children grow FROM THEIR CONTENT to consume the
/// axis, leaving no free space (attribute_semantics.json distribution.ruling:
/// "proportional to their content size"). Each growable child gets its
/// content size plus an equal share of what is left; no leftover, or no
/// growable child, leaves the content sizes standing (fill never shrinks
/// anyone). The same policy as KotlinJsonUI's DistributionFillRow /
/// DistributionFillColumn.
///
/// An HStack of `.frame(maxWidth: .infinity)` children cannot express it: it
/// gives every flexible child the same width whatever its content, which is
/// fillEqually. A 300 row holding a 60 box and the labels "BBBB" and
/// "CCCCCCCC" drew 60 / 120 / 120 where Android draws 60 / 97 / 143 and web
/// 60 / 95.84 / 144.16 (frame-parity common/distribution__fill, 2026-10-05).
///
/// A child grows when it is flexible on the axis — it accepts more than its
/// content (an undeclared size, which `distribution: fill` gives
/// `.frame(maxWidth: .infinity)`). A child that declares its size is fixed
/// and keeps it (distribution.explicitChildSizeWins). Reading it from the
/// child keeps one rule for both renderers: the Dynamic container uses this
/// layout directly and the sjui codegen emits a call to it.
public struct DistributionFillLayout: Layout {
    public var axis: Axis
    public var spacing: CGFloat
    /// Where a child sits across the axis: 0 top / leading, 0.5 centre,
    /// 1 bottom / trailing.
    public var crossBias: CGFloat

    public init(axis: Axis, spacing: CGFloat = 0, crossBias: CGFloat = 0) {
        self.axis = axis
        self.spacing = spacing
        self.crossBias = crossBias
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = mainSizes(proposal: proposal, subviews: subviews)
        let cross = subviews.indices.map { crossSize(subviews[$0], main: sizes[$0], proposal: proposal) }.max() ?? 0
        let gaps = spacing * CGFloat(max(subviews.count - 1, 0))
        let main = available(proposal) ?? (sizes.reduce(0, +) + gaps)
        return axis == .horizontal ? CGSize(width: main, height: cross) : CGSize(width: cross, height: main)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = mainSizes(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        var position = axis == .horizontal ? bounds.minX : bounds.minY
        for (i, subview) in subviews.enumerated() {
            let crossRoom = axis == .horizontal ? bounds.height : bounds.width
            let child = subview.sizeThatFits(childProposal(main: sizes[i], cross: crossRoom))
            let crossLength = axis == .horizontal ? child.height : child.width
            let crossOffset = (crossRoom - crossLength) * crossBias
            if axis == .horizontal {
                subview.place(at: CGPoint(x: position, y: bounds.minY + crossOffset), anchor: .topLeading,
                              proposal: ProposedViewSize(width: sizes[i], height: crossLength))
            } else {
                subview.place(at: CGPoint(x: bounds.minX + crossOffset, y: position), anchor: .topLeading,
                              proposal: ProposedViewSize(width: crossLength, height: sizes[i]))
            }
            position += sizes[i] + spacing
        }
    }

    /// The growth arithmetic, kept apart so a test exercises the real policy.
    public static func grow(_ content: [CGFloat], grows: [Bool], available: CGFloat?, spacing: CGFloat) -> [CGFloat] {
        guard let available = available, available.isFinite else { return content }
        let leftover = available - spacing * CGFloat(max(content.count - 1, 0)) - content.reduce(0, +)
        let growers = grows.filter { $0 }.count
        guard leftover > 0, growers > 0 else { return content }
        let share = leftover / CGFloat(growers)
        return zip(content, grows).map { $1 ? $0 + share : $0 }
    }

    private func available(_ proposal: ProposedViewSize) -> CGFloat? {
        let value = axis == .horizontal ? proposal.width : proposal.height
        guard let value = value, value.isFinite else { return nil }
        return value
    }

    private func mainSizes(proposal: ProposedViewSize, subviews: Subviews) -> [CGFloat] {
        let content = subviews.map { subview -> CGFloat in
            let ideal = axis == .horizontal
                ? subview.sizeThatFits(ProposedViewSize(width: nil, height: proposal.height))
                : subview.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
            return axis == .horizontal ? ideal.width : ideal.height
        }
        let grows = subviews.indices.map { i -> Bool in
            let widest = axis == .horizontal
                ? subviews[i].sizeThatFits(ProposedViewSize(width: .infinity, height: proposal.height)).width
                : subviews[i].sizeThatFits(ProposedViewSize(width: proposal.width, height: .infinity)).height
            return widest > content[i] + 0.5
        }
        return Self.grow(content, grows: grows, available: available(proposal), spacing: spacing)
    }

    private func childProposal(main: CGFloat, cross: CGFloat?) -> ProposedViewSize {
        axis == .horizontal ? ProposedViewSize(width: main, height: cross) : ProposedViewSize(width: cross, height: main)
    }

    private func crossSize(_ subview: LayoutSubview, main: CGFloat, proposal: ProposedViewSize) -> CGFloat {
        let size = subview.sizeThatFits(childProposal(main: main, cross: axis == .horizontal ? proposal.height : proposal.width))
        return axis == .horizontal ? size.height : size.width
    }
}
