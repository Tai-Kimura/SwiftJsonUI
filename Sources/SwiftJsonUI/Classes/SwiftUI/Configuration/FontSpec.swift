//
//  FontSpec.swift
//  SwiftJsonUI
//
//  Unified font resolution input passed to `SwiftJsonUIConfiguration.fontProvider`.
//  Generators (sjui_tools) collapse the JSON-level font attributes
//  (`fontFamily`, `font` (weight), `fontSize`, future `italic`) into a single
//  `FontSpec` so apps can implement one provider and control the full resolved
//  Font for every text-bearing component.
//

import SwiftUI

/// Aggregated description of the font attributes declared on a JSON layout
/// node. All fields are optional so a partial spec (e.g. weight-only,
/// family-only, size-only) can flow through the same provider entry point.
public struct FontSpec: Equatable {
    /// Font family name (e.g. `"Noto Sans JP"`). `nil` when the layout did not
    /// specify `fontFamily`.
    public let family: String?

    /// SwiftUI weight resolved by the generator from the JSON `font`/`fontWeight`
    /// string (e.g. `.bold`). `nil` when no weight was requested.
    public let weight: Font.Weight?

    /// Point size requested by the layout. `nil` when `fontSize` is absent — the
    /// resolver/provider can fall back to a configured default.
    public let size: CGFloat?

    /// Reserved for the future `italic` JSON attribute. Always `false` for now;
    /// the field exists so apps that ship custom italic faces don't need a
    /// new provider signature later.
    public let italic: Bool

    public init(family: String? = nil,
                weight: Font.Weight? = nil,
                size: CGFloat? = nil,
                italic: Bool = false) {
        self.family = family
        self.weight = weight
        self.size = size
        self.italic = italic
    }
}
