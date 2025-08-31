//
//  FailableDecodable.swift
//  SwiftJsonUI
//
//  Helper for decoding arrays where some elements might fail
//

import Foundation
#if DEBUG


/// Wrapper for failable decoding of array elements
struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            value = try container.decode(T.self)
        } catch {
            #if DEBUG
            // Log decoding errors to help debug
            print("[FailableDecodable] Failed to decode \(T.self): \(error)")
            // Try to get more info about what we're trying to decode
            if T.self == DynamicComponent.self {
                // Try to decode as AnyCodable to see what's in there
                if let anyDict = try? container.decode(AnyCodable.self),
                   let dict = anyDict.value as? [String: Any] {
                    print("[FailableDecodable] Component type: \(dict["type"] ?? "nil")")
                    if dict["type"] as? String == "Collection" {
                        print("[FailableDecodable] Collection component failed!")
                        print("[FailableDecodable] sections: \(dict["sections"] ?? "nil")")
                        print("[FailableDecodable] items: \(dict["items"] ?? "nil")")
                        print("[FailableDecodable] height: \(dict["height"] ?? "nil")")
                        print("[FailableDecodable] columns: \(dict["columns"] ?? "nil")")
                    }
                }
            }
            #endif
            value = nil
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
