//
//  TestBridgeFixture.swift
//  ConformanceHost
//
//  INTERACTIVE_HOST_CONTRACT.md §6 (testBridge), the Dynamic face: a fixture
//  rendered through DynamicView directly has no generated Data, so the host
//  attaches the library's bridge itself over a typed store made from the
//  manifest's `testBridge.data`, and judges each value with the library's
//  check (JsonUITestValue) — the same function the generated code calls.
//  The codegen face needs none of this: its generated view carries the bridge.
//

import SwiftUI
import SwiftJsonUI

/// A fixture's `testBridge` entry: the typed Data it declares.
struct TestBridgeDecl {
    struct Field {
        let name: String
        let declaredClass: String
        let defaultValue: Any
    }
    let fields: [Field]

    /// The screen id this face gives the fixture's screen — the key of its
    /// payload (job 1) and the screen `state` reads (job 3). The UITest
    /// spells it the same way.
    static func screenId(for fixtureId: String) -> String {
        "conformance_\(FixtureLoader.markerSafe(fixtureId))"
    }
}

enum TestBridgeIndex {
    /// `testBridge` per fixture id, read once from the bundled manifest with
    /// JSONSerialization: its defaults are typed (Int, Bool, null).
    private static let decls: [String: TestBridgeDecl] = {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fixtures = root["fixtures"] as? [[String: Any]] else { return [:] }
        var out: [String: TestBridgeDecl] = [:]
        for fixture in fixtures {
            guard let id = fixture["id"] as? String,
                  let bridge = fixture["testBridge"] as? [String: Any] else { continue }
            let fields = (bridge["data"] as? [[String: Any]] ?? []).compactMap { entry -> TestBridgeDecl.Field? in
                guard let name = entry["name"] as? String, let klass = entry["class"] as? String else { return nil }
                return TestBridgeDecl.Field(name: name, declaredClass: klass, defaultValue: entry["defaultValue"] ?? NSNull())
            }
            out[id] = TestBridgeDecl(fields: fields)
        }
        return out
    }()

    static func decl(for fixtureId: String) -> TestBridgeDecl? { decls[fixtureId] }
}

/// The typed Data of a testBridge fixture on the Dynamic face. Recreated with
/// the fixture view (a remount makes a new one, at its defaults).
final class TestBridgeFixtureStore: ObservableObject {
    @Published private(set) var values: [String: Any]
    let decl: TestBridgeDecl

    init(decl: TestBridgeDecl) {
        self.decl = decl
        self.values = Dictionary(uniqueKeysWithValues: decl.fields.map { ($0.name, $0.defaultValue) })
    }

    /// The bridge's apply: each key judged by the library's check against
    /// the class the fixture declares.
    func apply(_ input: [String: Any]) -> [JsonUIRejectedKey] {
        var rejected: [JsonUIRejectedKey] = []
        var next = values
        for (key, value) in input {
            guard let field = decl.fields.first(where: { $0.name == key }) else {
                rejected.append(.notADataField(key))
                continue
            }
            switch JsonUITestValue.check(value, declaredClass: field.declaredClass) {
            case .accept(let accepted): next[key] = accepted ?? NSNull()
            case .reject(let reason): rejected.append(JsonUIRejectedKey(key: key, reason: reason))
            }
        }
        values = next
        return rejected
    }

    /// The bridge's data: every declared field, the host's String vars
    /// (ConformanceStateStore — afterFirstDraw writes there) taking
    /// precedence for the names they hold.
    func snapshot(overriding stringVars: [String: String]) -> [String: Any] {
        var out = values
        for (name, value) in stringVars where out.keys.contains(name) { out[name] = value }
        return out
    }

    /// DynamicView data for the declared fields: a Binding per String field
    /// (a label bound to it re-renders when apply writes), the plain value
    /// otherwise (read by the bridge only).
    func externalData() -> [String: Any] {
        var out: [String: Any] = [:]
        for field in decl.fields {
            let name = field.name
            if field.declaredClass.hasPrefix("String") {
                out[name] = SwiftUI.Binding<String>(
                    get: { [weak self] in self?.values[name] as? String ?? "" },
                    set: { [weak self] in self?.values[name] = $0 }
                )
            } else {
                out[name] = values[name]
            }
        }
        return out
    }
}
