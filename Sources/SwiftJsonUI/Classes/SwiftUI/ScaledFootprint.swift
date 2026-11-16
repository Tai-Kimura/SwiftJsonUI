import SwiftUI

/// Takes the space a `.scaleEffect(scale)` view is drawn in: the child's own
/// size times `scale`, with the child centred in it. `scaleEffect` changes the
/// drawing only, so a scaled view kept its unscaled footprint — an Indicator
/// with `indicatorStyle: large` (1.5) or `small` (0.8) was laid out 20, the
/// same as `medium` (frame-parity
/// Indicator/indicatorStyle__large and __small, 2026-10-05). The sjui codegen
/// emits the same modifier.
public struct ScaledFootprint: Layout {
    public var scale: CGFloat

    public init(scale: CGFloat) {
        self.scale = scale
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let size = child.sizeThatFits(.unspecified)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: .unspecified)
    }
}

public extension View {
    /// `.scaleEffect(scale)` that also lays out at the scaled size (ScaledFootprint).
    func scaledWithFootprint(_ scale: CGFloat) -> some View {
        ScaledFootprint(scale: scale) { self.scaleEffect(scale) }
    }
}
