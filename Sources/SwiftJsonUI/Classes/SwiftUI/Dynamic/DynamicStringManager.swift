//
//  DynamicStringManager.swift
//  SwiftJsonUI
//
//  Dynamic mode string localization using strings.json
//  Matches StringManagerHelper.rb behavior for correct localization key lookup.
//

import Foundation
#if DEBUG

public class DynamicStringManager {
    public static let shared = DynamicStringManager()

    /// strings.json data: { "login": { "welcome_back": "Welcome Back", ... }, ... }
    private var stringsData: [String: [String: String]] = [:]
    /// Reverse lookup: value → localization key (e.g., "Email address" → "login_email_address")
    private var valueToKey: [String: String] = [:]
    /// Key lookup: snake_case text → localization key (e.g., "welcome_back" → "login_welcome_back")
    private var textToKey: [String: String] = [:]
    private var isLoaded = false

    /// strings.json sections owned by the layout currently rendering, most
    /// specific first. A bare key like "open" exists in as many sections as
    /// declare it ({home: 営業中, store_info: 開店} in a downstream app), and the
    /// flat maps above resolve it by dictionary iteration order — i.e. by
    /// chance. The codegen face resolves through the layout's OWN section
    /// (StringManagerHelper.current_namespaces), and the UIKit face through
    /// SJUIViewCreator.currentFilePrefix; this is the SwiftUI-dynamic
    /// equivalent, set by DynamicView as each layout's body renders
    /// (a downstream home screen tab rendered 開店 for home's 営業中, 2026-08-10).
    private var currentNamespaces: [String] = []

    private init() {}

    /// Announce the layout about to render. Accepts the layout name as the
    /// loader spells it; both the path-flattened and basename spellings are
    /// candidates, matching StringManagerCore.namespace_candidates.
    public func beginLayout(_ name: String) {
        func sanitized(_ s: String) -> String {
            return s.lowercased().replacingOccurrences(
                of: "[^a-z0-9]", with: "_", options: .regularExpression
            )
        }
        var candidates: [String] = []
        let base = (name as NSString).lastPathComponent
        if base != name {
            candidates.append(sanitized(base))
        }
        candidates.append(sanitized(name))
        currentNamespaces = candidates
    }

    /// Load strings.json from Layouts/Resources directory
    public func loadIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true

        let layoutDir = JSONLayoutLoader.getLayoutFileDirPath()
        let stringsPath = "\(layoutDir)/Resources/strings.json"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: stringsPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback to bundle
            if let bundleURL = Bundle.main.url(forResource: "strings", withExtension: "json"),
               let data = try? Data(contentsOf: bundleURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                parseStringsJSON(json)
            }
            return
        }
        parseStringsJSON(json)
    }

    internal func parseStringsJSON(_ json: [String: Any]) {
        // Preferred language for resolving `{en, ja, ...}` language-map entries
        // inside strings.json. Falls back to "en" so value→key lookups still
        // work when the device language isn't represented.
        let preferredLang = Bundle.main.preferredLocalizations.first ?? "en"

        for (fileName, fileObject) in json {
            guard let entries = fileObject as? [String: Any] else { continue }

            var flatStrings: [String: String] = [:]
            for (key, raw) in entries {
                let localizationKey = "\(fileName)_\(key)"
                // Always record the snake_case key → localization key mapping
                // even when we can't recover a concrete string value, because
                // `.localized()` resolves the real translation through
                // Localizable.strings (R.string on Kotlin). This is the
                // mapping responsible for turning "section_composition" into
                // "item_detail_section_composition" before NSLocalizedString.
                textToKey[key] = localizationKey

                // Extract a representative string value. Plain primitives
                // (legacy schema) are used as-is; `{en, ja, ...}` language
                // maps contribute their preferred-locale entry plus any
                // other locale as value→key fallbacks.
                if let stringValue = raw as? String {
                    flatStrings[key] = stringValue
                    if valueToKey[stringValue] == nil {
                        valueToKey[stringValue] = localizationKey
                    }
                } else if let langMap = raw as? [String: String] {
                    let primary = langMap[preferredLang] ?? langMap["en"] ?? langMap.values.first
                    if let primary = primary {
                        flatStrings[key] = primary
                    }
                    for (_, localized) in langMap {
                        if valueToKey[localized] == nil {
                            valueToKey[localized] = localizationKey
                        }
                    }
                }
            }
            stringsData[fileName] = flatStrings
        }
        Logger.debug("[DynamicStringManager] Loaded strings.json: \(stringsData.count) files, \(valueToKey.count) value mappings, \(textToKey.count) key mappings")
    }

    /// Resolve text to localized string (matches StringManagerHelper.rb logic)
    public func localize(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        loadIfNeeded()

        // 0. The rendering layout's own sections win, key or value — the
        //    same ownership order the codegen face applies. Only then do the
        //    flat (iteration-order) maps get a say.
        for ns in currentNamespaces {
            guard let section = stringsData[ns] else { continue }
            if section[text] != nil {
                return "\(ns)_\(text)".localized()
            }
            if let key = section.first(where: { $0.value == text })?.key {
                return "\(ns)_\(key)".localized()
            }
        }

        // 1. A text that IS a declared strings.json key resolves as that key,
        //    before the value reverse-lookup or any spelling heuristic:
        //    membership in the SSoT is what makes something a key, not how it
        //    is spelled. The extractor truncates long ASCII text to 31 chars,
        //    which can leave a trailing underscore
        //    ("dont_have_an_account_apply_for_") — a spelling the snake_case
        //    gate below rejects, and the value lookup can be poisoned by a
        //    legacy entry whose VALUE is that raw key, so this label rendered
        //    its key on the dynamic face while codegen resolved it
        //    (a downstream login screen, 2026-08-09). KJUI's ResourceCache.resolveString
        //    has always been key-first; this aligns the faces.
        if let key = textToKey[text] {
            return key.localized()
        }

        // 2. Try lookup by value (e.g., "Email address" → "login_email_address")
        if let key = valueToKey[text] {
            return key.localized()
        }

        // 3. Undeclared snake_case-shaped text falls back to NSLocalizedString
        if isSnakeCase(text) {
            return text.localized()
        }

        // 4. Non-snake_case, not found in strings.json → return as-is
        return text
    }

    /// Reload strings.json (call after hot reload updates)
    public func reload() {
        isLoaded = false
        stringsData.removeAll()
        valueToKey.removeAll()
        textToKey.removeAll()
        currentNamespaces.removeAll()
    }

    /// Test seam: replace the loaded table wholesale, bypassing file I/O.
    internal func loadStrings(fromParsed json: [String: Any]) {
        reload()
        isLoaded = true
        parseStringsJSON(json)
    }

    private func isSnakeCase(_ text: String) -> Bool {
        // Same spelling the extractor's should_extract_string? skips
        // (string_manager_core.rb), trailing underscore included — the
        // extractor emits truncation keys like "…_apply_for_" and every
        // resolver must accept what the extractor produces.
        let pattern = "^[a-z][a-z0-9]*(_[a-z0-9]+)*_?$"
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Convenience extension for Dynamic mode localization
public extension String {
    /// Localize using DynamicStringManager (strings.json lookup + NSLocalizedString)
    func dynamicLocalized() -> String {
        return DynamicStringManager.shared.localize(self)
    }
}
#endif // DEBUG
