//
//  EmbedConverter.swift
//  SwiftJsonUI
//
//  Converts a dynamic `Embed` component to SwiftUI. Two-tier resolution
//  matching TabViewConverter:
//   1. Try CustomComponentRegistry for the screen name (compiled screens
//      register adapters that instantiate their generated View, which
//      owns its own VM via @StateObject).
//   2. Fall back to DynamicView(jsonName:) loading the embedded layout JSON.
//      In this path the embed receives ONLY the resolved params as its
//      data dict — the parent's data is intentionally NOT propagated,
//      so the embedded screen's data defaults take effect (see
//      DynamicView.mergeDataDefaults).
//
//  See jsonui-cli/docs/plans/2026-05-11-embed-feature.md for the design.
//

import SwiftUI

#if DEBUG

public struct EmbedConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any],
        viewId: String? = nil
    ) -> AnyView {
        let raw = component.rawData
        let screenName = (raw["screen"] as? String) ?? ""
        let embedId = (raw["id"] as? String) ?? (viewId ?? "embed")
        let rawMode = raw["navigationMode"] as? String
        let resolvedParams = resolveParams(raw["params"], parentData: data)
        let eventBridge = buildEventBridge(eventMap: raw["events"] as? [String: String], parentData: data)

        guard !screenName.isEmpty else {
            return AnyView(
                Text("Embed: 'screen' attribute is required")
                    .foregroundColor(.red)
            )
        }

        // Version-skew guard: an unknown navigationMode means the layout was
        // authored against a newer attribute vocabulary than this runtime.
        // Never silently degrade to delegate — surface it (same red-box
        // convention as DynamicComponentBuilder's unknown-component branch).
        guard let navigationMode = parseNavigationMode(rawMode) else {
            return AnyView(
                Text("Embed: unknown navigationMode '\(rawMode ?? "")' — update SwiftJsonUI")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
            )
        }

        var result: AnyView
        if navigationMode == .isolated {
            result = AnyView(
                EmbedContainer(
                    embedId: embedId,
                    screen: screenName,
                    params: resolvedParams,
                    navigationMode: .isolated,
                    isolatedNavigation: .automatic,
                    eventBridge: eventBridge
                ) {
                    buildEmbeddedScreen(
                        screenName: screenName,
                        embedId: embedId,
                        params: resolvedParams,
                        component: component
                    )
                }
            )
        } else {
            result = AnyView(
                EmbedContainer(
                    embedId: embedId,
                    screen: screenName,
                    params: resolvedParams,
                    navigationMode: navigationMode,
                    eventBridge: eventBridge
                ) {
                    buildEmbeddedScreen(
                        screenName: screenName,
                        embedId: embedId,
                        params: resolvedParams,
                        component: component
                    )
                }
            )
        }

        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)
        return result
    }

    /// Build an event bridge from the JSON `events: { onEventName: "parentHandlerName" }`
    /// map. Each emitted `.named(name:payload:)` looks up the handler in the
    /// parent data dict (handlers are functions / closures stored by name).
    private static func buildEventBridge(
        eventMap: [String: String]?,
        parentData: [String: Any]
    ) -> ((EmbeddedEvent) -> Void)? {
        guard let eventMap = eventMap, !eventMap.isEmpty else { return nil }
        return { event in
            guard case .named(let name, let payload) = event else { return }
            guard let handlerName = eventMap[name] else { return }
            // The parent VM exposes handlers as either ([String: Any]) -> Void
            // or () -> Void closures keyed by name in the data dict.
            if let withPayload = parentData[handlerName] as? ([String: Any]) -> Void {
                withPayload(payload)
            } else if let noArgs = parentData[handlerName] as? () -> Void {
                noArgs()
            }
        }
    }

    @ViewBuilder
    private static func buildEmbeddedScreen(
        screenName: String,
        embedId: String,
        params: [String: Any],
        component: DynamicComponent
    ) -> some View {
        // Tier 1: registered custom adapter (compiled screens)
        if let adapter = CustomComponentRegistry.shared.adapter(for: screenName) {
            adapter.buildView(
                component: component,
                data: params,
                viewId: "\(screenName)_embed_\(embedId)",
                parentOrientation: nil
            )
        } else {
            // Tier 2: dynamic fallback — load embedded layout JSON with params only.
            // Parent's `data` is intentionally NOT passed; DynamicView's
            // mergeDataDefaults will fill the rest from the layout's own data section.
            DynamicView(
                jsonName: screenName,
                viewId: "\(screenName)_embed_\(embedId)",
                data: params
            )
        }
    }

    /// nil = unknown value (version skew) — caller renders an explicit error.
    private static func parseNavigationMode(_ raw: String?) -> EmbedNavigationMode? {
        switch raw {
        case nil, "delegate": return .delegate
        case "isolated": return .isolated
        default: return nil
        }
    }

    /// Resolve `params` tree: for each leaf whose value is a @{binding} string,
    /// look up the parent data dict and substitute the bound value. Literals
    /// pass through. Intermediate nodes are literal objects (validated by the
    /// CLI: bindings are leaf-only, arrays unsupported) — recursed here so
    /// nested leaves resolve too.
    private static func resolveParams(_ raw: Any?, parentData: [String: Any]) -> [String: Any] {
        guard let dict = raw as? [String: Any] else { return [:] }
        var resolved: [String: Any] = [:]
        for (key, value) in dict {
            if let s = value as? String, s.hasPrefix("@{"), s.hasSuffix("}") {
                let prop = String(s.dropFirst(2).dropLast())
                if let bound = parentData[prop] {
                    resolved[key] = bound
                }
                // unresolved binding → key dropped (let embedded layout's defaultValue apply)
            } else if let nested = value as? [String: Any] {
                resolved[key] = resolveParams(nested, parentData: parentData)
            } else {
                resolved[key] = value
            }
        }
        return resolved
    }
}

#endif // DEBUG
