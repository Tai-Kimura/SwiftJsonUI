//
//  IncludeExpander.swift
//  SwiftJsonUI
//
//  Expands include references inline with ID prefix support for Dynamic mode
//

import Foundation

#if DEBUG

/// Module for expanding includes inline with ID prefix support
public class IncludeExpander {

    // MARK: - Singleton
    public static let shared = IncludeExpander()
    private init() {}

    // MARK: - String Helpers

    // 🔻 THE CODEGEN'S SPELLING IS THE SPELLING. An element inside an include
    // that carries an id is addressed by one id on every face (ruling U8,
    // include-child-ids-are-spelled-differently-on-each-platform), and the one
    // chosen is what the Ruby codegen writes — sjui_tools / kjui_tools
    // include_expander.rb `to_camel_case` / `combine_with_prefix`. These two
    // functions are that Ruby, answer for answer:
    // - segments split like Ruby's `split('_')`: leading and inner empty
    //   segments kept, trailing ones dropped (`_leading` → `Leading`,
    //   `a__b` → `aB`, `trailing_` → `trailing`);
    // - every segment after the first goes through `capitalize`, which
    //   LOWERCASES the rest (`verify_2FA_form` → `verify2faForm`,
    //   `clear_URL_button` → `clearUrlButton`); the first stays as written
    //   (`URL_field` → `URLField`);
    // - after a prefix only a leading `[a-z]` is raised (`sub(/^[a-z]/)`).
    // This used to keep each segment's case, and `split` dropped a leading
    // empty segment, so the dynamic ids and the codegen's differed on exactly
    // those shapes. Measured against both Ruby expanders (ruby 2.6.10).

    /// Ruby's `String#split('_')`.
    static func rubySplit(_ str: String) -> [String] {
        var parts = str.components(separatedBy: "_")
        while let last = parts.last, last.isEmpty { parts.removeLast() }
        return parts
    }

    /// Ruby's `String#capitalize` (identifiers are ASCII): the first
    /// character raised, the rest lowered.
    static func rubyCapitalize(_ part: String) -> String {
        part.prefix(1).uppercased() + part.dropFirst().lowercased()
    }

    /// Convert snake_case to camelCase
    /// e.g., "header1_title_label" -> "header1TitleLabel"
    func toCamelCase(_ str: String) -> String {
        guard str.contains("_") else { return str }
        let parts = Self.rubySplit(str)
        guard let first = parts.first else { return "" }
        return first + parts.dropFirst().map(Self.rubyCapitalize).joined()
    }

    /// Combine prefix and name in camelCase
    /// e.g., prefix="header1", name="title" -> "header1Title"
    /// e.g., prefix="header1", name="title_label" -> "header1TitleLabel"
    func combineWithPrefix(_ prefix: String?, _ name: String) -> String {
        guard let prefix = prefix else { return name }
        let camelName = toCamelCase(name)
        guard let head = camelName.unicodeScalars.first, ("a"..."z").contains(head) else {
            return prefix + camelName
        }
        return prefix + camelName.prefix(1).uppercased() + camelName.dropFirst()
    }

    // MARK: - Main Processing

    /// Process includes in JSON data, expanding them inline with ID prefixes
    /// - Parameters:
    ///   - jsonData: The JSON dictionary to process
    ///   - baseDir: Base directory for resolving include paths
    ///   - idPrefix: Optional ID prefix to apply
    /// - Returns: The processed JSON with includes expanded
    public func processIncludes(_ jsonData: [String: Any], baseDir: String, idPrefix: String? = nil) -> [String: Any] {
        var json = jsonData

        // If this component has an include, expand it
        if let includePath = json["include"] as? String {
            // Load the included JSON file
            guard let includedJSON = loadIncludedJSON(includePath, baseDir: baseDir) else {
                Logger.debug("[IncludeExpander] Failed to load include: \(includePath)")
                return json
            }

            // Get the ID prefix from the include element
            let includeId = json["id"] as? String
            let newPrefix: String?
            if let existingPrefix = idPrefix, let includeId = includeId {
                newPrefix = combineWithPrefix(existingPrefix, includeId)
            } else if let includeId = includeId {
                // camel(includeId), as the codegen does (`to_camel_case`).
                // It was the raw id, so `hero_card` + `title` gave
                // `hero_cardTitle` here and `heroCardTitle` in the codegen.
                newPrefix = toCamelCase(includeId)
            } else {
                newPrefix = idPrefix
            }

            // Merge properties from the include element (except id and include)
            var merged = includedJSON
            for (key, value) in json {
                if key == "include" || key == "id" {
                    continue
                }
                if key == "data" || key == "shared_data" {
                    // Merge data/shared_data arrays
                    if let existingArray = merged[key] as? [[String: Any]],
                       let newArray = value as? [[String: Any]] {
                        merged[key] = existingArray + newArray
                    } else {
                        merged[key] = value
                    }
                } else {
                    // Override other properties
                    merged[key] = value
                }
            }

            // Apply ID prefix and recursively process
            json = applyIdPrefix(merged, prefix: newPrefix)
            json = processIncludes(json, baseDir: baseDir, idPrefix: newPrefix)

            // Debug: Log expanded JSON
            Logger.debug("[IncludeExpander] === Include expanded: \(includePath) with prefix: \(newPrefix ?? "nil") ===")
            if let dataArray = json["data"] as? [[String: Any]] {
                Logger.debug("[IncludeExpander] Data definitions:")
                for item in dataArray {
                    if let name = item["name"] as? String {
                        Logger.debug("[IncludeExpander]   - \(name)")
                    }
                }
            }
            // Log all child elements (text and type)
            if let children = json["child"] as? [[String: Any]] {
                Logger.debug("[IncludeExpander] Children:")
                for child in children {
                    let childType = child["type"] as? String ?? "unknown"
                    let childId = child["id"] as? String ?? "no-id"
                    let childText = child["text"] as? String ?? "no-text"
                    Logger.debug("[IncludeExpander]   - type=\(childType), id=\(childId), text=\(childText)")
                }
            }

            return json
        }

        // Apply ID prefix to current element's id
        if let prefix = idPrefix, let currentId = json["id"] as? String {
            json["id"] = combineWithPrefix(prefix, currentId)
        }

        // Process child/children recursively
        if let child = json["child"] {
            if let childArray = child as? [[String: Any]] {
                json["child"] = childArray.map { processIncludes($0, baseDir: baseDir, idPrefix: idPrefix) }
            } else if let childDict = child as? [String: Any] {
                json["child"] = processIncludes(childDict, baseDir: baseDir, idPrefix: idPrefix)
            }
        }

        if let children = json["children"] {
            if let childArray = children as? [[String: Any]] {
                // Normalize children to child
                json["child"] = childArray.map { processIncludes($0, baseDir: baseDir, idPrefix: idPrefix) }
                json.removeValue(forKey: "children")
            } else if let childDict = children as? [String: Any] {
                json["child"] = processIncludes(childDict, baseDir: baseDir, idPrefix: idPrefix)
                json.removeValue(forKey: "children")
            }
        }

        return json
    }

    // MARK: - ID Prefix Application

    /// Apply ID prefix to all elements, data definitions, and @{} bindings
    func applyIdPrefix(_ jsonData: [String: Any], prefix: String?) -> [String: Any] {
        // nil only, as the codegen's `apply_id_prefix` (`&& prefix`).
        guard let prefix = prefix else { return jsonData }

        var json = jsonData

        // Apply prefix to data definitions
        if let dataArray = json["data"] as? [[String: Any]] {
            json["data"] = dataArray.map { dataItem -> [String: Any] in
                var item = dataItem
                if let name = item["name"] as? String {
                    item["name"] = combineWithPrefix(prefix, name)
                }
                return item
            }
        }

        // Transform all @{} bindings
        if let transformed = transformBindings(json, prefix: prefix) as? [String: Any] {
            json = transformed
        }

        return json
    }

    /// Transform @{variableName} to @{prefixVariableName} in all string values
    func transformBindings(_ data: Any, prefix: String) -> Any {
        if let dict = data as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                result[key] = transformBindings(value, prefix: prefix)
            }
            return result
        } else if let array = data as? [Any] {
            return array.map { transformBindings($0, prefix: prefix) }
        } else if let str = data as? String {
            // Transform @{variableName} but not @{this.xxx} or @{item.xxx}
            return transformBindingString(str, prefix: prefix)
        }
        return data
    }

    /// Transform binding expressions in a string
    func transformBindingString(_ str: String, prefix: String) -> String {
        // Pattern: @{variableName}
        let pattern = #"@\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return str
        }

        var result = str
        let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex..., in: str))

        // Process matches in reverse order to preserve indices
        for match in matches.reversed() {
            guard let varRange = Range(match.range(at: 1), in: str),
                  let fullRange = Range(match.range, in: str) else {
                continue
            }

            let varName = String(str[varRange])

            // Skip if contains dot (this.xxx, item.xxx, etc.)
            if varName.contains(".") {
                continue
            }

            let prefixedName = combineWithPrefix(prefix, varName)
            result = result.replacingCharacters(in: fullRange, with: "@{\(prefixedName)}")
        }

        return result
    }

    // MARK: - File Loading

    /// Load included JSON file from cache or bundle
    func loadIncludedJSON(_ includePath: String, baseDir: String) -> [String: Any]? {
        let fm = FileManager.default

        // Try loading from cache directory first
        let layoutFileDirPath = JSONLayoutLoader.getLayoutFileDirPath()

        // Build possible paths
        let possiblePaths = [
            "\(layoutFileDirPath)/\(includePath).json",
            "\(baseDir)/\(includePath).json"
        ]

        for path in possiblePaths {
            if fm.fileExists(atPath: path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Included files carry their own `$jui` file-root marker
                // when distributed normalized — it's metadata, not an
                // attribute of the include host
                _ = JsonUINormalization.consumeMarker(&json)
                // Apply styles to included JSON
                let processedJSON = StyleProcessor.processStyles(json)
                Logger.debug("[IncludeExpander] Loaded include from: \(path)")
                return processedJSON
            }
        }

        // Try loading from bundle
        if let data = JSONLayoutLoader.loadJSON(named: includePath),
           var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            _ = JsonUINormalization.consumeMarker(&json)
            let processedJSON = StyleProcessor.processStyles(json)
            Logger.debug("[IncludeExpander] Loaded include from bundle: \(includePath)")
            return processedJSON
        }

        Logger.debug("[IncludeExpander] Include file not found: \(includePath)")
        return nil
    }
}

#endif // DEBUG
