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
    
    /// Check if this is a valid component (has type)
    public var isValid: Bool {
        return !type.isEmpty
    }
    let id: String?
    let text: String?
    let fontSize: CGFloat?
    let fontColor: String?
    let font: String?
    let fontWeight: String?
    let width: CGFloat?  // .infinity for matchParent, nil for wrapContent, or specific value
    let height: CGFloat?  // .infinity for matchParent, nil for wrapContent, or specific value
    let widthRaw: String?  // Store original string value if needed
    let heightRaw: String?  // Store original string value if needed
    let background: String?
    let padding: AnyCodable?
    let margin: AnyCodable?
    let margins: AnyCodable?
    let paddings: AnyCodable?
    let leftMargin: CGFloat?
    let rightMargin: CGFloat?
    let topMargin: CGFloat?
    let bottomMargin: CGFloat?
    let leftPadding: CGFloat?
    let rightPadding: CGFloat?
    let topPadding: CGFloat?
    let bottomPadding: CGFloat?
    let paddingLeft: CGFloat?
    let paddingRight: CGFloat?
    let paddingTop: CGFloat?
    let paddingBottom: CGFloat?
    let insets: AnyCodable?
    let insetHorizontal: CGFloat?
    let cornerRadius: CGFloat?
    let borderWidth: CGFloat?
    let borderColor: String?
    let alpha: CGFloat?
    let opacity: CGFloat?
    let hidden: Bool?
    let visibility: String?
    let shadow: AnyCodable?
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
    
    // Component specific - child is always an array
    let child: [DynamicComponent]?
    let orientation: String?
    let contentMode: String?
    let src: String?  // Image source (local name or URL)
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
    let columns: Int?  // For collection/grid layouts
    let spacing: CGFloat?  // For stack/grid spacing
    
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
    
    // Layout properties
    let gravity: [String]?  // Raw gravity values from JSON
    let alignment: Alignment?  // Converted SwiftUI alignment
    let widthWeight: Double?
    let heightWeight: Double?
    
    // Relative positioning
    let alignTop: Bool?  // true = align to parent top
    let alignBottom: Bool?  // true = align to parent bottom
    let alignLeft: Bool?  // true = align to parent left
    let alignRight: Bool?  // true = align to parent right
    let centerHorizontal: Bool?
    let centerVertical: Bool?
    let alignLeftOfView: String?  // JSON: alignLeftOfView -> constraint: leftOf
    let alignRightOfView: String?  // JSON: alignRightOfView -> constraint: rightOf
    let alignTopOfView: String?  // JSON: alignTopOfView -> constraint: above
    let alignBottomOfView: String?  // JSON: alignBottomOfView -> constraint: below
    
    // CodingKeys
    public enum CodingKeys: String, CodingKey {
        case type, id, text, fontSize, fontColor, font, fontWeight
        case width, height, widthRaw, heightRaw, background
        case padding, margin, margins, paddings
        case leftMargin, rightMargin, topMargin, bottomMargin
        case leftPadding, rightPadding, topPadding, bottomPadding
        case paddingLeft, paddingRight, paddingTop, paddingBottom
        case insets, insetHorizontal
        case cornerRadius, borderWidth, borderColor
        case alpha, opacity, hidden, visibility, shadow, clipToBounds
        case minWidth, maxWidth, minHeight, maxHeight
        case aspectWidth, aspectHeight
        case userInteractionEnabled, centerInParent, weight
        case child
        case orientation, contentMode, src, placeholder, renderingMode
        case headers, items, data
        case hint, hintColor, hintFont, flexible, containerInset, hideOnFocused
        case action, iconOn, iconOff, iconColor, iconPosition
        case textAlign, selectedItem, isOn, progress, value
        case minValue, maxValue, indicatorStyle, selectedIndex
        case columns, spacing
        case onClick, onLongPress, onAppear, onDisappear
        case onChange, onSubmit, onToggle, onSelect
        case include, variables
        case gravity, alignment, widthWeight, heightWeight
        case alignTop, alignBottom, alignLeft, alignRight
        case centerHorizontal, centerVertical
        case alignLeftOfView, alignRightOfView, alignTopOfView, alignBottomOfView
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Type is required - if not present, skip this element (could be include, data, etc.)
        type = try container.decode(String.self, forKey: .type)
        
        // Basic properties
        id = try container.decodeIfPresent(String.self, forKey: .id)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        fontSize = try container.decodeIfPresent(CGFloat.self, forKey: .fontSize)
        fontColor = try container.decodeIfPresent(String.self, forKey: .fontColor)
        font = try container.decodeIfPresent(String.self, forKey: .font)
        fontWeight = try container.decodeIfPresent(String.self, forKey: .fontWeight)
        
        // Size properties - use helper for decoding
        let widthResult = DynamicDecodingHelper.decodeSizeValue(from: container, forKey: .width)
        width = widthResult.value
        widthRaw = widthResult.raw
        
        let heightResult = DynamicDecodingHelper.decodeSizeValue(from: container, forKey: .height)
        height = heightResult.value
        heightRaw = heightResult.raw
        
        background = try container.decodeIfPresent(String.self, forKey: .background)
        
        // Padding/Margin
        padding = try container.decodeIfPresent(AnyCodable.self, forKey: .padding)
        margin = try container.decodeIfPresent(AnyCodable.self, forKey: .margin)
        margins = try container.decodeIfPresent(AnyCodable.self, forKey: .margins)
        paddings = try container.decodeIfPresent(AnyCodable.self, forKey: .paddings)
        leftMargin = try container.decodeIfPresent(CGFloat.self, forKey: .leftMargin)
        rightMargin = try container.decodeIfPresent(CGFloat.self, forKey: .rightMargin)
        topMargin = try container.decodeIfPresent(CGFloat.self, forKey: .topMargin)
        bottomMargin = try container.decodeIfPresent(CGFloat.self, forKey: .bottomMargin)
        leftPadding = try container.decodeIfPresent(CGFloat.self, forKey: .leftPadding)
        rightPadding = try container.decodeIfPresent(CGFloat.self, forKey: .rightPadding)
        topPadding = try container.decodeIfPresent(CGFloat.self, forKey: .topPadding)
        bottomPadding = try container.decodeIfPresent(CGFloat.self, forKey: .bottomPadding)
        paddingLeft = try container.decodeIfPresent(CGFloat.self, forKey: .paddingLeft)
        paddingRight = try container.decodeIfPresent(CGFloat.self, forKey: .paddingRight)
        paddingTop = try container.decodeIfPresent(CGFloat.self, forKey: .paddingTop)
        paddingBottom = try container.decodeIfPresent(CGFloat.self, forKey: .paddingBottom)
        insets = try container.decodeIfPresent(AnyCodable.self, forKey: .insets)
        insetHorizontal = try container.decodeIfPresent(CGFloat.self, forKey: .insetHorizontal)
        
        // Style properties
        cornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .cornerRadius)
        borderWidth = try container.decodeIfPresent(CGFloat.self, forKey: .borderWidth)
        borderColor = try container.decodeIfPresent(String.self, forKey: .borderColor)
        alpha = try container.decodeIfPresent(CGFloat.self, forKey: .alpha)
        opacity = try container.decodeIfPresent(CGFloat.self, forKey: .opacity)
        hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        visibility = try container.decodeIfPresent(String.self, forKey: .visibility)
        shadow = try container.decodeIfPresent(AnyCodable.self, forKey: .shadow)
        clipToBounds = try container.decodeIfPresent(Bool.self, forKey: .clipToBounds)
        
        // Size constraints
        minWidth = try container.decodeIfPresent(CGFloat.self, forKey: .minWidth)
        maxWidth = try container.decodeIfPresent(CGFloat.self, forKey: .maxWidth)
        minHeight = try container.decodeIfPresent(CGFloat.self, forKey: .minHeight)
        maxHeight = try container.decodeIfPresent(CGFloat.self, forKey: .maxHeight)
        aspectWidth = try container.decodeIfPresent(CGFloat.self, forKey: .aspectWidth)
        aspectHeight = try container.decodeIfPresent(CGFloat.self, forKey: .aspectHeight)
        
        // Interaction
        userInteractionEnabled = try container.decodeIfPresent(Bool.self, forKey: .userInteractionEnabled)
        centerInParent = try container.decodeIfPresent(Bool.self, forKey: .centerInParent)
        weight = try container.decodeIfPresent(CGFloat.self, forKey: .weight)
        
        // Child handling - use helper for decoding (child is always an array)
        child = DynamicDecodingHelper.decodeChildren(from: container, forKey: .child)
        
        // Component specific
        orientation = try container.decodeIfPresent(String.self, forKey: .orientation)
        contentMode = try container.decodeIfPresent(String.self, forKey: .contentMode)
        src = try container.decodeIfPresent(String.self, forKey: .src)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        renderingMode = try container.decodeIfPresent(String.self, forKey: .renderingMode)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        items = try container.decodeIfPresent([String].self, forKey: .items)
        data = try container.decodeIfPresent([[String: String]].self, forKey: .data)
        hint = try container.decodeIfPresent(String.self, forKey: .hint)
        hintColor = try container.decodeIfPresent(String.self, forKey: .hintColor)
        hintFont = try container.decodeIfPresent(String.self, forKey: .hintFont)
        flexible = try container.decodeIfPresent(Bool.self, forKey: .flexible)
        containerInset = try container.decodeIfPresent([CGFloat].self, forKey: .containerInset)
        hideOnFocused = try container.decodeIfPresent(Bool.self, forKey: .hideOnFocused)
        action = try container.decodeIfPresent(String.self, forKey: .action)
        iconOn = try container.decodeIfPresent(String.self, forKey: .iconOn)
        iconOff = try container.decodeIfPresent(String.self, forKey: .iconOff)
        iconColor = try container.decodeIfPresent(String.self, forKey: .iconColor)
        iconPosition = try container.decodeIfPresent(String.self, forKey: .iconPosition)
        textAlign = try container.decodeIfPresent(String.self, forKey: .textAlign)
        selectedItem = try container.decodeIfPresent(String.self, forKey: .selectedItem)
        isOn = try container.decodeIfPresent(Bool.self, forKey: .isOn)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress)
        value = try container.decodeIfPresent(Double.self, forKey: .value)
        minValue = try container.decodeIfPresent(Double.self, forKey: .minValue)
        maxValue = try container.decodeIfPresent(Double.self, forKey: .maxValue)
        indicatorStyle = try container.decodeIfPresent(String.self, forKey: .indicatorStyle)
        selectedIndex = try container.decodeIfPresent(Int.self, forKey: .selectedIndex)
        columns = try container.decodeIfPresent(Int.self, forKey: .columns)
        spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        
        // Event handlers
        onClick = try container.decodeIfPresent(String.self, forKey: .onClick)
        onLongPress = try container.decodeIfPresent(String.self, forKey: .onLongPress)
        onAppear = try container.decodeIfPresent(String.self, forKey: .onAppear)
        onDisappear = try container.decodeIfPresent(String.self, forKey: .onDisappear)
        onChange = try container.decodeIfPresent(String.self, forKey: .onChange)
        onSubmit = try container.decodeIfPresent(String.self, forKey: .onSubmit)
        onToggle = try container.decodeIfPresent(String.self, forKey: .onToggle)
        onSelect = try container.decodeIfPresent(String.self, forKey: .onSelect)
        
        // Include support
        include = try container.decodeIfPresent(String.self, forKey: .include)
        variables = try container.decodeIfPresent([String: AnyCodable].self, forKey: .variables)
        
        // Layout properties
        gravity = DynamicDecodingHelper.decodeGravity(from: container)
        alignment = DynamicDecodingHelper.gravityToAlignment(gravity)
        widthWeight = try container.decodeIfPresent(Double.self, forKey: .widthWeight)
        heightWeight = try container.decodeIfPresent(Double.self, forKey: .heightWeight)
        
        // Relative positioning
        alignTop = try container.decodeIfPresent(Bool.self, forKey: .alignTop)
        alignBottom = try container.decodeIfPresent(Bool.self, forKey: .alignBottom)
        alignLeft = try container.decodeIfPresent(Bool.self, forKey: .alignLeft)
        alignRight = try container.decodeIfPresent(Bool.self, forKey: .alignRight)
        centerHorizontal = try container.decodeIfPresent(Bool.self, forKey: .centerHorizontal)
        centerVertical = try container.decodeIfPresent(Bool.self, forKey: .centerVertical)
        alignLeftOfView = try container.decodeIfPresent(String.self, forKey: .alignLeftOfView)
        alignRightOfView = try container.decodeIfPresent(String.self, forKey: .alignRightOfView)
        alignTopOfView = try container.decodeIfPresent(String.self, forKey: .alignTopOfView)
        alignBottomOfView = try container.decodeIfPresent(String.self, forKey: .alignBottomOfView)
    }
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
        
        // Try to decode as array of DynamicComponents (for child arrays)
        if let componentArray = try? container.decode([DynamicComponent].self) {
            self.value = componentArray
        }
        // Try to decode as single DynamicComponent
        else if let component = try? container.decode(DynamicComponent.self) {
            self.value = component
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
        }
        // Try to decode as array (general case, might contain mixed types)
        else if let array = try? container.decode([AnyCodable].self) {
            self.value = array
        }
        // Try to decode as dictionary (for objects with unknown structure)
        else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict
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