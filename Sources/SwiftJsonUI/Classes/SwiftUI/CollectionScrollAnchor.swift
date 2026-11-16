//
//  CollectionScrollAnchor.swift
//  SwiftJsonUI
//
//  Where a Collection's scrollTo target lands, from a BOUND scrollAnchor
//  (`"scrollAnchor": "@{prop}"`, jsonui-cli 1.9.29,
//  jui-collection-scrollto-per-request-anchor). sjui's generated code calls
//  it inside the `.onChange(of:)` the scrollTo value keys, and the Dynamic
//  Collection with the value of the render that changed the scrollTo value
//  — so the anchor a request lands by is the bound value at that moment,
//  and a change of the anchor alone scrolls nothing.
//
//  Outside `#if DEBUG`: generated code uses it in every configuration.
//

import SwiftUI

public enum CollectionScrollAnchor {
    /// The UnitPoint the SSoT's Collection.scrollAnchor names along the
    /// scroll axis: top — the target's leading edge at the viewport's;
    /// center — its middle at the middle; bottom — its trailing edge at the
    /// trailing edge. On a horizontal Collection those are `.leading` /
    /// `.center` / `.trailing`. Anything else lands as bottom, and a DEBUG
    /// build says so, naming the Collection.
    public static func point(_ value: String?, horizontal: Bool, collection: String = "") -> UnitPoint {
        switch value {
        case "top": return horizontal ? .leading : .top
        case "center": return .center
        case "bottom": return horizontal ? .trailing : .bottom
        default:
            warnOnce(value, collection: collection)
            return horizontal ? .trailing : .bottom
        }
    }

    /// Test hook: receives every warning a DEBUG build gives.
    public static var warningSink: ((String) -> Void)?

    private static var warned = Set<String>()
    private static let lock = NSLock()

    /// Test hook: forget which (Collection, value) pairs were named.
    public static func resetForTest() {
        lock.lock(); warned.removeAll(); lock.unlock()
    }

    /// Once per (Collection, value), in a DEBUG build only: the Dynamic
    /// Collection resolves its anchor on every render.
    private static func warnOnce(_ value: String?, collection: String) {
        #if DEBUG
        let name = collection.isEmpty ? "(unnamed)" : collection
        let raw = value ?? "nil"
        lock.lock()
        let first = warned.insert("\(name):\(raw)").inserted
        lock.unlock()
        guard first else { return }
        let message = "Collection \(name): scrollAnchor \"\(raw)\" is not top, center or bottom — lands as bottom"
        warningSink?(message)
        Logger.debug(message)
        #endif
    }
}
