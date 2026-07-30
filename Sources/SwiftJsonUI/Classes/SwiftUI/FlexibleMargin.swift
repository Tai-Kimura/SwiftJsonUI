//
//  FlexibleMargin.swift
//  SwiftJsonUI
//
//  Bounded horizontal margins for the SwiftUI layout mode.
//

import SwiftUI

/// A leading/trailing margin expressed as a *range* rather than a fixed inset.
///
/// UIKit gets this from AutoLayout: `minStartMargin` / `maxStartMargin` become a
/// `>=` / `<=` constraint pair against the superview's edge, and the solver picks
/// the value (`UIViewDisposure.applyLeftPaddingConstraint`). SwiftUI has no
/// flexible `padding`, so the equivalent is a bounded gap in a zero-spacing
/// `HStack` — a `Spacer` is the only view that absorbs slack, and a `frame`
/// caps how much of it the spacer may take.
///
/// Semantics per side:
///
/// - **both bounds** — gap flexes within `min...max`.
/// - **max only** — gap flexes within `0...max`.
/// - **min only** — fixed inset of `min`. There is no ceiling for slack to be
///   distributed against, so a greedy spacer would shove the content to the
///   opposite edge; the floor is the whole of what was asked for. (UIKit drops a
///   lone `min` entirely — its flexible branch requires both bounds — so this is
///   deliberately the more useful of the two readings.)
///
/// When neither side has a ceiling no stack is introduced at all, which keeps the
/// common case free of an extra layout container.
public struct FlexibleHorizontalMarginModifier: ViewModifier {
    private let minStart: CGFloat?
    private let maxStart: CGFloat?
    private let minEnd: CGFloat?
    private let maxEnd: CGFloat?

    public init(
        minStart: CGFloat? = nil,
        maxStart: CGFloat? = nil,
        minEnd: CGFloat? = nil,
        maxEnd: CGFloat? = nil
    ) {
        self.minStart = minStart
        self.maxStart = maxStart
        self.minEnd = minEnd
        self.maxEnd = maxEnd
    }

    public func body(content: Content) -> some View {
        if maxStart == nil && maxEnd == nil {
            content
                .padding(.leading, minStart ?? 0)
                .padding(.trailing, minEnd ?? 0)
        } else {
            HStack(spacing: 0) {
                gap(min: minStart, max: maxStart)
                content
                gap(min: minEnd, max: maxEnd)
            }
        }
    }

    @ViewBuilder
    private func gap(min: CGFloat?, max: CGFloat?) -> some View {
        if let max = max {
            // `minLength` is the floor; the frame is the ceiling.
            Spacer(minLength: min ?? 0)
                .frame(maxWidth: max)
        } else if let min = min {
            // This side is fixed, but the row is flexible because the other
            // side has a ceiling — so the inset has to be a gap in the stack,
            // not a padding around it.
            Spacer(minLength: 0)
                .frame(width: min)
        }
    }
}

public extension View {
    /// Applies `minStartMargin` / `maxStartMargin` / `minEndMargin` /
    /// `maxEndMargin`. Pass `nil` for a bound that was not declared — an
    /// omitted bound is not the same as `0`.
    func flexibleHorizontalMargin(
        minStart: CGFloat? = nil,
        maxStart: CGFloat? = nil,
        minEnd: CGFloat? = nil,
        maxEnd: CGFloat? = nil
    ) -> some View {
        modifier(
            FlexibleHorizontalMarginModifier(
                minStart: minStart,
                maxStart: maxStart,
                minEnd: minEnd,
                maxEnd: maxEnd
            )
        )
    }
}
