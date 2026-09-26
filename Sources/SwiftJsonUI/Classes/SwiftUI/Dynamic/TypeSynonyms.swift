//
//  TypeSynonyms.swift
//  SwiftJsonUI
//
//  The type-spelling synonyms — a node `type` that is not a declared section
//  (HStack, ProgressBar, WebView, …) and the type it is drawn as.
//

import Foundation

/// The type-spelling synonyms, read from jsonui-cli's
/// `shared/core/type_synonyms.json`, vendored byte for byte as this
/// package's resource (`Resources/type_synonyms.json`; CI compares the copy
/// with the pinned jsonui-cli ref). Validation (jui_cli, the Ruby tools) and
/// the codegen converters read the same file, so no renderer holds a list of
/// its own.
///
/// A synonym draws as its `canonical` type, or as `render_as` where the
/// entry names one (CircleImage keeps its circular converter). Any other key
/// of an entry is an attribute the spelling means — HStack is a View with
/// `orientation: horizontal` — added where the node does not set it.
///
/// A type the app registers as its own component (CustomComponentRegistry)
/// is taken before this, with the node as written, and is never rewritten.
///
/// The file ships in the package's resource bundle. When it cannot be read,
/// the first lookup stops the app, naming it: drawing every synonym spelling
/// as an unknown type, quietly, is the failure this refuses.
public enum TypeSynonyms {
    /// One entry: the section that declares the spelling, what it is drawn
    /// as, and the attributes the spelling means.
    public struct Entry {
        public let canonical: String
        public let renderAs: String?
        public let implied: [String: Any]
        public var drawnAs: String { renderAs ?? canonical }
    }

    /// The vendored file in the package's resource bundle, or nil.
    static var resourceURL: URL? { Bundle.module.url(forResource: "type_synonyms", withExtension: "json") }

    /// Spelling → entry, keyed lowercase: the dispatch matches types
    /// case-insensitively, and so does this.
    public static let entries: [String: Entry] = {
        guard let url = resourceURL else {
            fatalError("SwiftJsonUI: type_synonyms.json is not in the SwiftJsonUI resource bundle. "
                + "The type-synonym table ships with the package; without it no synonym spelling "
                + "(HStack, ProgressBar, WebView, …) can be drawn as its type.")
        }
        do {
            return try parse(Data(contentsOf: url))
        } catch {
            fatalError("SwiftJsonUI: \(url.lastPathComponent) could not be read: \(error)")
        }
    }()

    /// Hook for tests / apps; defaults to Logger.debug.
    public static var warningHandler: ((String) -> Void)?

    private static var reported = Set<String>()
    private static let lock = NSLock()

    enum TableError: Error, CustomStringConvertible {
        case malformed(String)
        var description: String {
            switch self { case .malformed(let what): return what }
        }
    }

    /// The entries in [data], the vendored file.
    static func parse(_ data: Data) throws -> [String: Entry] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let synonyms = root["synonyms"] as? [String: Any] else {
            throw TableError.malformed("no `synonyms` object")
        }
        var out: [String: Entry] = [:]
        for (spelling, value) in synonyms {
            guard let entry = value as? [String: Any], let canonical = entry["canonical"] as? String else {
                throw TableError.malformed("entry `\(spelling)` has no `canonical`")
            }
            let implied = entry.filter { $0.key != "canonical" && $0.key != "render_as" }
            out[spelling.lowercased()] = Entry(
                canonical: canonical, renderAs: entry["render_as"] as? String, implied: implied)
        }
        return out
    }

    /// The type `type` is drawn as: its synonym's target, or itself.
    public static func drawnAs(_ type: String) -> String {
        entries[type.lowercased()]?.drawnAs ?? type
    }

    /// The node `raw` as drawn. For a synonym, a copy whose `type` is what it
    /// is drawn as, with the attributes its spelling means added where the
    /// node does not set them. Where the node sets one otherwise (an HStack
    /// with `orientation: vertical`), the node's value stays and a warning
    /// names both, once per spelling and value. Anything else: nil.
    public static func canonicalize(_ raw: [String: Any]) -> [String: Any]? {
        guard let type = raw["type"] as? String, let entry = entries[type.lowercased()] else {
            return nil
        }
        var drawn = raw
        drawn["type"] = entry.drawnAs
        for (key, meant) in entry.implied {
            guard let given = raw[key] else {
                drawn[key] = meant
                continue
            }
            if (given as? NSObject)?.isEqual(meant) == true { continue }
            let fingerprint = "\(type).\(key).\(given)"
            lock.lock()
            let firstTime = reported.insert(fingerprint).inserted
            lock.unlock()
            guard firstTime else { continue }
            let message = "[TypeSynonyms] \(type) means \(key) \(meant), and the node sets \(key) "
                + "\(given): drawn as \(entry.drawnAs) with \(key) \(given)"
            if let handler = warningHandler {
                handler(message)
            } else {
                Logger.debug(message)
            }
        }
        return drawn
    }

    /// Test support: forget previously reported pairs.
    public static func reset() {
        lock.lock()
        reported.removeAll()
        lock.unlock()
    }
}

#if DEBUG
extension TypeSynonyms {
    /// The type a node spelled `type` is drawn as — what classifies a node by
    /// its type asks this, so that it agrees with DynamicComponentBuilder: an
    /// app's own component as written (CustomComponentRegistry, asked first
    /// there too); else its synonym's target, then a declared alias
    /// section's canonical one (JsonUIComponentAliases). jsonui-cli's
    /// shared/core/type_synonyms.rb `drawn_type` is the same rule for the
    /// codegen. A list to compare it with holds drawn types only.
    public static func drawnType(_ type: String) -> String {
        if CustomComponentRegistry.shared.adapter(for: type) != nil { return type }
        let drawn = drawnAs(type)
        return JsonUIComponentAliases.canonical(for: drawn) ?? drawn
    }
}
#endif
