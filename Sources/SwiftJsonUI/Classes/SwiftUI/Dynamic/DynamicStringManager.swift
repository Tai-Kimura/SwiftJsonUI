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

    private init() {}

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

    private func parseStringsJSON(_ json: [String: Any]) {
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
                // mapping responsible for turning "cask_composition" into
                // "whisky_detail_cask_composition" before NSLocalizedString.
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

        // 1. Try lookup by value (e.g., "Email address" → "login_email_address")
        if let key = valueToKey[text] {
            return key.localized()
        }

        // 2. If snake_case, try lookup by key
        if isSnakeCase(text) {
            if let key = textToKey[text] {
                return key.localized()
            }
            // Fallback: try .localized() directly on the text
            return text.localized()
        }

        // 3. Non-snake_case, not found in strings.json → return as-is
        return text
    }

    /// Reload strings.json (call after hot reload updates)
    public func reload() {
        isLoaded = false
        stringsData.removeAll()
        valueToKey.removeAll()
        textToKey.removeAll()
    }

    private func isSnakeCase(_ text: String) -> Bool {
        let pattern = "^[a-z]+(_[a-z0-9]+)*$"
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
