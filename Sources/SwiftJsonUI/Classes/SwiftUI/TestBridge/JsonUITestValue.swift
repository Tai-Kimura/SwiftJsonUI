//
//  JsonUITestValue.swift
//  SwiftJsonUI
//
//  The one place an initialState value is judged against a Data class.
//
//  Canon: jsonui-test-runner specs/2026-07-08-advanced-test-features.md §10.3,
//  fixed by specs/vectors/initial-state-coercion.json (vendored through
//  jsonui-cli shared/core/initial_state_coercion_vectors.json).
//

import Foundation
import CoreGraphics

/// A key of an initialState payload the app did not apply, and why. The
/// reason is one of the fixed strings of spec §10.3.
public struct JsonUIRejectedKey: Equatable {
    public let key: String
    public let reason: String

    public init(key: String, reason: String) {
        self.key = key
        self.reason = reason
    }

    /// The reason for a key that is not one of the screen's Data names.
    public static func notADataField(_ key: String) -> JsonUIRejectedKey {
        JsonUIRejectedKey(key: key, reason: "not a data field")
    }
}

/// Judges one initialState value against the class a layout declares.
///
/// Generated code (`sjui build`) calls ``check(_:declaredClass:)`` once per
/// Data field and assigns what it accepts; a host that drives `DynamicView`
/// directly builds its apply from the same function. No other code decides
/// whether a value fits: the existing `update(dictionary:)` drops a value
/// that does not fit without saying so, which is why it is not used here.
public enum JsonUITestValue {
    public enum Outcome {
        /// The value, converted to the Swift type the class maps to
        /// (`String`, `Int`, `Double`, `Float`, `CGFloat`, `Bool`, a typed
        /// array of those, `[Any]`, `[String: Any]`), or nil for an accepted
        /// `null`. A `Color` is accepted as its `String` spelling; resolving
        /// it is the caller's.
        case accept(Any?)
        /// The rejection reason, verbatim from spec §10.3.
        case reject(String)
    }

    enum Primitive: Equatable {
        case string, int, double, float, cgFloat, bool, color
    }

    enum Kind: Equatable {
        case primitive(Primitive)
        case typedArray(Primitive)
        case untypedArray
        case object
        case unsupported
    }

    /// The generators' class vocabulary (`type_mapping.json`): a synonym
    /// judges like its class, and keeps its own spelling in a reason.
    static let primitiveSpellings: [String: Primitive] = [
        "String": .string, "string": .string,
        "Int": .int, "int": .int, "Integer": .int, "integer": .int,
        "Double": .double, "double": .double, "Number": .double, "number": .double,
        "Float": .float, "float": .float,
        "CGFloat": .cgFloat,
        "Bool": .bool, "bool": .bool, "Boolean": .bool, "boolean": .bool,
        "Color": .color, "color": .color,
    ]

    /// (kind, optional) for a declared class. Optional is a trailing `?` and
    /// nothing else.
    static func parse(_ declaredClass: String) -> (Kind, Bool) {
        let spelled = declaredClass.trimmingCharacters(in: .whitespaces)
        let optional = spelled.hasSuffix("?")
        let base = optional ? String(spelled.dropLast()) : spelled
        // A closure type is unsupported whatever else it looks like.
        if base.contains("->") { return (.unsupported, optional) }
        if let primitive = primitiveSpellings[base] { return (.primitive(primitive), optional) }
        if ["Array", "array"].contains(base) { return (.untypedArray, optional) }
        if ["Object", "object", "Hash", "hash"].contains(base) { return (.object, optional) }
        if let element = arrayElement(base) {
            if let primitive = primitiveSpellings[element] { return (.typedArray(primitive), optional) }
            return (.unsupported, optional)
        }
        return (.unsupported, optional)
    }

    /// The element of `Array(X)`, `[X]` (not a dictionary `[K: V]`) or `List<X>`.
    static func arrayElement(_ base: String) -> String? {
        if base.hasPrefix("Array("), base.hasSuffix(")") {
            return String(base.dropFirst("Array(".count).dropLast())
        }
        if base.hasPrefix("List<"), base.hasSuffix(">") {
            return String(base.dropFirst("List<".count).dropLast())
        }
        if base.hasPrefix("["), base.hasSuffix("]"), !base.contains(":") {
            return String(base.dropFirst().dropLast())
        }
        return nil
    }

    public static func check(_ value: Any?, declaredClass: String) -> Outcome {
        let (kind, optional) = parse(declaredClass)
        if kind == .unsupported { return .reject("unsupported type \(declaredClass)") }
        if isNull(value) {
            return optional ? .accept(nil) : .reject("null for non-optional \(declaredClass)")
        }
        let mismatch = Outcome.reject("type mismatch: expected \(declaredClass)")
        switch kind {
        case .primitive(let primitive):
            guard let converted = convert(value as Any, to: primitive) else { return mismatch }
            return .accept(converted)
        case .typedArray(let primitive):
            guard let elements = value as? [Any] else { return mismatch }
            var converted: [Any] = []
            for element in elements {
                guard !isNull(element), let one = convert(element, to: primitive) else { return mismatch }
                converted.append(one)
            }
            return .accept(typedArray(converted, of: primitive))
        case .untypedArray:
            guard let elements = value as? [Any], elements.allSatisfy(isScalar) else { return mismatch }
            return .accept(elements)
        case .object:
            guard let entries = value as? [String: Any], entries.values.allSatisfy(isScalar) else { return mismatch }
            return .accept(entries)
        case .unsupported:
            return .reject("unsupported type \(declaredClass)")
        }
    }

    // MARK: - JSON value reading

    static func isNull(_ value: Any?) -> Bool {
        guard let value else { return true }
        return value is NSNull
    }

    /// A JSON boolean. `NSNumber` carries both booleans and numbers, and a
    /// Swift `as? Bool` accepts 0 and 1 — the CFBoolean type id is the only
    /// thing that tells `true` from `1`.
    static func boolean(_ value: Any) -> Bool? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }

    /// A JSON number that is not a boolean.
    static func number(_ value: Any) -> NSNumber? {
        guard let number = value as? NSNumber, boolean(value) == nil else { return nil }
        return number
    }

    /// A string, number or boolean: what an untyped Array / Object may hold.
    static func isScalar(_ value: Any) -> Bool {
        value is String || value as? NSNumber != nil
    }

    static func convert(_ value: Any, to primitive: Primitive) -> Any? {
        switch primitive {
        case .string, .color:
            return value as? String
        case .bool:
            return boolean(value)
        case .int:
            guard let number = number(value) else { return nil }
            let double = number.doubleValue
            // Integral (2.0 included — JavaScript cannot tell it from 2) and
            // within 32 bits: the Int every face can hold.
            guard double.isFinite, double.rounded() == double,
                  double >= Double(Int32.min), double <= Double(Int32.max) else { return nil }
            return Int(double)
        case .double:
            return number(value)?.doubleValue
        case .float:
            return number(value)?.floatValue
        case .cgFloat:
            return number(value).map { CGFloat($0.doubleValue) }
        }
    }

    static func typedArray(_ values: [Any], of primitive: Primitive) -> Any {
        switch primitive {
        case .string, .color: return values.compactMap { $0 as? String }
        case .int: return values.compactMap { $0 as? Int }
        case .double: return values.compactMap { $0 as? Double }
        case .float: return values.compactMap { $0 as? Float }
        case .cgFloat: return values.compactMap { $0 as? CGFloat }
        case .bool: return values.compactMap { $0 as? Bool }
        }
    }
}
