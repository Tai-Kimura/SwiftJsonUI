//
//  DataDefaultValue.swift
//  SwiftJsonUI
//
//  What a data property's `defaultValue` means in dynamic mode — the reading
//  the code generators apply (jsonui-cli `JsonUIShared::StringLiterals.default_text`
//  and `TypeConverterCore#normalize_data_property`), so a layout shows the
//  same text generated or dynamic. Measured against the same table:
//  Tests/SwiftJsonUITests/Fixtures/string_default_vectors.json, vendored
//  byte-identical from jsonui-cli `shared/core/string_default_vectors.json`
//  (StringDefaultVectorTests; the COPIES list in CI compares the copy).
//
//  Until 10.29.0 dynamic mode took the value as it stood: a `"'…'"` or
//  `"\"…\""` spelling showed its quotes, and a value written per platform
//  reached the data map as a dictionary.
//

import Foundation

enum DataDefaultValue {
    private static let language = "swift"

    // Dynamic mode renders SwiftUI; `uikit` is the codegen's other mode.
    private static let modes = ["swiftui", "uikit"]

    private static let platformLanguages: Set<String> = ["swift", "kotlin", "typescript"]

    /// The value this platform reads from `value`: the `swift` entry of a
    /// value written per platform (`{ "swift": …, "kotlin": … }`, and its
    /// `swiftui` entry when written per mode), the value itself otherwise —
    /// or nil when it is written per platform and names no `swift`.
    static func select(_ value: Any) -> Any? {
        guard let entries = value as? [String: Any] else { return value }
        if let mine = entries[language] {
            if let byMode = mine as? [String: Any] {
                for mode in modes {
                    if let chosen = byMode[mode] { return chosen }
                }
            }
            return mine
        }
        let keys = Set(entries.keys)
        return !keys.isEmpty && keys.isSubset(of: platformLanguages) ? nil : value
    }

    /// The declared class, itself possibly written per platform.
    static func className(_ declared: Any?) -> String? {
        guard let declared = declared else { return nil }
        return select(declared) as? String
    }

    /// A class's value when the layout gives this platform none: the
    /// vocabulary `jui g project` writes a spec's types with — "" / 0 / 0.0 /
    /// false / [] — and nil (no value) for an optional or any other class.
    static func vocabulary(_ className: String?) -> Any? {
        guard let type = className?.trimmingCharacters(in: .whitespaces) else { return nil }
        if type.hasSuffix("?") { return nil }
        switch type {
        case "String": return ""
        case "Int", "Integer": return 0
        case "Double", "Float", "CGFloat": return 0.0
        case "Bool", "Boolean": return false
        default:
            let list = type.hasPrefix("Array(") || type.hasPrefix("List<")
                || (type.hasPrefix("[") && type.hasSuffix("]") && !type.contains(":"))
            return list ? [Any]() : nil
        }
    }

    /// The warning for a value written per platform that names no `swift`:
    /// the code generators' sentence (TypeConverterCore
    /// #default_for_missing_platform) without the layout, which dynamic mode
    /// does not know. `given` in the order the caller has it.
    static func missingPlatformWarning(name: String, given: [String], className: String?) -> String {
        let answer: String
        if className?.trimmingCharacters(in: .whitespaces).hasSuffix("?") == true {
            answer = "nil"
        } else if let value = vocabulary(className), let type = className {
            answer = "the \(type) default \(literal(value))"
        } else {
            answer = "no default (\(className ?? "") has no vocabulary value)"
        }
        return "data '\(name)' defaultValue is given for \(given.joined(separator: ", ")) "
            + "but not \(language) — \(language) gets \(answer)"
    }

    /// A vocabulary value as the generators print it (Ruby's inspect).
    private static func literal(_ value: Any) -> String {
        switch value {
        case let text as String: return "\"\(text)\""
        case let flag as Bool: return flag ? "true" : "false"
        case let number as Int: return String(number)
        case let number as Double: return String(number)
        case let list as [Any]: return list.isEmpty ? "[]" : String(describing: list)
        default: return String(describing: value)
        }
    }

    /// The text a String default's spelling means:
    ///   bare (canonical)  the text as written
    ///   ''                empty
    ///   "…"               JSON's escapes; when they do not read as JSON (an
    ///                     escape JSON does not have, a bare `"`, a raw
    ///                     control character, a lone surrogate), the text
    ///                     between the quotes as written
    ///   '…'               the text between the quotes as written
    static func text(_ raw: String) -> String {
        if raw == "''" { return "" }
        let scalars = raw.unicodeScalars
        guard scalars.count >= 2 else { return raw }
        let inner = String(String.UnicodeScalarView(scalars.dropFirst().dropLast()))
        if raw.hasPrefix("\""), raw.hasSuffix("\"") {
            return jsonString(inner) ?? inner
        }
        if raw.hasPrefix("'"), raw.hasSuffix("'") {
            return inner
        }
        return raw
    }

    /// `inner` read as the inside of a JSON string, or nil when it is not one.
    private static func jsonString(_ inner: String) -> String? {
        let units = Array(inner.utf16)
        var out: [UInt16] = []
        var i = 0
        while i < units.count {
            let unit = units[i]
            if unit == 0x22 || unit < 0x20 { return nil }
            if unit != 0x5C {
                out.append(unit)
                i += 1
                continue
            }
            guard i + 1 < units.count else { return nil }
            switch units[i + 1] {
            case 0x22, 0x5C, 0x2F: out.append(units[i + 1])
            case 0x62: out.append(0x08)
            case 0x66: out.append(0x0C)
            case 0x6E: out.append(0x0A)
            case 0x72: out.append(0x0D)
            case 0x74: out.append(0x09)
            case 0x75:
                guard i + 6 <= units.count else { return nil }
                var code: UInt16 = 0
                for digit in units[(i + 2)..<(i + 6)] {
                    guard let value = hexValue(digit) else { return nil }
                    code = code << 4 | value
                }
                out.append(code)
                i += 4
            default:
                return nil
            }
            i += 2
        }
        // Every surrogate in a pair: a lone one is not text.
        var k = 0
        while k < out.count {
            if (0xD800...0xDBFF).contains(out[k]) {
                guard k + 1 < out.count, (0xDC00...0xDFFF).contains(out[k + 1]) else { return nil }
                k += 2
                continue
            }
            if (0xDC00...0xDFFF).contains(out[k]) { return nil }
            k += 1
        }
        return String(decoding: out, as: UTF16.self)
    }

    private static func hexValue(_ unit: UInt16) -> UInt16? {
        switch unit {
        case 0x30...0x39: return unit - 0x30
        case 0x41...0x46: return unit - 0x41 + 10
        case 0x61...0x66: return unit - 0x61 + 10
        default: return nil
        }
    }
}
