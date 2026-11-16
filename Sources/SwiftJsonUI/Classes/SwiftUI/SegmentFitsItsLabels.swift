//
//  SegmentFitsItsLabels.swift
//  SwiftJsonUI
//
//  A wrapContent Segment is as wide as its labels: equal segments, each as
//  wide as the widest label, the whole capped at the width it is given — past
//  it the control takes that width and the longer labels are cut, as a
//  matchParent one is. The same on every platform (jsonui-cli 2.5.47,
//  Segment/items__wrap_uneven and __control/Segment__width-wrapContent).
//
//  A segmented Picker takes all the width it is offered; at its ideal width
//  UISegmentedControl keeps its equal segments (apportionsSegmentWidthsByContent
//  false), so the fixed-size control is the content width, and ViewThatFits
//  falls back to the offered width when that does not fit.
//

import SwiftUI

public extension View {
    /// A segmented Picker sized to its labels, capped at the offered width.
    func segmentFitsItsLabels() -> some View {
        ViewThatFits(in: .horizontal) {
            self.fixedSize(horizontal: true, vertical: false)
            self
        }
    }
}
