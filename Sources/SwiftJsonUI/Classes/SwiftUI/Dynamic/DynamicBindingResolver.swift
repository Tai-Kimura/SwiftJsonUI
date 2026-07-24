//
//  DynamicBindingResolver.swift
//  SwiftJsonUI
//
//  Central `@{...}` binding-expression resolver for the SwiftUI Dynamic
//  layer. ONE implementation of the canonical binding-resolution semantics
//  (jsonui-cli shared/core/binding_semantics.json, version 1):
//
//  - Expression:   path [ '??' default ] | '!' path (bool value context only)
//  - Path lookup:  FLAT key first, then dot-path traversal with bracket
//                  array index (items[0].title). Out-of-range / non-array /
//                  missing or non-object intermediate => unresolved (never
//                  a crash).
//  - '??' default: split on the FIRST '??'; whitespace-insensitive; the
//                  default literal is a double- or single-quoted string,
//                  true/false, a number, or null (= unresolved). A resolved
//                  path (including false / 0 / "") always wins.
//  - Coercion:     one bool table (Bool; Int != 0; "true"/"1"/"false"/"0"
//                  case-insensitive), one number table (number or numeric
//                  string), canonical text stringification (integral
//                  numbers without decimal point, bools as "true"/"false",
//                  nil / object / array => unresolved — never a debug dump).
//
//  All Dynamic-layer resolution sites (DynamicHelpers, DynamicBindingHelper,
//  DynamicDecodingHelper, modifier helpers, converters) route through this
//  type. Two-way Binding<T> extraction stays flat-identifier by design and
//  does NOT come through here (see binding_semantics.json `twoWay`).
//

import SwiftUI
#if DEBUG

public enum DynamicBindingResolver {

    // MARK: - Expression model

    /// Parsed default literal (right-hand side of `??`).
    public enum DefaultLiteral: Equatable {
        case string(String)
        case bool(Bool)
        case number(Double)
        /// `null`, or an unparseable literal (fails closed) — treated as
        /// unresolved per the canonical semantics.
        case null

        /// The literal as a plain value (`nil` for `.null`).
        public var anyValue: Any? {
            switch self {
            case .string(let s): return s
            case .bool(let b): return b
            case .number(let d): return d
            case .null: return nil
            }
        }
    }

    /// Parsed `@{...}` inner expression.
    public struct Expression {
        /// Trimmed path with any leading `!` stripped.
        public let path: String
        /// True when the expression is `!path` (bool value contexts only).
        public let negated: Bool
        /// True when the expression contains a `??` default clause.
        public let hasDefault: Bool
        /// The parsed default literal (`nil` when `hasDefault == false`).
        public let defaultLiteral: DefaultLiteral?
    }

    // MARK: - Syntax helpers

    /// True when `raw` is exactly one whole `@{...}` expression.
    public static func isBindingExpression(_ raw: String?) -> Bool {
        return inner(of: raw) != nil
    }

    /// `"@{expr}"` → `"expr"`; anything else → nil.
    public static func inner(of raw: String?) -> String? {
        guard let raw = raw, raw.hasPrefix("@{"), raw.hasSuffix("}"), raw.count > 3 else {
            return nil
        }
        return String(raw.dropFirst(2).dropLast(1))
    }

    /// Parse an inner expression (`name`, `!flag`, `a.b[0].c ?? 'x'`, ...).
    /// Splits on the FIRST `??` only; whitespace around the path, the
    /// operator and the default literal is insignificant. An unparseable
    /// default literal fails closed to `.null` (= unresolved).
    public static func parse(_ innerRaw: String) -> Expression {
        var lhs = innerRaw
        var hasDefault = false
        var defaultLiteral: DefaultLiteral? = nil
        if let range = innerRaw.range(of: "??") {
            lhs = String(innerRaw[..<range.lowerBound])
            let rhs = String(innerRaw[range.upperBound...])
                .trimmingCharacters(in: .whitespaces)
            hasDefault = true
            defaultLiteral = parseDefaultLiteral(rhs)
        }
        var path = lhs.trimmingCharacters(in: .whitespaces)
        var negated = false
        if path.hasPrefix("!") {
            negated = true
            path = String(path.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return Expression(
            path: path,
            negated: negated,
            hasDefault: hasDefault,
            defaultLiteral: defaultLiteral
        )
    }

    /// Parse a default literal: `"x"` / `'x'` / `true` / `false` / number /
    /// `null`. Anything else (including a second `??` inside the remainder)
    /// fails closed to `.null`.
    static func parseDefaultLiteral(_ raw: String) -> DefaultLiteral {
        switch raw {
        case "null": return .null
        case "true": return .bool(true)
        case "false": return .bool(false)
        default: break
        }
        for quote: Character in ["\"", "'"] {
            if raw.count >= 2, raw.first == quote, raw.last == quote {
                let content = String(raw.dropFirst().dropLast())
                // The delimiter quote may not reappear inside the content —
                // this is what makes `'x' ?? 'y'` (double default) fail
                // closed instead of parsing as the string "x' ?? 'y".
                guard !content.contains(quote) else { return .null }
                return .string(content)
            }
        }
        if let number = Double(raw) { return .number(number) }
        return .null
    }

    // MARK: - Path lookup (raw values — wrappers preserved)

    /// Canonical path lookup: the raw path string as a FLAT key first (a
    /// data map that literally contains "a.b" shadows the nested path),
    /// then dot-path traversal with bracket array indices. Returns the raw
    /// stored leaf (SwiftUI.Binding / AnyCodable wrappers preserved) so
    /// value-layer callers can inspect wrapper types; `nil` when the path
    /// is unresolved.
    public static func lookupRaw(path: String, in data: [String: Any]) -> Any? {
        guard !path.isEmpty else { return nil }
        if let flat = data[path] {
            return flat
        }
        guard path.contains(".") || path.contains("[") else { return nil }
        var current: Any? = data
        for segment in path.split(separator: ".", omittingEmptySubsequences: false) {
            guard let (name, indices) = parseSegment(String(segment)) else { return nil }
            guard let dict = unwrapContainer(current) as? [String: Any],
                  let named = dict[name] else { return nil }
            current = named
            for index in indices {
                guard let array = unwrapContainer(current) as? [Any],
                      array.indices.contains(index) else { return nil }
                current = array[index]
            }
        }
        return current
    }

    /// `"name"` → ("name", []); `"name[0]"` → ("name", [0]);
    /// `"name[0][2]"` → ("name", [0, 2]). Only non-negative integer
    /// literals are valid indices; anything malformed → nil (unresolved).
    private static func parseSegment(_ segment: String) -> (name: String, indices: [Int])? {
        guard !segment.isEmpty else { return nil }
        guard let bracket = segment.firstIndex(of: "[") else {
            guard !segment.contains("]") else { return nil }
            return (segment, [])
        }
        let name = String(segment[..<bracket])
        guard !name.isEmpty else { return nil }
        var indices: [Int] = []
        var rest = Substring(segment[bracket...])
        while !rest.isEmpty {
            guard rest.first == "[", let close = rest.firstIndex(of: "]") else { return nil }
            let digits = rest[rest.index(after: rest.startIndex)..<close]
            guard !digits.isEmpty, digits.allSatisfy({ $0.isNumber }),
                  let index = Int(digits) else { return nil }
            indices.append(index)
            rest = rest[rest.index(after: close)...]
        }
        return (name, indices)
    }

    /// Container-level unwrap used during traversal (AnyCodable can wrap
    /// intermediate dictionaries / arrays).
    private static func unwrapContainer(_ value: Any?) -> Any? {
        var current = value
        while let anyCodable = current as? AnyCodable {
            current = anyCodable.value
        }
        return current
    }

    // MARK: - Value-layer unwrap

    /// Unwrap `AnyCodable` and the standard `SwiftUI.Binding<T>` wrappers
    /// (String / Int / Double / Bool / CGFloat) to the plain value.
    /// `NSNull` unwraps to nil.
    public static func unwrap(_ value: Any?) -> Any? {
        guard var current = value else { return nil }
        while let anyCodable = current as? AnyCodable {
            current = anyCodable.value
        }
        if current is NSNull { return nil }
        if let binding = current as? SwiftUI.Binding<String> { return binding.wrappedValue }
        if let binding = current as? SwiftUI.Binding<Int> { return binding.wrappedValue }
        if let binding = current as? SwiftUI.Binding<Double> { return binding.wrappedValue }
        if let binding = current as? SwiftUI.Binding<Bool> { return binding.wrappedValue }
        if let binding = current as? SwiftUI.Binding<CGFloat> { return binding.wrappedValue }
        return current
    }

    // MARK: - Coercion tables (canonical — the ONE table used everywhere)

    /// True when the NSNumber is actually a CFBoolean (JSON `true`/`false`)
    /// rather than a numeric value — required because NSNumber bridging
    /// would otherwise let `1` cast to `Bool` and `true` cast to `Double`.
    private static func isBooleanNumber(_ number: NSNumber) -> Bool {
        return CFGetTypeID(number) == CFBooleanGetTypeID()
    }

    /// Bool coercion: Bool; Int != 0; String "true"/"1"/"false"/"0"
    /// (case-insensitive); anything else → nil (unresolved).
    public static func coerceBool(_ value: Any?) -> Bool? {
        guard let value = unwrap(value) else { return nil }
        if let number = value as? NSNumber {
            if isBooleanNumber(number) { return number.boolValue }
            return number.doubleValue != 0
        }
        if let bool = value as? Bool { return bool }
        if let string = value as? String {
            switch string.lowercased() {
            case "true", "1": return true
            case "false", "0": return false
            default: return nil
            }
        }
        return nil
    }

    /// Number coercion: number or numeric string; bools and anything else
    /// → nil (unresolved).
    public static func coerceDouble(_ value: Any?) -> Double? {
        guard let value = unwrap(value) else { return nil }
        if let number = value as? NSNumber {
            if isBooleanNumber(number) { return nil }
            return number.doubleValue
        }
        if let string = value as? String { return Double(string) }
        return nil
    }

    /// Strict Bool: only genuine booleans (no int / string coercion).
    /// Used where a plain data value drives a Bool-shaped view decision
    /// (e.g. visibility Bool → "visible"/"gone").
    public static func strictBool(_ value: Any?) -> Bool? {
        guard let value = unwrap(value) else { return nil }
        if let number = value as? NSNumber {
            return isBooleanNumber(number) ? number.boolValue : nil
        }
        return value as? Bool
    }

    // MARK: - Canonical text stringification

    /// Canonical stringification: String as-is; Bool "true"/"false";
    /// integral numbers without decimal point ("5", not "5.0"); nil /
    /// dictionary / array / other objects → nil (unresolved) — never a
    /// `String(describing:)` debug dump.
    public static func stringify(_ value: Any?) -> String? {
        guard let value = unwrap(value) else { return nil }
        if let string = value as? String { return string }
        if let number = value as? NSNumber {
            if isBooleanNumber(number) { return number.boolValue ? "true" : "false" }
            return stringifyDouble(number.doubleValue, number: number)
        }
        if let bool = value as? Bool { return bool ? "true" : "false" }
        return nil
    }

    private static func stringifyDouble(_ double: Double, number: NSNumber? = nil) -> String {
        if double.truncatingRemainder(dividingBy: 1) == 0,
           double.magnitude < 1e15 {
            return String(Int64(double))
        }
        if let number = number { return number.stringValue }
        return "\(double)"
    }

    // MARK: - Context resolution: text

    private static let interpolationRegex = try? NSRegularExpression(
        pattern: "@\\{([^}]+)\\}", options: []
    )

    /// Mixed-text interpolation: every `@{...}` occurrence is replaced by
    /// its stringified resolved value; unresolved occurrences render as an
    /// empty string (with a debug log listing the available keys).
    public static func interpolate(_ text: String, data: [String: Any]) -> String {
        guard text.contains("@{"), let regex = interpolationRegex else { return text }
        var result = text
        let matches = regex.matches(
            in: text, options: [],
            range: NSRange(location: 0, length: (text as NSString).length)
        )
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text),
                  let innerRange = Range(match.range(at: 1), in: text) else { continue }
            let innerExpr = String(text[innerRange])
            let replacement = resolveTextOccurrence(innerExpr, data: data)
            result.replaceSubrange(range, with: replacement)
        }
        return result
    }

    /// Resolve one `@{...}` occurrence for text context ("" when unresolved).
    static func resolveTextOccurrence(_ innerRaw: String, data: [String: Any]) -> String {
        let expression = parse(innerRaw)
        // Negation is a bool-value-context feature. In text the token is an
        // ordinary (unresolvable) key: only a literal flat "!path" key hits.
        if expression.negated {
            if let value = stringify(data["!" + expression.path]) { return value }
            return textDefault(expression) ?? ""
        }
        if let raw = lookupRaw(path: expression.path, in: data) {
            if let value = stringify(raw) {
                Logger.debug("[DynamicBindingResolver] text: '\(expression.path)' = '\(value)'")
                return value
            }
            // Resolved to null / object / array — not stringifiable.
        }
        if let fallback = textDefault(expression) { return fallback }
        Logger.debug("[DynamicBindingResolver] text: '\(expression.path)' NOT FOUND in data. Available keys: \(Array(data.keys))")
        return ""
    }

    private static func textDefault(_ expression: Expression) -> String? {
        guard let literal = expression.defaultLiteral else { return nil }
        switch literal {
        case .string(let s): return s
        case .bool(let b): return b ? "true" : "false"
        case .number(let d): return stringifyDouble(d)
        case .null: return nil
        }
    }

    // MARK: - Context resolution: typed whole-value

    /// String value context. `nil` = unresolved (the caller's default
    /// applies). Accepts either the inner expression or a whole `@{...}`.
    public static func resolveString(expression innerRaw: String, data: [String: Any]) -> String? {
        let expression = parse(normalizedInner(innerRaw))
        if expression.negated {
            // Invalid in string context — ordinary flat "!path" key only.
            if let value = stringify(data["!" + expression.path]) { return value }
        } else if let raw = lookupRaw(path: expression.path, in: data),
                  let value = stringify(raw) {
            return value
        }
        guard let literal = expression.defaultLiteral else { return nil }
        switch literal {
        case .string(let s): return s
        case .bool(let b): return b ? "true" : "false"
        case .number(let d): return stringifyDouble(d)
        case .null: return nil
        }
    }

    /// Bool value context (the only context where `!` negation applies).
    /// `nil` = unresolved. An unresolved negated path stays unresolved —
    /// the default (when present) applies WITHOUT inversion.
    public static func resolveBool(expression innerRaw: String, data: [String: Any]) -> Bool? {
        let expression = parse(normalizedInner(innerRaw))
        if let raw = lookupRaw(path: expression.path, in: data),
           let value = coerceBool(raw) {
            return expression.negated ? !value : value
        }
        if let literal = expression.defaultLiteral,
           let fallback = coerceBool(literal.anyValue) {
            return fallback
        }
        return nil
    }

    /// Number value context. `nil` = unresolved.
    public static func resolveDouble(expression innerRaw: String, data: [String: Any]) -> Double? {
        let expression = parse(normalizedInner(innerRaw))
        if !expression.negated,
           let raw = lookupRaw(path: expression.path, in: data),
           let value = coerceDouble(raw) {
            return value
        }
        if let literal = expression.defaultLiteral,
           let fallback = coerceDouble(literal.anyValue) {
            return fallback
        }
        return nil
    }

    /// Integer value context (number table, then integral conversion).
    public static func resolveInt(expression innerRaw: String, data: [String: Any]) -> Int? {
        guard let double = resolveDouble(expression: innerRaw, data: data),
              let int = Int(exactly: double.rounded()) else { return nil }
        return int
    }

    /// Generic typed resolution used by `processValue<T>` /
    /// `resolveValue<T>`: raw wrapper inspection first (so a
    /// `SwiftUI.Binding<T>` of ANY `T` unwraps), then the canonical
    /// coercion table for the standard scalar types, then a plain cast.
    public static func resolveTyped<T>(expression innerRaw: String, data: [String: Any]) -> T? {
        let expression = parse(normalizedInner(innerRaw))
        if !expression.negated, let raw = lookupRaw(path: expression.path, in: data) {
            if let binding = raw as? SwiftUI.Binding<T> { return binding.wrappedValue }
            if T.self == String.self, let value = stringify(raw) { return value as? T }
            if T.self == Bool.self, let value = coerceBool(raw) { return value as? T }
            if T.self == Double.self, let value = coerceDouble(raw) { return value as? T }
            if T.self == CGFloat.self, let value = coerceDouble(raw) { return CGFloat(value) as? T }
            if T.self == Int.self, let value = coerceDouble(raw),
               let int = Int(exactly: value.rounded()) { return int as? T }
            if let value = unwrap(raw) as? T { return value }
            return nil
        }
        guard let literal = expression.defaultLiteral else { return nil }
        if T.self == String.self { return (resolveString(expression: innerRaw, data: data)) as? T }
        if T.self == Bool.self { return coerceBool(literal.anyValue) as? T }
        if T.self == Double.self { return coerceDouble(literal.anyValue) as? T }
        if T.self == CGFloat.self { return coerceDouble(literal.anyValue).map { CGFloat($0) } as? T }
        if T.self == Int.self {
            return coerceDouble(literal.anyValue).flatMap { Int(exactly: $0.rounded()) } as? T
        }
        return literal.anyValue as? T
    }

    // MARK: - Context resolution: embed params / include data (raw leaves)

    /// Embed-params leaf resolution: path-only features, native JSON types
    /// preserved (the raw stored value is returned so reactive wrappers a
    /// parent placed in its data dict survive; `NSNull` resolves to nil).
    /// `??` defaults and `!` negation are validator errors in this context
    /// — they fail closed to unresolved (nil ⇒ the key is dropped so the
    /// embedded screen's own data-section defaultValue applies).
    public static func resolveParamValue(expression innerRaw: String, parentData: [String: Any]) -> Any? {
        let expression = parse(normalizedInner(innerRaw))
        guard !expression.negated, !expression.hasDefault else { return nil }
        guard let raw = lookupRaw(path: expression.path, in: parentData) else { return nil }
        if raw is NSNull { return nil }
        return raw
    }

    /// Include-data value resolution: same raw-preserving lookup as embed
    /// params, but `??` defaults resolve (include data is a value context).
    public static func resolveDataValue(expression innerRaw: String, parentData: [String: Any]) -> Any? {
        let expression = parse(normalizedInner(innerRaw))
        if !expression.negated,
           let raw = lookupRaw(path: expression.path, in: parentData),
           !(raw is NSNull) {
            return raw
        }
        return expression.defaultLiteral?.anyValue
    }

    /// Accept either the inner expression ("name") or a whole binding
    /// string ("@{name}") — call sites hold both shapes (AttrValue.binding
    /// stores the inner; rawData holds the wrapped form).
    private static func normalizedInner(_ raw: String) -> String {
        return inner(of: raw) ?? raw
    }
}

#endif // DEBUG
