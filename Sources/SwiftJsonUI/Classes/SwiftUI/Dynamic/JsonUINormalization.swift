//
//  JsonUINormalization.swift
//  SwiftJsonUI
//
//  Helpers around the `$jui` normalization marker that `jui build`
//  ("build": {"normalizeLayouts": true}) writes into distributed layout
//  JSON:
//
//      { "$jui": { "normalized": "L1", "schemaVersion": 1 }, ... }
//
//  A layout that carries the L1 (or higher, e.g. L2) marker has already
//  had alias attribute spellings rewritten to their canonical names, so
//  consumers may take the canonical-only code path and skip alias
//  fallbacks. Raw (L0) layouts keep the legacy alias-fallback behavior.
//

import Foundation

public enum JsonUINormalization {
    /// Top-level marker key in distributed layout JSON.
    public static let markerKey = "$jui"

    public static let supportedSchemaVersion = 1

    /// `JSONDecoder.userInfo` key carrying the per-decode normalization
    /// flag down to every nested `DynamicComponent` (the marker only
    /// exists at the layout file root, but canonicalization applies to
    /// the whole tree).
    public static let decoderUserInfoKey = CodingUserInfoKey(
        rawValue: "jsonui.normalized"
    )!

    /// True when the layout root carries a normalization marker of at
    /// least L1 (L2 includes L1 canonicalization).
    public static func isCanonicalized(_ layout: [String: Any]?) -> Bool {
        guard let marker = layout?[markerKey] as? [String: Any],
              let level = marker["normalized"] as? String else {
            return false
        }
        return level == "L1" || level == "L2"
    }

    /// Read and remove the marker from a layout root dictionary.
    /// Returns whether the layout was (at least) L1-canonicalized. The
    /// marker key is always stripped so it never surfaces as an
    /// attribute (rawData, unapplied-attribute checks, ...).
    public static func consumeMarker(_ layout: inout [String: Any]) -> Bool {
        let normalized = isCanonicalized(layout)
        layout.removeValue(forKey: markerKey)
        return normalized
    }

    /// Configure a decoder so nested `DynamicComponent`s expose
    /// `isNormalized == true` and skip alias fallbacks.
    public static func apply(to decoder: JSONDecoder, normalized: Bool) {
        decoder.userInfo[decoderUserInfoKey] = normalized
    }
}
