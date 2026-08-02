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
//   4. Collection data supply — every layout `data` entry declared with
//      `class: "CollectionDataSource"` is materialized into a real
//      SwiftJsonUI.CollectionDataSource and exposed under its name, because
//      CollectionConverter resolves `items: "@{prop}"` via
//      `data[prop] as? CollectionDataSource` — a raw defaultValue dictionary
//      never survives that cast. The host plays the consumer ViewModel's
//      role here, generically (F4 Phase 2 prerequisite). This channel is
//      independent of the manifest `state` block: Collection fixtures are
//      static, not interactive.
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
    /// Requirement 4: materialized `class: "CollectionDataSource"` entries
    /// from the layout data section, keyed by declared name. Static data —
    /// never mutated after init, so no @Published needed.
    private let collectionData: [String: CollectionDataSource]

    init(fixtureId: String) {
        let decl = ConformanceStateIndex.state(for: fixtureId)
        self.decl = decl

        let dataEntries = Self.dataSectionEntries(fixtureId: fixtureId)
        self.collectionData = Self.collectionDataSources(from: dataEntries)

        guard let decl else { return }

        // Requirement 1: initial values from the layout data section
        // (production defaults path), manifest defaultValue as fallback.
        let layoutDefaults = Self.dataSectionDefaults(from: dataEntries)
        var seeded: [String: String] = [:]
        for varDecl in decl.vars {
            seeded[varDecl.name] = layoutDefaults[varDecl.name] ?? varDecl.defaultValue
        }
        self.values = seeded
    }

    /// External data for DynamicView: one CollectionDataSource per declared
    /// collection entry (requirement 4 — supplied for static fixtures too),
    /// one Binding<String> per declared var (requirements 1 + 3) and one
    /// `() -> Void` closure per declared handler (requirement 2). On a name
    /// collision the interactive var wins — a declared var is the more
    /// specific intent.
    var externalData: [String: Any] {
        var out: [String: Any] = [:]
        for (name, source) in collectionData {
            out[name] = source
        }
        guard let decl else { return out }
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

    /// Read the fixture layout's root-level `data` section — the identical
    /// source DynamicView.mergeDataDefaults extracts defaults from at render
    /// time. Parsed once per fixture; both the var defaults (requirement 1)
    /// and the collection supply (requirement 4) feed from it.
    private static func dataSectionEntries(fixtureId: String) -> [[String: Any]] {
        guard let url = FixtureLoader.layoutURL(fixtureId: fixtureId),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else {
            return []
        }
        return entries
    }

    private static func dataSectionDefaults(from entries: [[String: Any]]) -> [String: String] {
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

    /// Requirement 4: `{"name": N, "class": "CollectionDataSource",
    /// "defaultValue": ...}` entries become real CollectionDataSource values.
    /// Two accepted defaultValue shapes (INTERACTIVE_HOST_CONTRACT.md §4):
    ///   - `[ {...}, ... ]` — shorthand: one section holding these cell dicts
    ///   - `{"sections": [{"cell": name?, "cells": [ {...}, ... ]}, ...]}`
    /// The dynamic renderer takes each cell's view name from the Collection
    /// node's own `sections` declaration, so the per-section `cell` here is
    /// carried only for tuple fidelity (UIKit-path readers use it).
    private static func collectionDataSources(
        from entries: [[String: Any]]
    ) -> [String: CollectionDataSource] {
        var out: [String: CollectionDataSource] = [:]
        for entry in entries {
            guard let name = entry["name"] as? String,
                  (entry["class"] as? String) == "CollectionDataSource",
                  let defaultValue = entry["defaultValue"] else { continue }
            out[name] = materializeCollection(defaultValue)
        }
        return out
    }

    private static func materializeCollection(_ raw: Any) -> CollectionDataSource {
        var source = CollectionDataSource()
        if let cells = raw as? [[String: Any]] {
            var section = CollectionDataSection()
            section.setCells(viewName: "", data: cells)
            source.addSection(section)
            return source
        }
        guard let dict = raw as? [String: Any],
              let sections = dict["sections"] as? [[String: Any]] else {
            return source
        }
        for sectionRaw in sections {
            var section = CollectionDataSection()
            section.setCells(
                viewName: sectionRaw["cell"] as? String ?? "",
                data: sectionRaw["cells"] as? [[String: Any]] ?? []
            )
            source.addSection(section)
        }
        return source
    }
}
