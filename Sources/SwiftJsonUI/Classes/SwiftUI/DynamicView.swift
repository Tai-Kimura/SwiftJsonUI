//
//  DynamicView.swift
//  SwiftJsonUI
//
//  Main dynamic view entry point
//

import SwiftUI
import Combine

#if DEBUG

// MARK: - Dynamic View
public struct DynamicView: View {
    @State private var refreshId = UUID()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let data: [String: Any]
    private let viewId: String
    private let jsonName: String?
    private let directComponent: DynamicComponent?

    public init(jsonName: String, viewId: String? = nil, data: [String: Any] = [:]) {
        self.jsonName = jsonName
        self.data = data
        self.viewId = viewId ?? jsonName
        self.directComponent = nil
    }

    public init(component: DynamicComponent, viewId: String? = nil, data: [String: Any] = [:]) {
        self.jsonName = nil
        self.directComponent = component
        self.data = data
        self.viewId = viewId ?? "component"
    }

    /// Load component from cache or disk - called in body to get fresh data after HotLoader updates.
    /// When a JSON layout contains `responsive` blocks, resolution is performed at
    /// the dictionary level using the current size classes BEFORE decoding into
    /// DynamicComponent, so individual converters remain unaware of responsive logic.
    private var rootComponent: DynamicComponent? {
        if let component = directComponent {
            return component
        }
        if let name = jsonName {
            // Try loading the processed JSON dictionary so we can resolve
            // responsive overrides based on the current size class environment.
            if let processedJSON = JSONLayoutLoader.loadProcessedJSON(named: name) {
                if ResponsiveResolver.jsonContainsResponsive(processedJSON) {
                    let resolver = ResponsiveResolver(
                        horizontalSizeClass: horizontalSizeClass,
                        verticalSizeClass: verticalSizeClass
                    )
                    let resolvedJSON = resolver.resolveTree(processedJSON)
                    return JSONLayoutLoader.decodeComponent(from: resolvedJSON)
                }
            }
            // Fallback: no responsive blocks, use the standard cached component path
            return JSONLayoutLoader.loadComponent(named: name)
        }
        return nil
    }

    @ViewBuilder
    public var body: some View {
        let _ = Logger.debug("[DynamicView] body called for: \(jsonName ?? "unknown")")
        if let component = rootComponent {
            let mergedData = DynamicView.mergeDataDefaults(component: component, externalData: data)
            DynamicComponentBuilder(
                component: component,
                data: mergedData,
                viewId: viewId
            )
            .id(refreshId)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("layoutFileDidChanged"))) { _ in
                DynamicStringManager.shared.reload()
                refreshId = UUID()
            }
        } else {
            Text("Failed to load: \(jsonName ?? "unknown")")
                .foregroundColor(.gray)
        }
    }

    /// Extract defaultValue entries from the JSON data section and merge with external data.
    /// External data takes priority over defaults (matching generated code behavior where
    /// Data struct properties have default values that can be overridden).
    ///
    /// The data section comes in two shapes:
    /// - canonical: `"data": [ {name, class, defaultValue} ]` directly on the
    ///   root node (what codegen layouts and `jui conformance generate` emit)
    /// - legacy dynamic: a type-less child element carrying only a data array
    /// Both are read; the root-level array wins on duplicate names.
    /// (KotlinJsonUI's applyDataSectionDefaults had the same child-only scan
    /// bug — see docs/bugs 2026-07-02 root-level data section defaults.)
    private static func mergeDataDefaults(component: DynamicComponent, externalData: [String: Any]) -> [String: Any] {
        var dataEntries: [AnyCodable] = []

        // Legacy shape: data section child (no type, has data array)
        if let children = component.childComponents {
            Logger.debug("[DynamicView:mergeDefaults] children count=\(children.count), types=\(children.map { $0.type ?? "(nil)" })")
            if let dataChild = children.first(where: { $0.type == nil && $0.data != nil }),
               let childEntries = dataChild.data {
                dataEntries.append(contentsOf: childEntries)
            }
        }

        // Canonical shape: data array on the node itself (appended last so
        // root-level entries win on duplicate names)
        if let rootEntries = component.data {
            dataEntries.append(contentsOf: rootEntries)
        }

        guard !dataEntries.isEmpty else {
            Logger.debug("[DynamicView:mergeDefaults] No data section found (root-level or data-only child)")
            return externalData
        }

        var merged = [String: Any]()
        var defaultCount = 0

        // Extract default values from data section
        for entry in dataEntries {
            guard let dict = entry.value as? [String: Any],
                  let name = dict["name"] as? String else {
                Logger.debug("[DynamicView:mergeDefaults] Skipping entry: value type=\(type(of: entry.value))")
                continue
            }

            if let defaultValue = dict["defaultValue"] {
                merged[name] = defaultValue
                defaultCount += 1
            }
        }

        Logger.debug("[DynamicView:mergeDefaults] Extracted \(defaultCount) defaults from \(dataEntries.count) data entries")

        // Log visibility-related defaults
        let visibilityDefaults = merged.filter { $0.key.lowercased().contains("visibility") }
        if !visibilityDefaults.isEmpty {
            Logger.debug("[DynamicView:mergeDefaults] Visibility defaults: \(visibilityDefaults)")
        }

        // External data overrides defaults
        let externalVisibility = externalData.filter { $0.key.lowercased().contains("visibility") }
        if !externalVisibility.isEmpty {
            Logger.debug("[DynamicView:mergeDefaults] External visibility overrides: \(externalVisibility)")
        }

        for (key, value) in externalData {
            merged[key] = value
        }

        Logger.debug("[DynamicView:mergeDefaults] Final merged keys count=\(merged.count)")
        let finalVisibility = merged.filter { $0.key.lowercased().contains("visibility") }
        if !finalVisibility.isEmpty {
            Logger.debug("[DynamicView:mergeDefaults] Final visibility values: \(finalVisibility)")
        }

        return merged
    }
}

// MARK: - Preview Helper
public struct DynamicViewPreview: View {
    let jsonName: String

    public init(jsonName: String) {
        self.jsonName = jsonName
    }

    public var body: some View {
        DynamicView(jsonName: jsonName)
            .onAppear {
                #if DEBUG
                HotLoader.instance.isHotLoadEnabled = true
                #endif
            }
    }
}

// MARK: - Force re-evaluation when data dictionary changes
// Dictionary<String, Any> doesn't conform to Equatable, so SwiftUI's internal
// comparison may fail to detect changes. Always returning false ensures body
// is re-evaluated whenever the parent re-renders with new data.
extension DynamicView: Equatable {
    public static func == (lhs: DynamicView, rhs: DynamicView) -> Bool { false }
}
#endif // DEBUG
