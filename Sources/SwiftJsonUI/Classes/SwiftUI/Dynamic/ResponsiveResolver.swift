//
//  ResponsiveResolver.swift
//  SwiftJsonUI
//
//  Resolves responsive overrides in JSON layout dictionaries based on
//  the current iOS horizontal and vertical size classes.
//
//  JSON format:
//    {
//      "type": "View",
//      "orientation": "vertical",
//      "spacing": 8,
//      "responsive": {
//        "regular": { "orientation": "horizontal", "spacing": 24 },
//        "landscape": { "spacing": 16 },
//        "regular-landscape": { "orientation": "horizontal", "spacing": 32 }
//      },
//      "child": [...]
//    }
//
//  Size class mapping:
//    compact             -> horizontalSizeClass == .compact
//    regular             -> horizontalSizeClass == .regular
//    landscape           -> verticalSizeClass == .compact
//    compact-landscape   -> horizontalSizeClass == .compact && verticalSizeClass == .compact
//    regular-landscape   -> horizontalSizeClass == .regular && verticalSizeClass == .compact
//    medium              -> falls back to compact (iOS has no medium size class)
//
//  Priority (highest to lowest):
//    compound (compact-landscape, regular-landscape)
//    > landscape
//    > regular
//    > medium
//    > compact
//    > default (no overrides)
//

import SwiftUI

#if DEBUG

/// Resolves responsive overrides from a JSON layout tree based on the current
/// horizontal and vertical size classes. Operates at the dictionary level so
/// that individual component converters remain unaware of responsive logic.
public struct ResponsiveResolver {

    /// Current horizontal size class from the SwiftUI environment.
    public let horizontalSizeClass: UserInterfaceSizeClass?

    /// Current vertical size class from the SwiftUI environment.
    public let verticalSizeClass: UserInterfaceSizeClass?

    public init(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) {
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
    }

    // MARK: - Public API

    /// Walk the entire JSON tree and resolve every `responsive` block found.
    /// Returns a new dictionary tree with overrides merged and `responsive`
    /// keys removed.
    public func resolveTree(_ json: [String: Any]) -> [String: Any] {
        var resolved = resolveNode(json)

        // Recursively process "child" array
        if let children = resolved["child"] as? [[String: Any]] {
            resolved["child"] = children.map { resolveTree($0) }
        }

        // Also handle "children" alias
        if let children = resolved["children"] as? [[String: Any]] {
            resolved["children"] = children.map { resolveTree($0) }
        }

        // Process tabs (TabView children)
        if let tabs = resolved["tabs"] as? [[String: Any]] {
            resolved["tabs"] = tabs.map { tab in
                var mutableTab = tab
                if let tabChild = mutableTab["child"] as? [[String: Any]] {
                    mutableTab["child"] = tabChild.map { resolveTree($0) }
                }
                if let tabChildren = mutableTab["children"] as? [[String: Any]] {
                    mutableTab["children"] = tabChildren.map { resolveTree($0) }
                }
                return mutableTab
            }
        }

        return resolved
    }

    /// Quick check whether a JSON tree contains any `responsive` key anywhere
    /// in the hierarchy. Used to decide whether to take the responsive
    /// resolution path or the fast cached-component path.
    public static func jsonContainsResponsive(_ json: [String: Any]) -> Bool {
        if json["responsive"] != nil {
            return true
        }
        if let children = json["child"] as? [[String: Any]] {
            for child in children {
                if jsonContainsResponsive(child) { return true }
            }
        }
        if let children = json["children"] as? [[String: Any]] {
            for child in children {
                if jsonContainsResponsive(child) { return true }
            }
        }
        if let tabs = json["tabs"] as? [[String: Any]] {
            for tab in tabs {
                if let tabChild = tab["child"] as? [[String: Any]] {
                    for child in tabChild {
                        if jsonContainsResponsive(child) { return true }
                    }
                }
                if let tabChildren = tab["children"] as? [[String: Any]] {
                    for child in tabChildren {
                        if jsonContainsResponsive(child) { return true }
                    }
                }
            }
        }
        return false
    }

    // MARK: - Internal

    /// Resolve a single node: merge the best-matching responsive override
    /// into the base attributes and strip the `responsive` key.
    func resolveNode(_ json: [String: Any]) -> [String: Any] {
        guard let responsive = json["responsive"] as? [String: [String: Any]] else {
            return json
        }

        // Determine the matching key based on current size classes
        let matchingOverrides = bestMatchingOverrides(from: responsive)

        // Start from the base JSON (without `responsive`)
        var result = json
        result.removeValue(forKey: "responsive")

        // Merge overrides on top of base attributes
        for (key, value) in matchingOverrides {
            result[key] = value
        }

        return result
    }

    /// Determine the best-matching override dictionary from the responsive
    /// block, following the priority order:
    ///   compound > landscape > regular > medium > compact > (none)
    func bestMatchingOverrides(from responsive: [String: [String: Any]]) -> [String: Any] {
        let isCompact = horizontalSizeClass == .compact
        let isRegular = horizontalSizeClass == .regular
        let isLandscape = verticalSizeClass == .compact

        // Priority 1: Compound keys (most specific)
        if isCompact && isLandscape, let overrides = responsive["compact-landscape"] {
            return overrides
        }
        if isRegular && isLandscape, let overrides = responsive["regular-landscape"] {
            return overrides
        }

        // Priority 2: Landscape (verticalSizeClass == .compact)
        if isLandscape, let overrides = responsive["landscape"] {
            return overrides
        }

        // Priority 3: Regular (horizontalSizeClass == .regular)
        if isRegular, let overrides = responsive["regular"] {
            return overrides
        }

        // Priority 4: Medium (falls back to compact on iOS)
        if isCompact, let overrides = responsive["medium"] {
            return overrides
        }

        // Priority 5: Compact (horizontalSizeClass == .compact)
        if isCompact, let overrides = responsive["compact"] {
            return overrides
        }

        // No match -- return empty (use base attributes as-is)
        return [:]
    }
}

#endif // DEBUG
