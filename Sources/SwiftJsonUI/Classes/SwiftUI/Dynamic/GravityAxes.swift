//
//  GravityAxes.swift
//  SwiftJsonUI
//
//  `gravity` resolved per axis, in ONE place.
//
//  The policy had four private copies of the horizontal extractor and three of
//  the vertical one, and they had drifted: the dynamic ScrollView converter's
//  copy (a file deleted in 10.20.0 — the builder never dispatched to it) never
//  learned `centerHorizontal`, so a `gravity: ["centerHorizontal"]` inside a
//  ScrollView fell to `left` while the same declaration centred everywhere
//  else. A copied helper going stale is the shape G measured on android
//  (`Label/fontFamily__binding` inert with the binding resolving fine — a
//  private duplicate of a shared helper), reported across for an ios check;
//  this is that check, and it found one.
//
//  The rule itself is the 2026-08-07 canon
//  (`attribute_semantics.json` gravityDefaults): each axis resolves
//  independently, and the axis a single-value gravity does NOT name takes the
//  container default for that axis — top vertically, start horizontally. Never
//  "unset", never inherited from the parent.
//

import SwiftUI
#if DEBUG

public enum GravityAxes {

    /// The horizontal axis, or the declared default (`start`) when unnamed.
    /// `centerHorizontal` is the single-axis spelling of `center`.
    public static func horizontal(_ gravity: [String]?) -> String {
        guard let parts = gravity, !parts.isEmpty else { return "left" }
        if let h = parts.first(where: { ["left", "center", "right", "centerHorizontal"].contains($0) }) {
            return h == "centerHorizontal" ? "center" : h
        }
        return "left"
    }

    /// The vertical axis, or the declared default (`top`) when unnamed.
    /// `centerVertical` is the single-axis spelling of `center`.
    public static func vertical(_ gravity: [String]?) -> String {
        guard let parts = gravity, !parts.isEmpty else { return "top" }
        if let v = parts.first(where: { ["top", "center", "bottom", "centerVertical"].contains($0) }) {
            return v == "centerVertical" ? "center" : v
        }
        return "top"
    }

    /// SwiftUI's horizontal alignment for a resolved axis. `.leading` rather
    /// than `.left` because the canon says *start*, which is RTL-aware.
    public static func horizontalAlignment(_ gravity: [String]?) -> HorizontalAlignment {
        switch horizontal(gravity) {
        case "right": return .trailing
        case "center": return .center
        default: return .leading
        }
    }

    public static func verticalAlignment(_ gravity: [String]?) -> VerticalAlignment {
        switch vertical(gravity) {
        case "bottom": return .bottom
        case "center": return .center
        default: return .top
        }
    }
}
#endif // DEBUG
