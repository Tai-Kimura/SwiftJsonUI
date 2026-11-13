//
//  CollectionReorderRule.swift
//  SwiftJsonUI
//
//  The rule a reorderable Collection follows, as plain functions (ticket jui-collection-drag-to-reorder). The same
//  rule is written for Android and web, and jsonui-cli's shared/core/reorder_vectors.json pins all three; these are
//  what the library's own drag (iOS below 27, and every list with a reorderHandle) and the conversions from SwiftUI's
//  onMove / ReorderDifference read.
//
//  Positions are in the rows' content coordinates (a scroll moves the rows and the finger alike, so it is part of
//  the drag's dy). Indexes are within one section; `to` is the index the row holds AFTER the move.
//

import CoreGraphics

public enum CollectionReorderRule {

    /// The top and bottom of one row, in content coordinates.
    public struct RowSpan: Equatable {
        public let top: CGFloat
        public let bottom: CGFloat
        public init(top: CGFloat, bottom: CGFloat) { self.top = top; self.bottom = bottom }
        public var center: CGFloat { (top + bottom) / 2 }
    }

    /// Where the row grabbed at `from` lands while it is dragged `dy`: past every neighbour whose centre its own
    /// centre has crossed (exactly on a centre is not past it), and never onto or past a locked row.
    public static func target(from: Int, dy: CGFloat, rows: [RowSpan], locked: Set<Int>) -> Int {
        guard rows.indices.contains(from) else { return from }
        let center = rows[from].center + dy
        var to = from
        if dy > 0 {
            var j = from + 1
            while j < rows.count, !locked.contains(j), center > rows[j].center {
                to = j
                j += 1
            }
        } else if dy < 0 {
            var j = from - 1
            while j >= 0, !locked.contains(j), center < rows[j].center {
                to = j
                j -= 1
            }
        }
        return to
    }

    /// Whether letting go commits the move: the finger is inside the Collection's container (the stack that holds
    /// the rows, its header and footer included). Above the first row the row lands first, below the last row last
    /// (target() gives that); only outside the container is the move cancelled — what SwiftUI's own reorder
    /// container does on iOS 27, which reports a release over the header or the footer as the start or the end and
    /// cannot be told otherwise (measured; ruling 2026-11-13).
    public static func releaseCommits(fingerY: CGFloat, containerTop: CGFloat, containerBottom: CGFloat) -> Bool {
        fingerY >= containerTop && fingerY <= containerBottom
    }

    /// `onReorder` is called only for a real move.
    public static func shouldReport(from: Int, to: Int) -> Bool { from != to }

    /// SwiftUI's List.onMove gives the destination BEFORE the moved row is taken out.
    public static func toIndex(fromOnMove from: Int, destination: Int) -> Int {
        destination > from ? destination - 1 : destination
    }

    /// SwiftUI's ReorderDifference (iOS 27) names the row the moved one goes in front of, or the end.
    /// `beforeIndex` is that row's index in the order before the move; nil is the end.
    public static func toIndex(from: Int, beforeIndex: Int?, count: Int) -> Int {
        guard let before = beforeIndex else { return count - 1 }
        return before > from ? before - 1 : before
    }

    /// Whether a move crosses a locked row (or starts on one): the library refuses it, whichever way it came.
    public static func crossesLocked(from: Int, to: Int, locked: Set<Int>) -> Bool {
        if locked.contains(from) { return true }
        let range = from < to ? (from + 1)...to : to...max(to, from - 1)
        return from != to && range.contains { locked.contains($0) }
    }

    /// Where a move reported from anywhere (iOS 27's container and List.onMove can carry a row past a locked one)
    /// ends: short of the first locked row in its way, as the library's own drag stops. Nil when the row itself is
    /// locked, which never moves.
    public static func clampedTo(from: Int, to: Int, locked: Set<Int>) -> Int? {
        if locked.contains(from) { return nil }
        if to > from, let wall = locked.filter({ $0 > from && $0 <= to }).min() { return wall - 1 }
        if to < from, let wall = locked.filter({ $0 < from && $0 >= to }).max() { return wall + 1 }
        return to
    }

    /// The edge band, in points, and the fastest auto-scroll, in points a second.
    public static let autoScrollBand: CGFloat = 48
    public static let autoScrollMaxSpeed: CGFloat = 800

    /// The auto-scroll velocity for a finger at `y` in a viewport from `top` to `bottom` (window coordinates):
    /// negative up, positive down, 0 outside both bands. The speed grows with how deep into the band the finger is.
    /// In a viewport shorter than two bands the nearer edge wins.
    public static func autoScrollVelocity(fingerY y: CGFloat, viewportTop top: CGFloat, viewportBottom bottom: CGFloat) -> CGFloat {
        let band = autoScrollBand
        let fromTop = y - top, fromBottom = bottom - y
        let inTop = fromTop < band, inBottom = fromBottom < band
        guard inTop || inBottom else { return 0 }
        let upward = inTop && (!inBottom || fromTop <= fromBottom)
        let depth = upward ? band - max(0, fromTop) : band - max(0, fromBottom)
        let speed = autoScrollMaxSpeed * min(1, max(0, depth / band))
        return upward ? -speed : speed
    }

    /// The accessibility actions a row offers: up unless it is first, the row above is locked, or it is locked
    /// itself; down likewise.
    public static func accessibilityMoves(index: Int, count: Int, locked: Set<Int>) -> (up: Bool, down: Bool) {
        guard !locked.contains(index), index >= 0, index < count else { return (false, false) }
        let up = index > 0 && !locked.contains(index - 1)
        let down = index < count - 1 && !locked.contains(index + 1)
        return (up, down)
    }
}
