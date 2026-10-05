//
//  DirectionStart.swift
//  SwiftJsonUI
//
//  Where a reversed stack starts.
//
//  `direction: bottomToTop` stacks from the BOTTOM edge — the first child is
//  the lowest, each next one above it — and `rightToLeft` from the right edge,
//  the first child the rightmost (user ruling 2026-10-05, attribute_semantics
//  stackDirection; rightToLeft is the same reading turned sideways). The
//  children were reversed and then laid from the top / the left, so in a
//  200-high column of six 40s the first child sat at 200, past the bottom
//  edge, where it belongs at 160 (measured in the conformance host's pixels,
//  View/direction__bottomtotop and __righttoleft). A gravity that names the
//  main axis still decides it; with none, the main axis starts at the edge
//  the direction starts from.
//

import SwiftUI

enum DirectionStart {
    private static let verticalWords: Set<String> = ["top", "center", "bottom", "centerVertical"]
    private static let horizontalWords: Set<String> = ["left", "center", "right", "centerHorizontal", "start", "end"]

    /// "bottom" / "right" when the stack is reversed along its orientation
    /// and its gravity does not name that axis; nil otherwise.
    static func edge(direction: String?, orientation: String?, gravity: [String]?) -> String? {
        let parts = gravity ?? []
        switch (direction?.lowercased(), orientation?.lowercased()) {
        case ("bottomtotop", "vertical"):
            return parts.contains(where: verticalWords.contains) ? nil : "bottom"
        case ("righttoleft", "horizontal"):
            return parts.contains(where: horizontalWords.contains) ? nil : "right"
        default:
            return nil
        }
    }

    static func edge(of component: DynamicComponent) -> String? {
        edge(direction: component.direction, orientation: component.orientation, gravity: component.gravity)
    }

    /// The frame alignment with its main axis moved to the start edge.
    static func alignment(_ alignment: Alignment, component: DynamicComponent) -> Alignment {
        switch edge(of: component) {
        case "bottom": return Alignment(horizontal: alignment.horizontal, vertical: .bottom)
        case "right": return Alignment(horizontal: .trailing, vertical: alignment.vertical)
        default: return alignment
        }
    }
}
