//
//  DeclaredSpelling.swift
//  SwiftJsonUI
//
//  An enum attribute's value by its declared spelling, case and all
//  (jsonui-cli 1.9.0, as type names are).
//

import Foundation

/// `declared` is a generated attribute enum's `declaredSpellings` — every
/// spelling attribute_definitions.json declares for the attribute, its values
/// and its valueAliases keys, case-sensitive
/// (`ViewAttributes.Orientation.declaredSpellings`).
///
/// The hand-written switches compare lowercased names. `lowered` is what they
/// compare now: the lowercased value when the value is one of the declared
/// spellings, nil for anything else — a spelling declared in no case
/// ("Horizontal" for "horizontal"), a word declared nowhere — which each
/// switch already sends to its default. The validator names such a value;
/// this does not say it again. The three tools read the same way
/// (jsonui-cli shared/core/enum_spelling.rb).
public enum DeclaredSpelling {
    public static func lowered(_ value: String?, in declared: [String]) -> String? {
        guard let value = value, declared.contains(value) else { return nil }
        return value.lowercased()
    }
}
