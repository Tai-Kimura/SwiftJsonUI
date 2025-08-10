//
//  DynamicPadding.swift
//  SwiftJsonUI
//
//  Flexible padding type that accepts single number or array
//

import SwiftUI

// MARK: - Flexible Padding Type
public enum DynamicPadding: Decodable {
    case single(CGFloat)
    case array([CGFloat])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as array first
        if let array = try? container.decode([CGFloat].self) {
            self = .array(array)
        }
        // Try to decode as single CGFloat
        else if let single = try? container.decode(CGFloat.self) {
            self = .single(single)
        }
        // Try to decode as Int and convert to CGFloat
        else if let intValue = try? container.decode(Int.self) {
            self = .single(CGFloat(intValue))
        }
        // Try to decode as String and parse
        else if let stringValue = try? container.decode(String.self) {
            if let floatValue = Float(stringValue) {
                self = .single(CGFloat(floatValue))
            } else {
                throw DecodingError.typeMismatch(DynamicPadding.self,
                    DecodingError.Context(codingPath: decoder.codingPath,
                                        debugDescription: "Could not parse padding value from string"))
            }
        }
        else {
            throw DecodingError.typeMismatch(DynamicPadding.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                    debugDescription: "Expected number or array for padding"))
        }
    }
    
    public var edgeInsets: EdgeInsets {
        switch self {
        case .single(let value):
            return EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
        case .array(let values):
            switch values.count {
            case 1:
                return EdgeInsets(top: values[0], leading: values[0], 
                                bottom: values[0], trailing: values[0])
            case 2:
                // vertical, horizontal
                return EdgeInsets(top: values[0], leading: values[1], 
                                bottom: values[0], trailing: values[1])
            case 3:
                // top, horizontal, bottom
                return EdgeInsets(top: values[0], leading: values[1], 
                                bottom: values[2], trailing: values[1])
            case 4:
                // top, right, bottom, left (CSS order)
                return EdgeInsets(top: values[0], leading: values[3], 
                                bottom: values[2], trailing: values[1])
            default:
                return EdgeInsets()
            }
        }
    }
    
    public var asArray: [CGFloat] {
        switch self {
        case .single(let value):
            return [value, value, value, value]
        case .array(let values):
            return values
        }
    }
}