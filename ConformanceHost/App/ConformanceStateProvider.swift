//
//  ConformanceStateProvider.swift
//  ConformanceHost
//
//  The ONE generic state mechanism this host implements for every
//  `class: interactive` conformance fixture — the iOS implementation of
//  conformance/INTERACTIVE_HOST_CONTRACT.md. No fixture-specific code
//  exists anywhere in the host (host effort must not scale with fixture
//  count).
//
//  Contract (3 requirements):
//   1. Initial values — every `state.vars` entry is provisioned with its
//      defaultValue before first render, from the fixture layout's `data`
//      section (the same source DynamicView.mergeDataDefaults reads — the
//      production Dynamic-mode path). The manifest declaration is only the
//      fallback if a var is missing from the layout data section.
//   2. Handlers — every `state.handlers` entry becomes a `() -> Void`
//      closure in the data dictionary under its name. Invoking it sets the
//      single variable `set.var` to the literal `set.value`; any callback
//      payload is ignored (DynamicEventHelper.call/callWithValue fall back
//      to the `() -> Void` shape for every callback signature).
//   3. Two-way write-back — every var is exposed as a SwiftUI.Binding<String>
//      (per DynamicBindingHelper.string), so `text: "@{var}"` on
//      TextField/TextView writes edits back and mirror Labels re-render.
//
//  Re-render: the store is an ObservableObject; any var mutation (handler
//  fire or input write-back) publishes and the observing FixtureScreen
//  rebuilds DynamicView with the fresh values.
//

import SwiftUI
import SwiftJsonUI

// MARK: - Manifest `state` declaration (subset of manifest.json)

struct ConformanceStateDecl: Decodable {
    struct Var: Decodable {
        let name: String
        let defaultValue: String
    }

    struct Handler: Decodable {
        struct SetOp: Decodable {
            let `var`: String
            let value: String
        }
        /// Second handler kind (INTERACTIVE_HOST_CONTRACT.md): drive an
        /// isolated embed's private stack through EmbedNavigatorRegistry.
        struct EmbedOp: Decodable {
            let id: String
            let action: String
            let screen: String?
            let params: [String: String]?
        }
        let name: String
        let set: SetOp?
        let embed: EmbedOp?
    }

    let vars: [Var]
    let handlers: [Handler]
}

/// fixture id -> manifest data (state declaration, layout path), parsed once
/// from the bundled manifest.
enum ConformanceStateIndex {
    private struct Manifest: Decodable {
        struct Fixture: Decodable {
            let id: String
            let layout: String
            let state: ConformanceStateDecl?
        }
        let fixtures: [Fixture]
    }

    private static let fixtures: [String: Manifest.Fixture] = {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else {
            return [:]
        }
        var out: [String: Manifest.Fixture] = [:]
        for fixture in manifest.fixtures {
            out[fixture.id] = fixture
        }
        return out
    }()

    static func state(for fixtureId: String) -> ConformanceStateDecl? {
        fixtures[fixtureId]?.state
    }

    /// The manifest-declared layout path (relative to the conformance dir,
    /// e.g. "fixtures/common/onClick__callback_fire_2.layout.json").
    /// NOT always derivable from the id: the generator appends `_N` when two
    /// fixture ids collide case-insensitively (onclick vs onClick).
    static func layoutPath(for fixtureId: String) -> String? {
        fixtures[fixtureId]?.layout
    }
}

// MARK: - Generic state store

final class ConformanceStateStore: ObservableObject {
    @Published private var values: [String: String] = [:]
    private let decl: ConformanceStateDecl?

    init(fixtureId: String) {
        let decl = ConformanceStateIndex.state(for: fixtureId)
        self.decl = decl
        guard let decl else { return }

        // Requirement 1: initial values from the layout data section
        // (production defaults path), manifest defaultValue as fallback.
        let layoutDefaults = Self.dataSectionDefaults(fixtureId: fixtureId)
        var seeded: [String: String] = [:]
        for varDecl in decl.vars {
            seeded[varDecl.name] = layoutDefaults[varDecl.name] ?? varDecl.defaultValue
        }
        self.values = seeded
    }

    /// External data for DynamicView: one Binding<String> per declared var
    /// (requirements 1 + 3) and one `() -> Void` closure per declared
    /// handler (requirement 2). Empty for non-interactive fixtures, so
    /// DynamicView.mergeDataDefaults alone drives static rendering.
    var externalData: [String: Any] {
        guard let decl else { return [:] }
        var out: [String: Any] = [:]
        for varDecl in decl.vars {
            let name = varDecl.name
            out[name] = SwiftUI.Binding<String>(
                get: { [weak self] in self?.values[name] ?? "" },
                set: { [weak self] newValue in self?.values[name] = newValue }
            )
        }
        for handler in decl.handlers {
            if let embedOp = handler.embed {
                let closure: () -> Void = {
                    guard let navigator = EmbedNavigatorRegistry.shared.navigator(for: embedOp.id) else {
                        return
                    }
                    switch embedOp.action {
                    case "push":
                        guard let screen = embedOp.screen else { return }
                        navigator.push(screen: screen, params: embedOp.params ?? [:])
                    case "pop":
                        navigator.pop()
                    default:
                        break
                    }
                }
                out[handler.name] = closure
                continue
            }
            guard let setOp = handler.set else { continue }
            let varName = setOp.var
            let literal = setOp.value
            let closure: () -> Void = { [weak self] in
                self?.values[varName] = literal
            }
            out[handler.name] = closure
        }
        return out
    }

    /// Read the `data` section defaults straight from the fixture layout
    /// JSON — the identical source DynamicView.mergeDataDefaults extracts
    /// defaults from at render time.
    private static func dataSectionDefaults(fixtureId: String) -> [String: String] {
        guard let url = FixtureLoader.layoutURL(fixtureId: fixtureId),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else {
            return [:]
        }
        var out: [String: String] = [:]
        for entry in entries {
            guard let name = entry["name"] as? String else { continue }
            if let defaultValue = entry["defaultValue"] as? String {
                out[name] = defaultValue
            } else if let defaultValue = entry["defaultValue"] {
                out[name] = String(describing: defaultValue)
            }
        }
        return out
    }
}
