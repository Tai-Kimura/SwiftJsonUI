//
//  DynamicComponent.swift
//  SwiftJsonUI
//
//  Dynamic component model and helpers
//

import SwiftUI

// MARK: - Component Model
public struct DynamicComponent: Decodable {
    let type: String
    let id: String?
    let text: String?
    let fontSize: CGFloat?
    let fontColor: String?
    let font: String?
    let width: Dynamic<String>?
    let height: Dynamic<String>?
    let background: String?
    let padding: DynamicPadding?
    let margin: DynamicPadding?
    let cornerRadius: CGFloat?
    let borderWidth: CGFloat?
    let borderColor: String?
    let alpha: CGFloat?
    let hidden: Bool?
    let visibility: String?
    let shadow: DynamicShadow?
    let clipToBounds: Bool?
    let minWidth: CGFloat?
    let maxWidth: CGFloat?
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let aspectWidth: CGFloat?
    let aspectHeight: CGFloat?
    let userInteractionEnabled: Bool?
    let centerInParent: Bool?
    let weight: CGFloat?
    
    // Component specific
    let child: AnyCodable?
    let children: [DynamicComponent]?
    let orientation: String?
    let contentMode: String?
    let url: String?
    let placeholder: String?
    let renderingMode: String?
    let headers: [String: String]?
    let items: [String]?
    let data: [[String: String]]?
    let hint: String?
    let hintColor: String?
    let hintFont: String?
    let flexible: Bool?
    let containerInset: [CGFloat]?
    let hideOnFocused: Bool?
    let action: String?
    let iconOn: String?
    let iconOff: String?
    let iconColor: String?
    let iconPosition: String?
    let textAlign: String?
    let selectedItem: String?
    let isOn: Bool?
    let progress: Double?
    let value: Double?
    let minValue: Double?
    let maxValue: Double?
    let indicatorStyle: String?
    let selectedIndex: Int?
    
    // Event handlers
    let onClick: String?
    let onLongPress: String?
    let onAppear: String?
    let onDisappear: String?
    let onChange: String?
    let onSubmit: String?
    let onToggle: String?
    let onSelect: String?
    
    // Include support
    let include: String?
    let variables: [String: AnyCodable]?
}

// MARK: - Dynamic Type (for single item or array)
public enum Dynamic<T: Decodable>: Decodable {
    case single(T)
    case array([T])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([T].self) {
            self = .array(array)
        } else if let single = try? container.decode(T.self) {
            self = .single(single)
        } else {
            throw DecodingError.typeMismatch(Dynamic.self, 
                DecodingError.Context(codingPath: decoder.codingPath, 
                                    debugDescription: "Expected single value or array"))
        }
    }
    
    public var asArray: [T] {
        switch self {
        case .single(let value):
            return [value]
        case .array(let values):
            return values
        }
    }
}

// MARK: - AnyCodable for variable values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as array first
        if let array = try? container.decode([AnyCodable].self) {
            // Check if this is an array of DynamicComponents or mixed content (including data objects)
            var components: [DynamicComponent] = []
            var hasDataObject = false
            
            for item in array {
                if let component = item.value as? DynamicComponent {
                    components.append(component)
                } else if let dict = item.value as? [String: AnyCodable],
                          dict["data"] != nil {
                    // This is a data binding object, skip it
                    hasDataObject = true
                }
            }
            
            // If we found DynamicComponents and no data objects, store as component array
            if !components.isEmpty && !hasDataObject {
                self.value = components
            } else {
                // Store as raw array (might contain data objects)
                self.value = array
            }
        }
        // Try to decode as single DynamicComponent
        else if let component = try? container.decode(DynamicComponent.self) {
            self.value = component
        }
        // Try to decode as dictionary (for nested object or data binding)
        else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict
        }
        // Try primitive types
        else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else {
            self.value = ""
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        }
    }
    
    // Helper methods to get typed values
    public var asDynamicComponent: DynamicComponent? {
        return value as? DynamicComponent
    }
    
    public var asDynamicComponentArray: [DynamicComponent]? {
        return value as? [DynamicComponent]
    }
}