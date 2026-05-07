//
//  DynamicBindingHelper.swift
//  SwiftJsonUI
//
//  Resolves @{property} expressions to Binding<T> from data dictionary
//

import SwiftUI
#if DEBUG

/// Resolves @{property} binding expressions to actual SwiftUI Binding<T> values.
/// Matches tool-generated code pattern:
///   $data.textValue  → Binding<String>
///   data.isOn        → read-only value
public struct DynamicBindingHelper {

    /// Extract property name from @{propertyName} syntax
    private static func extractPropertyName(from value: String?) -> String? {
        return DynamicEventHelper.extractPropertyName(from: value)
    }

    // MARK: - Binding<String>

    /// Resolve @{property} to Binding<String>
    /// Looks for Binding<String> in data dict, falls back to .constant()
    static func string(_ expression: String?, data: [String: Any], fallback: String = "") -> SwiftUI.Binding<String> {
        guard let propName = extractPropertyName(from: expression) else {
            return .constant(fallback)
        }

        // Try Binding<String> first (two-way binding)
        if let binding = data[propName] as? SwiftUI.Binding<String> {
            return binding
        }

        // Fallback to constant from string value in data
        if let value = data[propName] as? String {
            return .constant(value)
        }

        return .constant(fallback)
    }

    // MARK: - Binding<Bool>

    /// Resolve @{property} to Binding<Bool>
    static func bool(_ expression: String?, data: [String: Any], fallback: Bool = false) -> SwiftUI.Binding<Bool> {
        guard let propName = extractPropertyName(from: expression) else {
            return .constant(fallback)
        }

        if let binding = data[propName] as? SwiftUI.Binding<Bool> {
            return binding
        }

        if let value = data[propName] as? Bool {
            return .constant(value)
        }

        return .constant(fallback)
    }

    // MARK: - Binding<Int>

    /// Resolve @{property} to Binding<Int>
    static func int(_ expression: String?, data: [String: Any], fallback: Int = 0) -> SwiftUI.Binding<Int> {
        guard let propName = extractPropertyName(from: expression) else {
            return .constant(fallback)
        }

        if let binding = data[propName] as? SwiftUI.Binding<Int> {
            return binding
        }

        if let value = data[propName] as? Int {
            return .constant(value)
        }

        return .constant(fallback)
    }

    // MARK: - Binding<Double>

    /// Resolve @{property} to Binding<Double>
    static func double(_ expression: String?, data: [String: Any], fallback: Double = 0) -> SwiftUI.Binding<Double> {
        guard let propName = extractPropertyName(from: expression) else {
            return .constant(fallback)
        }

        if let binding = data[propName] as? SwiftUI.Binding<Double> {
            return binding
        }

        if let value = data[propName] as? Double {
            return .constant(value)
        }

        return .constant(fallback)
    }

    // MARK: - Read-only value resolution

    /// Resolve a raw attribute value (from component.rawData) to a concrete value.
    /// Handles both @{binding} expressions and literal values.
    /// Automatically unwraps SwiftUI.Binding<T> if the data dictionary contains one.
    /// Use this in CustomComponent adapters instead of manual `data[prop] as? String`.
    ///
    /// Example:
    ///   let text: String = DynamicBindingHelper.resolveValue(component.rawData["text"], data: data) ?? ""
    ///   let fontSize: Double = DynamicBindingHelper.resolveValue(component.rawData["fontSize"], data: data) ?? 0
    public static func resolveValue<T>(_ expression: Any?, data: [String: Any]) -> T? {
        guard let stringValue = expression as? String else {
            return expression as? T
        }

        if stringValue.hasPrefix("@{") && stringValue.hasSuffix("}") {
            let propName = String(stringValue.dropFirst(2).dropLast(1))
            // Unwrap SwiftUI.Binding if present
            if let binding = data[propName] as? SwiftUI.Binding<T> {
                return binding.wrappedValue
            }
            return data[propName] as? T
        }

        return stringValue as? T
    }

    /// Resolve @{property} to a Bool value (read-only)
    /// Supports negation: @{!propertyName}
    /// Automatically unwraps SwiftUI.Binding<Bool> if present
    static func resolveBool(_ expression: Any?, data: [String: Any], fallback: Bool = false) -> Bool {
        guard let stringValue = expression as? String else {
            if let binding = expression as? SwiftUI.Binding<Bool> {
                return binding.wrappedValue
            }
            return expression as? Bool ?? fallback
        }

        if stringValue.hasPrefix("@{") && stringValue.hasSuffix("}") {
            var propName = String(stringValue.dropFirst(2).dropLast(1))
            var negate = false
            if propName.hasPrefix("!") {
                negate = true
                propName = String(propName.dropFirst())
            }
            // Unwrap SwiftUI.Binding<Bool> if present
            if let binding = data[propName] as? SwiftUI.Binding<Bool> {
                let value = binding.wrappedValue
                return negate ? !value : value
            }
            let value = data[propName] as? Bool ?? fallback
            return negate ? !value : value
        }

        return fallback
    }

    // MARK: - Binding extraction from data dictionary

    /// Extract SwiftUI.Binding<String> from data dictionary by key name
    /// Returns the binding if present, nil otherwise
    static func extractStringBinding(_ key: String, data: [String: Any]) -> SwiftUI.Binding<String>? {
        return data[key] as? SwiftUI.Binding<String>
    }

    /// Extract SwiftUI.Binding<Bool> from data dictionary by key name
    static func extractBoolBinding(_ key: String, data: [String: Any]) -> SwiftUI.Binding<Bool>? {
        return data[key] as? SwiftUI.Binding<Bool>
    }

    /// Extract SwiftUI.Binding<Bool> from @{property} expression, supporting negation
    static func extractBoolBinding(from expression: String?, data: [String: Any]) -> SwiftUI.Binding<Bool>? {
        guard let propName = extractPropertyName(from: expression) else { return nil }
        var name = propName
        var negate = false
        if name.hasPrefix("!") {
            negate = true
            name = String(name.dropFirst())
        }
        guard let binding = data[name] as? SwiftUI.Binding<Bool> else { return nil }
        if negate {
            return SwiftUI.Binding<Bool>(
                get: { !binding.wrappedValue },
                set: { binding.wrappedValue = !$0 }
            )
        }
        return binding
    }
}
#endif // DEBUG
