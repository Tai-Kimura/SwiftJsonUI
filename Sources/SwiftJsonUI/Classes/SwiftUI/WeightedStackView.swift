//
//  WeightedStackView.swift
//  SwiftJsonUI
//
//  Weighted layout using native HStack/VStack.
//  When all weights are equal (typical case): simple .frame(maxWidth/Height: .infinity)
//  When weights differ: Layout protocol for proportional distribution.
//

import SwiftUI

// MARK: - Weight Layout Value Key

public struct WeightLayoutKey: LayoutValueKey {
    public static let defaultValue: CGFloat = 0
}

public extension View {
    func layoutWeight(_ weight: CGFloat) -> some View {
        layoutValue(key: WeightLayoutKey.self, value: weight)
    }
}

// MARK: - Weighted HStack (Public API unchanged)

public struct WeightedHStack: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat
    let children: [(view: AnyView, weight: CGFloat)]
    let hasMatchParentCrossAxis: Bool

    public init(alignment: VerticalAlignment = .center, spacing: CGFloat = 0, children: [(view: AnyView, weight: CGFloat)], hasMatchParentCrossAxis: Bool = false) {
        self.alignment = alignment
        self.spacing = spacing
        self.children = children
        self.hasMatchParentCrossAxis = hasMatchParentCrossAxis
    }

    private var needsProportional: Bool {
        let weights = children.compactMap { $0.weight > 0 ? $0.weight : nil }
        guard let first = weights.first else { return false }
        return weights.contains { $0 != first }
    }

    public var body: some View {
        if needsProportional {
            WeightedHStackLayout(alignment: alignment, spacing: spacing) {
                ForEach(0..<children.count, id: \.self) { index in
                    children[index].view
                        .layoutWeight(children[index].weight)
                }
            }
        } else {
            HStack(alignment: alignment, spacing: spacing) {
                ForEach(0..<children.count, id: \.self) { index in
                    let child = children[index]
                    if child.weight > 0 {
                        child.view
                            .frame(minWidth: 0, maxWidth: .infinity)
                    } else {
                        child.view
                            .layoutPriority(1)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: !hasMatchParentCrossAxis)
        }
    }
}

// MARK: - Weighted VStack (Public API unchanged)

public struct WeightedVStack: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let children: [(view: AnyView, weight: CGFloat)]

    public init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 0, children: [(view: AnyView, weight: CGFloat)]) {
        self.alignment = alignment
        self.spacing = spacing
        self.children = children
    }

    private var needsProportional: Bool {
        let weights = children.compactMap { $0.weight > 0 ? $0.weight : nil }
        guard let first = weights.first else { return false }
        return weights.contains { $0 != first }
    }

    public var body: some View {
        if needsProportional {
            WeightedVStackLayout(alignment: alignment, spacing: spacing) {
                ForEach(0..<children.count, id: \.self) { index in
                    children[index].view
                        .layoutWeight(children[index].weight)
                }
            }
        } else {
            VStack(alignment: alignment, spacing: spacing) {
                ForEach(0..<children.count, id: \.self) { index in
                    let child = children[index]
                    if child.weight > 0 {
                        child.view
                            .frame(minHeight: 0, maxHeight: .infinity)
                    } else {
                        child.view
                            .layoutPriority(1)
                    }
                }
            }
        }
    }
}

// MARK: - Layout protocol (only used when weights differ)

public struct WeightedHStackLayout: Layout {
    public let alignment: VerticalAlignment
    public let spacing: CGFloat

    public init(alignment: VerticalAlignment = .center, spacing: CGFloat = 0) {
        self.alignment = alignment
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let spacingTotal = spacing * CGFloat(max(0, subviews.count - 1))

        guard let proposedWidth = proposal.width, proposedWidth.isFinite else {
            var totalWidth: CGFloat = 0
            var maxHeight: CGFloat = 0
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                totalWidth += size.width
                maxHeight = max(maxHeight, size.height)
            }
            return CGSize(width: totalWidth + spacingTotal, height: maxHeight)
        }

        let crossAxisProposal = ProposedViewSize(width: nil, height: proposal.height)
        var fixedWidth: CGFloat = 0
        var totalWeight: CGFloat = 0

        for subview in subviews {
            let weight = subview[WeightLayoutKey.self]
            if weight > 0 {
                totalWeight += weight
            } else {
                fixedWidth += subview.sizeThatFits(crossAxisProposal).width
            }
        }

        let resultHeight = proposal.height ?? subviews.map { $0.sizeThatFits(crossAxisProposal).height }.max() ?? 0
        return CGSize(width: proposedWidth, height: resultHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let spacingTotal = spacing * CGFloat(max(0, subviews.count - 1))
        let crossAxisProposal = ProposedViewSize(width: nil, height: bounds.height)

        var fixedWidth: CGFloat = 0
        var totalWeight: CGFloat = 0

        for subview in subviews {
            let weight = subview[WeightLayoutKey.self]
            if weight > 0 {
                totalWeight += weight
            } else {
                fixedWidth += subview.sizeThatFits(crossAxisProposal).width
            }
        }

        let remainingSpace = max(0, bounds.width - fixedWidth - spacingTotal)
        var x = bounds.minX

        for subview in subviews {
            let weight = subview[WeightLayoutKey.self]
            let childWidth: CGFloat
            let childSize: CGSize

            if weight > 0 && totalWeight > 0 {
                childWidth = remainingSpace * (weight / totalWeight)
                childSize = subview.sizeThatFits(ProposedViewSize(width: childWidth, height: bounds.height))
            } else {
                childSize = subview.sizeThatFits(crossAxisProposal)
                childWidth = childSize.width
            }

            let y: CGFloat
            switch alignment {
            case .top: y = bounds.minY
            case .bottom: y = bounds.maxY - childSize.height
            default: y = bounds.minY + (bounds.height - childSize.height) / 2
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: childWidth, height: bounds.height)
            )
            x += childWidth + spacing
        }
    }
}

public struct WeightedVStackLayout: Layout {
    public let alignment: HorizontalAlignment
    public let spacing: CGFloat

    public init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 0) {
        self.alignment = alignment
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let spacingTotal = spacing * CGFloat(max(0, subviews.count - 1))

        guard let proposedHeight = proposal.height, proposedHeight.isFinite else {
            var maxWidth: CGFloat = 0
            var totalHeight: CGFloat = 0
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                maxWidth = max(maxWidth, size.width)
                totalHeight += size.height
            }
            return CGSize(width: maxWidth, height: totalHeight + spacingTotal)
        }

        let crossAxisProposal = ProposedViewSize(width: proposal.width, height: nil)
        let resultWidth = proposal.width ?? subviews.map { $0.sizeThatFits(crossAxisProposal).width }.max() ?? 0
        return CGSize(width: resultWidth, height: proposedHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let spacingTotal = spacing * CGFloat(max(0, subviews.count - 1))
        let crossAxisProposal = ProposedViewSize(width: bounds.width, height: nil)

        var fixedHeight: CGFloat = 0
        var totalWeight: CGFloat = 0

        for subview in subviews {
            let weight = subview[WeightLayoutKey.self]
            if weight > 0 {
                totalWeight += weight
            } else {
                fixedHeight += subview.sizeThatFits(crossAxisProposal).height
            }
        }

        let remainingSpace = max(0, bounds.height - fixedHeight - spacingTotal)
        var y = bounds.minY

        for subview in subviews {
            let weight = subview[WeightLayoutKey.self]
            let childHeight: CGFloat
            let childSize: CGSize

            if weight > 0 && totalWeight > 0 {
                childHeight = remainingSpace * (weight / totalWeight)
                childSize = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: childHeight))
            } else {
                childSize = subview.sizeThatFits(crossAxisProposal)
                childHeight = childSize.height
            }

            let x: CGFloat
            switch alignment {
            case .leading: x = bounds.minX
            case .trailing: x = bounds.maxX - childSize.width
            default: x = bounds.minX + (bounds.width - childSize.width) / 2
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: bounds.width, height: childHeight)
            )
            y += childHeight + spacing
        }
    }
}
