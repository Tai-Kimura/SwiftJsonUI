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
//    medium              -> compact's condition (iOS has no medium size class)
//    medium-landscape    -> compact-landscape's condition
//
//  One key wins, alone: the first of jsonui-cli's PRIORITY_ORDER
//  (shared/core/responsive_resolver.rb) that is in the block and holds —
//    regular-landscape > medium-landscape > compact-landscape > landscape
//    > regular > medium > compact > default (no overrides)
//  Until 10.29.12 this resolver had no medium-landscape and tried
//  compact-landscape first (sjui-dynamic-responsive-ignores-medium-landscape).
//
//  Window-width conditions (jui-responsive-width-threshold-conditions): a
//  block of `minWidth:N` (window width >= N) / `maxWidth:N` (< N) keys and no
//  size class. The smallest maxWidth that holds wins, else the largest
//  minWidth. The width is the window's (SJUIWindowWidth), in points.
//  shared/core/responsive_resolution_vectors.json holds the cases
//  (ResponsiveResolverVectorTests).
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

    /// The window's width in points, for `minWidth:N` / `maxWidth:N`; nil
    /// when unknown, and then no width condition holds.
    public let windowWidth: CGFloat?

    public init(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        windowWidth: CGFloat? = nil
    ) {
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
        self.windowWidth = windowWidth
    }

    /// jsonui-cli shared/core/responsive_resolver.rb PRIORITY_ORDER.
    static let priorityOrder = [
        "regular-landscape", "medium-landscape", "compact-landscape",
        "landscape", "regular", "medium", "compact"
    ]

    /// A width condition: `minWidth:N` / `maxWidth:N`, N a whole number
    /// without a leading zero (responsive_resolver.rb WIDTH_CONDITION).
    struct WidthCondition: Equatable {
        enum Kind: Equatable { case min, max }
        let kind: Kind
        let value: Int

        init?(_ key: String) {
            let parts = key.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return nil }
            switch parts[0] {
            case "minWidth": kind = .min
            case "maxWidth": kind = .max
            default: return nil
            }
            let digits = parts[1]
            guard !digits.isEmpty, digits.allSatisfy({ ("0"..."9").contains($0) }),
                  digits == "0" || digits.first != "0",
                  let value = Int(digits) else { return nil }
            self.value = value
        }

        func holds(at width: CGFloat) -> Bool {
            kind == .min ? width >= CGFloat(value) : width < CGFloat(value)
        }
    }

    /// Whether a size-class key holds for these size classes.
    func holds(sizeClass key: String) -> Bool {
        let isCompact = horizontalSizeClass == .compact
        let isRegular = horizontalSizeClass == .regular
        let isLandscape = verticalSizeClass == .compact
        switch key {
        case "regular-landscape": return isRegular && isLandscape
        case "medium-landscape", "compact-landscape": return isCompact && isLandscape
        case "landscape": return isLandscape
        case "regular": return isRegular
        case "medium", "compact": return isCompact
        default: return false
        }
    }

    /// The key that wins in `responsive`, or nil (the base is drawn).
    func winningKey(in responsive: [String: [String: Any]]) -> String? {
        let keys = Array(responsive.keys)
        let widthKeys = keys.compactMap { key in WidthCondition(key).map { (key, $0) } }
        if !widthKeys.isEmpty && !keys.contains(where: { Self.priorityOrder.contains($0) }) {
            guard let width = windowWidth else { return nil }
            let maxes = widthKeys.filter { $0.1.kind == .max }.sorted { $0.1.value < $1.1.value }
            let mins = widthKeys.filter { $0.1.kind == .min }.sorted { $0.1.value > $1.1.value }
            return (maxes + mins).first { $0.1.holds(at: width) }?.0
        }
        return Self.priorityOrder.first { responsive[$0] != nil && holds(sizeClass: $0) }
    }

    // MARK: - Public API

    /// Walk the entire JSON tree and resolve every `responsive` block found.
    /// Returns a new dictionary tree with overrides merged and `responsive`
    /// keys removed.
    public func resolveTree(_ json: [String: Any]) -> [String: Any] {
        // The node's own block first, then — before its children are
        // resolved below — the axis a ScrollView takes from its child.
        var resolved = Self.stampingScrollAxis(resolveNode(json))

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

    /// Whether any `responsive` block in the tree holds a width condition
    /// (minWidth:N / maxWidth:N) — what makes DynamicView track its window's
    /// width. The same walk as jsonContainsResponsive.
    public static func jsonContainsWidthConditions(_ json: [String: Any]) -> Bool {
        if let responsive = json["responsive"] as? [String: Any],
           responsive.keys.contains(where: { WidthCondition($0) != nil }) {
            return true
        }
        let nested = ["child", "children"].compactMap { json[$0] as? [[String: Any]] }.flatMap { $0 }
            + ((json["tabs"] as? [[String: Any]]) ?? []).flatMap { tab in
                ["child", "children"].compactMap { tab[$0] as? [[String: Any]] }.flatMap { $0 }
            }
        return nested.contains { jsonContainsWidthConditions($0) }
    }

    // MARK: - ScrollView axis

    /// Stamped on a ScrollView by `stampingScrollAxis`: its only child's
    /// orientation as written, before that child's `responsive` is resolved.
    static let scrollBaseChildOrientationKey = "_scrollBaseChildOrientation"

    /// A ScrollView with no `orientation` of its own scrolls the way its only
    /// child View is laid out — and sjui's codegen (scrollview_converter.rb)
    /// reads that child as written: the axis is fixed when the code is
    /// generated, and a `responsive` override of the child's orientation
    /// changes the stack inside, never the scroll axis. This tree is resolved
    /// before DynamicScrollViewContainer sees it, so the child it would read
    /// is the resolved one: a child that is vertical but horizontal under
    /// `regular` turned the whole screen into a sideways scroll on a regular
    /// window, its content pinned to the width of its columns
    /// (sjui-dynamic-scrollview-axis-from-resolved-child). The child's
    /// orientation is stamped here, while it is still the one written, and
    /// only when the child has a block that could change it.
    static func stampingScrollAxis(_ node: [String: Any]) -> [String: Any] {
        guard node["type"] as? String == "ScrollView", node["orientation"] == nil else { return node }
        let listed = (node["child"] as? [[String: Any]]) ?? (node["children"] as? [[String: Any]])
            ?? (node["child"] as? [String: Any]).map { [$0] } ?? []
        // The children DynamicScrollViewContainer counts: those with a type
        // or an include (a data-only entry is not drawn).
        let drawn = listed.filter { ($0["type"] as? String).map { !$0.isEmpty } ?? ($0["include"] != nil) }
        guard drawn.count == 1, let child = drawn.first,
              (child["type"] as? String)?.lowercased() == "view",
              child["responsive"] != nil else { return node }
        var stamped = node
        stamped[scrollBaseChildOrientationKey] = child["orientation"] as? String == "horizontal" ? "horizontal" : "vertical"
        return stamped
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

        // Merge overrides on top of base attributes — but `style`: an
        // override's attributes are its own, written in it, and a style named
        // there is applied by no path (4f's ruling, 1.9.0; the shared
        // validator names it). Merged, it sat on the node unapplied until a
        // second pass of the stages applied it.
        for (key, value) in matchingOverrides where key != "style" {
            result[key] = value
        }
        if matchingOverrides["style"] != nil { Self.nameStyleInOverrideOnce() }

        return result
    }

    /// The shared validator's sentence for a `style` inside a responsive
    /// override.
    static let styleInOverride = "'style' inside a responsive override is not applied — put the attributes in the override"

    /// Hook for tests / apps; defaults to Logger.debug.
    public static var warningHandler: ((String) -> Void)?
    /// Named already, this process (tests reset it).
    static var named = false
    private static let lock = NSLock()

    private static func nameStyleInOverrideOnce() {
        lock.lock()
        let first = !named
        named = true
        lock.unlock()
        guard first else { return }
        if let warningHandler { warningHandler(styleInOverride) } else { Logger.debug(styleInOverride) }
    }

    /// The winning key's override dictionary, or empty (the base as-is).
    func bestMatchingOverrides(from responsive: [String: [String: Any]]) -> [String: Any] {
        winningKey(in: responsive).flatMap { responsive[$0] } ?? [:]
    }
}

#endif // DEBUG
