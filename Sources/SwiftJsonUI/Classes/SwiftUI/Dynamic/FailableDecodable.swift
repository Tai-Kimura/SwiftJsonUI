//
//  FailableDecodable.swift
//  SwiftJsonUI
//
//  Helper for decoding arrays where some elements might fail
//

import Foundation
#if DEBUG


/// Wrapper for failable decoding of array elements.
///
/// A failed element never aborts the surrounding array decode; instead the
/// failure is captured (`decodingError` + `rawJSON`) so callers can degrade
/// it visibly — `DynamicDecodingHelper.decodeChildren` turns failed children
/// into error-placeholder components instead of silently dropping them.
struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?
    /// The error thrown by `T`'s decode, when it failed.
    let decodingError: Error?
    /// The element's raw JSON object (when it was an object), for
    /// diagnostics / placeholder synthesis.
    let rawJSON: [String: Any]?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            value = try container.decode(T.self)
            decodingError = nil
            rawJSON = nil
        } catch {
            value = nil
            decodingError = error
            rawJSON = (try? container.decode(AnyCodable.self))?.value as? [String: Any]
            Logger.debug("[FailableDecodable] Failed to decode \(T.self): \(error)")
        }
    }
}

/// Extension to decode arrays where some elements might fail
extension Array where Element: Decodable {
    init(failableFrom decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let failableElements = try container.decode([FailableDecodable<Element>].self)
        self = failableElements.compactMap { $0.value }
    }
}
#endif // DEBUG
