//
//  JsonUIBindingPath.swift
//  SwiftJsonUI
//
//  Canonical `@{...}` PATH RESOLUTION and value coercion, available in
//  release builds.
//
//  The rest of the Dynamic subsystem is development-time only: 22 of the 23
//  files under Dynamic/ are wrapped in `#if DEBUG`, because a layout
//  interpreter and its hot-reload machinery have no place in a shipped app.
//  The one exception before this file was `JsonUINormalization`, and the line
//  it draws is the one that matters here: what a CONSUMER'S RELEASE BUILD
//  needs lives outside the guard.
//
//  Binding path resolution crossed that line when the static (codegen) face
//  started reading paths that traverse into an untyped JSON container. Such a
//  path cannot be Swift member access -- `[String: Any]` has no member `name`
//  -- so the generated code has to resolve it at runtime, and generated code
//  is distributed and built for release. Referencing a DEBUG-only symbol from
//  it produces the worst available failure: it compiles in DEBUG, so every
//  gate goes green, and breaks in the consumer's release build.
//
//  So the pure value logic lives here and `DynamicBindingResolver` delegates
//  to it, keeping ONE implementation of the canonical semantics rather than a
//  second copy that has to be kept in step. Nothing here is dynamic-specific:
//  no `AnyCodable`, no `SwiftUI.Binding` state store, no layout decoding. The
//  wrapper types the dynamic face carries are unwrapped by the caller through
//  the `unwrap` hook.
//
//  Semantics are jsonui-cli shared/core/binding_semantics.json (version 1).
//

import Foundation

public enum JsonUIBindingPath {

    // MARK: - Path lookup

    /// Canonical path lookup: the raw path string as a FLAT key first (a data
    /// map that literally contains "a.b" shadows the nested path), then
    /// dot-path traversal with bracket array indices. Returns `nil` when the
    /// path is unresolved -- an out-of-range index, a non-array where an index
    /// was used, or a missing or non-object intermediate. Never traps.
    ///
    /// `unwrap` is applied to each container before it is traversed, so a
    /// caller whose tree carries wrapper values (the dynamic face wraps them
    /// in `AnyCodable`) can traverse without this file knowing that type.
    public static func resolve(
        path: String,
        in data: [String: Any],
        unwrap: (Any?) -> Any? = { $0 }
    ) -> Any? {
        guard !path.isEmpty else { return nil }
        if let flat = data[path] {
            return flat
        }
        guard path.contains(".") || path.contains("[") else { return nil }
        var current: Any? = data
        for segment in path.split(separator: ".", omittingEmptySubsequences: false) {
            guard let (name, indices) = parseSegment(String(segment)) else { return nil }
            guard let dict = unwrap(current) as? [String: Any],
                  let named = dict[name] else { return nil }
            current = named
            for index in indices {
                guard let array = unwrap(current) as? [Any],
                      array.indices.contains(index) else { return nil }
                current = array[index]
            }
        }
        return current
    }

    /// `"name"` → ("name", []); `"name[0]"` → ("name", [0]);
    /// `"name[0][2]"` → ("name", [0, 2]). Only non-negative integer literals
    /// are valid indices; anything malformed → nil (unresolved).
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

    // MARK: - Coercion tables (canonical — the ONE table used everywhere)

    /// True when the NSNumber is actually a CFBoolean (JSON `true`/`false`)
    /// rather than a numeric value — required because NSNumber bridging would
    /// otherwise let `1` cast to `Bool` and `true` cast to `Double`.
    private static func isBooleanNumber(_ number: NSNumber) -> Bool {
        return CFGetTypeID(number) == CFBooleanGetTypeID()
    }

    /// Canonical text form. An integral Double renders without a fractional
    /// part ("1", not "1.0"), which is why callers must not use string
    /// interpolation instead. Containers have no text form → nil.
    public static func stringify(_ value: Any?) -> String? {
        guard let value = value, !(value is NSNull) else { return nil }
        if let string = value as? String { return string }
        if let number = value as? NSNumber {
            if isBooleanNumber(number) { return number.boolValue ? "true" : "false" }
            return stringifyDouble(number.doubleValue, number: number)
        }
        if let bool = value as? Bool { return bool ? "true" : "false" }
        return nil
    }

    /// Canonical text form for a bare number — the `??` default literal in a
    /// text context is one, and it has to render the same way a resolved
    /// value does ("1", not "1.0").
    public static func text(forNumber double: Double) -> String {
        return stringifyDouble(double)
    }

    private static func stringifyDouble(_ double: Double, number: NSNumber? = nil) -> String {
        if double.truncatingRemainder(dividingBy: 1) == 0,
           double.magnitude < 1e15 {
            return String(Int64(double))
        }
        if let number = number { return number.stringValue }
        return "\(double)"
    }

    /// Bool coercion: Bool; Int != 0; String "true"/"1"/"false"/"0"
    /// (case-insensitive); anything else → nil (unresolved).
    public static func bool(_ value: Any?) -> Bool? {
        guard let value = value, !(value is NSNull) else { return nil }
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

    /// Number coercion: number or numeric string; bools and anything else →
    /// nil (unresolved).
    public static func double(_ value: Any?) -> Double? {
        guard let value = value, !(value is NSNull) else { return nil }
        if let number = value as? NSNumber {
            if isBooleanNumber(number) { return nil }
            return number.doubleValue
        }
        if let string = value as? String { return Double(string) }
        return nil
    }
}
