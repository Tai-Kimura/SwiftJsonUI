//
//  FailableDecodable.swift
//  SwiftJsonUI
//
//  Helper for decoding arrays where some elements might fail
//

import Foundation

/// Wrapper for failable decoding of array elements
struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try? container.decode(T.self)
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