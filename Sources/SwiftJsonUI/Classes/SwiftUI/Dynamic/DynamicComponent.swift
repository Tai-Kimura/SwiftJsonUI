//
//  DynamicComponent.swift
//  SwiftJsonUI
//
//  Dynamic component model and helpers
//

import SwiftUI
#if DEBUG


// MARK: - Component Model
public struct DynamicComponent: Decodable {
    let type: String?
    
    /// Raw JSON data for this component (for custom attributes)
    public let rawData: [String: Any]

    /// True when this component came from an L1-normalized layout
    /// (`$jui` marker — see `JsonUINormalization`). Alias attribute
    /// spellings were already rewritten to canonical names, so
    /// converters skip alias fallbacks. Propagated to every nested
    /// component via `JSONDecoder.userInfo`.
    public let isNormalized: Bool

    /// Check if this is a valid component (has type)
    public var isValid: Bool {
        return type != nil && !type!.isEmpty
    }
    
    /// Get child components - supports both 'child' and 'children' keys
    public var childComponents: [DynamicComponent]? {
        // Prefer 'child' over 'children' for consistency
        return child ?? children
    }
    
    let id: String?
    let edgeInset: AnyCodable?  // Text padding for Label (単一値または配列形式をサポート)
    let autoShrink: Bool?  // Auto shrink text to fit for Label
    let lineBreakMode: String?  // Truncation mode: head, middle, tail (UIKit compatibility)
    let textShadow: AnyCodable?  // Text shadow for Label
    let widthRaw: String?  // Store original string value if needed
    let heightRaw: String?  // Store original string value if needed
    // UIKitに合わせてpaddingsに統一（paddingは削除）
    let paddings: AnyCodable?
    // UIKitに合わせてmarginsに統一（marginは削除）
    let margins: AnyCodable?
    // UIKitに合わせてpaddingTop形式に統一（leftPadding等は削除）
    // RTL-aware padding and margin
    // Min/Max margin constraints
    let insets: AnyCodable?
    let insetHorizontal: CGFloat?
    let insetVertical: CGFloat?
    let horizontalScroll: Bool?
    let columnSpacing: CGFloat?
    let itemSpacing: CGFloat?
    let contentInsets: AnyCodable?
    let hidesWhenStopped: Bool?
    let defaultImage: String?
    let errorImage: String?
    let loadingImage: String?
    let highlighted: Bool?
    let events: AnyCodable?
    let partialAttributes: AnyCodable?
    let highlightAttributes: AnyCodable?
    let hintAttributes: AnyCodable?
    // Check/Radio attributes
    let onSrc: String?
    let icon: String?
    let selectedIcon: String?
    let iconSize: CGFloat?
    let checkedColor: String?
    let uncheckedColor: String?
    let group: String?
    // Segment attributes
    let normalColor: String?
    let selectedColor: String?
    // TextField events
    let onTextChange: String?
    // TextField accessory
    let accessoryBackground: String?
    let accessoryTextColor: String?
    let doneText: String?
    // SelectBox attributes
    let caretAttributes: AnyCodable?
    let dividerAttributes: AnyCodable?
    let labelAttributes: AnyCodable?
    let canBack: Bool?
    let prompt: String?
    let includePromptWhenDataBinding: Bool?
    let minuteInterval: Int?
    // Web attributes
    let html: String?
    let allowsBackForwardNavigationGestures: Bool?
    let allowsLinkPreview: Bool?
    // View touch disable attributes
    let touchDisabledState: String?
    let touchEnabledViewIds: [String]?
    // IconLabel attributes
    let selectedFontColor: String?
    let iconMargin: CGFloat?
    // GradientView attributes
    let locations: [CGFloat]?
    // Collection attributes
    let itemWeight: CGFloat?
    let layout: String?
    let cellClasses: AnyCodable?
    let headerClasses: AnyCodable?
    let footerClasses: AnyCodable?
    let sections: [[String: Any]]?
    let setTargetAsDelegate: Bool?
    let setTargetAsDataSource: Bool?
    // Switch/Toggle event
    let alpha: CGFloat?
    let shadow: AnyCodable?
    let idealWidth: CGFloat?
    let idealHeight: CGFloat?
    
    // Z-order
    let indexBelow: String?  // Place below specified view ID
    let indexAbove: String?  // Place above specified view ID
    
    // Component specific - child is always an array
    let child: [DynamicComponent]?
    let children: [DynamicComponent]?  // Alias for child (backward compatibility)
    let orientation: String?
    let direction: String?  // Layout direction: topToBottom, bottomToTop, leftToRight, rightToLeft
    let distribution: String?  // Child distribution: fill, fillEqually, fillProportionally, equalSpacing, equalCentering
    let systemIcon: Bool?  // true to use SF Symbol, false for local asset (default: false)
    let placeholder: String?
    let renderingMode: String?
    let headers: [String: String]?
    let data: [AnyCodable]?  // For data elements with variable definitions
    let hint: String?
    // hintColor is already declared above with hintAttributes
    let hintFont: String?
    let hintFontSize: CGFloat?
    let hintLineHeightMultiple: CGFloat?
    let fieldPadding: CGFloat?
    let flexible: Bool?
    let containerInset: [CGFloat]?
    let hideOnFocused: Bool?
    let returnKeyType: String?  // Return key type for TextField
    let borderStyle: String?  // Border style for TextField
    let input: String?  // Keyboard type for TextField
    let action: String?
    let iconOn: String?
    let iconOff: String?
    let iconColor: String?
    let iconPosition: String?
    let minValue: Double?
    let maxValue: Double?
    let indicatorStyle: String?
    let tabs: [[String: Any]]?  // TabView tabs array
    let onTabChange: String?  // TabView tab change callback
    
    // ScrollView properties
    let contentInsetAdjustmentBehavior: String?  // never, always, automatic, scrollableAxes
    let showsHorizontalScrollIndicator: Bool?  // Show horizontal scroll indicator
    let showsVerticalScrollIndicator: Bool?  // Show vertical scroll indicator
    let paging: Bool?  // Enable paging
    let bounces: Bool?  // Enable bounce effect
    let scrollAnchor: String?  // top, center, bottom
    let defaultScrollAnchor: String?  // top, center, bottom (iOS 17+)

    // SelectBox/DatePicker properties
    let selectItemType: String?
    let datePickerMode: String?
    let datePickerStyle: String?
    let dateStringFormat: String?
    
    // Event handlers
    let onAppear: String?
    let onDisappear: String?
    let onChange: String?
    let onSubmit: String?
    let onToggle: String?
    let onSelect: String?
    
    // Include support
    let include: String?
    let variables: [String: AnyCodable]?
    let includeData: [String: AnyCodable]?  // For include component's data
    let sharedData: [String: AnyCodable]?   // For include component's shared_data
    
    // Layout properties
    let gravity: [String]?  // Raw gravity values from JSON
    let alignment: Alignment?  // Converted SwiftUI alignment
    
    // Relative positioning
    let alignLeftOfView: String?  // JSON: alignLeftOfView -> constraint: leftOf
    let alignRightOfView: String?  // JSON: alignRightOfView -> constraint: rightOf
    let alignTopOfView: String?  // JSON: alignTopOfView -> constraint: above
    let alignBottomOfView: String?  // JSON: alignBottomOfView -> constraint: below
    let alignTopView: String?  // Align top edge with target's top edge
    let alignBottomView: String?  // Align bottom edge with target's bottom edge
    let alignLeftView: String?  // Align left edge with target's left edge
    let alignRightView: String?  // Align right edge with target's right edge
    let alignCenterVerticalView: String?  // Center vertically with target view
    let alignCenterHorizontalView: String?  // Center horizontally with target view
    
    // CodingKeys
    public enum CodingKeys: String, CodingKey {
        case type, id
        case edgeInset
        case autoShrink, lineBreakMode, textShadow
        case width, height, widthRaw, heightRaw
        case padding, paddings, margins
        case leftPadding, rightPadding, topPadding, bottomPadding
        case insets, insetHorizontal, insetVertical, horizontalScroll, columnSpacing, itemSpacing, contentInsets
        case hidesWhenStopped
        case defaultImage, errorImage, loadingImage
        case highlighted, events
        case partialAttributes, highlightAttributes, hintAttributes
        case onSrc, icon, selectedIcon, iconSize, checkedColor, uncheckedColor, group
        case normalColor, selectedColor
        case onTextChange, accessoryBackground, accessoryTextColor, doneText
        case caretAttributes, dividerAttributes, labelAttributes, canBack, prompt, includePromptWhenDataBinding, minuteInterval
        case html, allowsBackForwardNavigationGestures, allowsLinkPreview
        case touchDisabledState, touchEnabledViewIds
        case selectedFontColor, iconMargin
        case locations
        case itemWeight, layout, cellClasses, headerClasses, footerClasses, sections
        case setTargetAsDelegate, setTargetAsDataSource
        case alpha, shadow
        case idealWidth, idealHeight
        case indexBelow, indexAbove
        case child
        case children  // Alias for child (backward compatibility)
        case orientation, direction, distribution, systemIcon, placeholder, renderingMode
        case headers, data
        case hint, hintFont, hintFontSize, hintLineHeightMultiple, fieldPadding, flexible, containerInset, hideOnFocused
        case returnKeyType, borderStyle, input
        case action, iconOn, iconOff, iconColor, iconPosition
        case minValue, maxValue, indicatorStyle
        case tabs, onTabChange
        case contentInsetAdjustmentBehavior
        case showsHorizontalScrollIndicator, showsVerticalScrollIndicator
        case paging, bounces
        case scrollAnchor, defaultScrollAnchor
        case selectItemType, datePickerMode, datePickerStyle
        case dateStringFormat
        case onAppear, onDisappear
        case onChange, onSubmit, onToggle, onSelect
        case include, variables
        case includeData  // Will be handled specially in decoder
        case sharedData = "shared_data"  // Map JSON "shared_data" to sharedData
        case gravity, alignment
        case alignLeftOfView, alignRightOfView, alignTopOfView, alignBottomOfView
        case alignTopView, alignBottomView, alignLeftView, alignRightView
        case alignCenterVerticalView, alignCenterHorizontalView
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Normalization flag threaded from the layout root (see
        // JsonUINormalization / JSONLayoutLoader)
        self.isNormalized = decoder.userInfo[
            JsonUINormalization.decoderUserInfoKey
        ] as? Bool ?? false

        // Store raw JSON data for custom attributes
        // Try to decode as AnyCodable to get all properties including unknown ones
        if let singleValue = try? decoder.singleValueContainer(),
           let anyValue = try? singleValue.decode(AnyCodable.self),
           var dict = anyValue.value as? [String: Any] {
            // The `$jui` normalization marker is metadata, never an
            // attribute — keep it out of rawData (it is stripped at the
            // root by JSONLayoutLoader, but included subtrees may carry
            // their own file-root marker)
            dict.removeValue(forKey: JsonUINormalization.markerKey)
            self.rawData = dict
        } else {
            // Fallback: Extract all known keys into dictionary
            var dict = [String: Any]()
            for key in container.allKeys {
                if let value = try? container.decode(AnyCodable.self, forKey: key) {
                    dict[key.stringValue] = value.value
                }
            }
            dict.removeValue(forKey: JsonUINormalization.markerKey)
            self.rawData = dict
        }
        
        // Type is optional - elements without type (include, data, etc.) will be skipped
        type = try container.decodeIfPresent(String.self, forKey: .type)
        
        // Basic properties
        id = try container.decodeIfPresent(String.self, forKey: .id)
        // `fontSize` has no hand-decoded slot: it is number|binding, a hard
        // decode of the bound spelling threw, and children go through
        // FailableDecodable — so the throw DELETED the component from the
        // tree instead of surfacing. `Label { fontSize: "@{x}" }` rendered
        // nothing at all. The generated tables carry it now.
        edgeInset = try container.decodeIfPresent(AnyCodable.self, forKey: .edgeInset)
        // These binding-capable attrs are declared `["number","binding"]` /
        // `["boolean","binding"]` in the shared catalog (see generated
        // LabelAttributes etc.). A `"@{binding}"` string makes a typed
        // decodeIfPresent THROW (key present, wrong type) — `try?` swallows
        // the throw so the typed slot becomes nil while the binding survives
        // via rawData / typedAttributes and is resolved at render time. A
        // literal still decodes identically, so non-binding layouts are
        // byte-unchanged.
        autoShrink = try container.decodeIfPresent(Bool.self, forKey: .autoShrink)
        textShadow = try container.decodeIfPresent(AnyCodable.self, forKey: .textShadow)
        lineBreakMode = try container.decodeIfPresent(String.self, forKey: .lineBreakMode)

        // Size properties - use helper for decoding
        // Only the RAW spelling is stored. The value goes through
        // `declaredWidth`, which reads `AttrValue<DimensionValue>` — a
        // `CGFloat?` slot cannot hold `width: "@{w}"`.
        widthRaw = DynamicDecodingHelper.decodeSizeValue(from: container, forKey: .width).raw
        
        heightRaw = DynamicDecodingHelper.decodeSizeValue(from: container, forKey: .height).raw
        
        
        // Padding/Margin（UIKitに合わせてpaddings/marginsに統一）
        paddings = try container.decodeIfPresent(AnyCodable.self, forKey: .paddings)
            ?? (try container.decodeIfPresent(AnyCodable.self, forKey: .padding))
        margins = try container.decodeIfPresent(AnyCodable.self, forKey: .margins)
        // Individual padding overrides (and their `topPadding` aliases) are
        // read from the generated typed extraction — see
        // DynamicHelpers.getPadding. No hand-decoded slot: the binding form
        // has to survive, and a CGFloat slot cannot hold `@{expr}`.

        // RTL-aware padding/margin
        // Min/Max margin constraints
        insets = try container.decodeIfPresent(AnyCodable.self, forKey: .insets)
        insetHorizontal = try container.decodeIfPresent(CGFloat.self, forKey: .insetHorizontal)
        insetVertical = try container.decodeIfPresent(CGFloat.self, forKey: .insetVertical)
        horizontalScroll = try container.decodeIfPresent(Bool.self, forKey: .horizontalScroll)
        columnSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .columnSpacing)
        itemSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .itemSpacing)
        contentInsets = try container.decodeIfPresent(AnyCodable.self, forKey: .contentInsets)
        // `try?` on every bindable slot whose Swift type cannot hold a
        // String: the bound spelling IS a String, a hard decode throws, and
        // children go through FailableDecodable — so the throw deleted the
        // component instead of surfacing. The typed extraction carries the
        // bound form; these slots only have to stop killing the node.
        hidesWhenStopped = try container.decodeIfPresent(Bool.self, forKey: .hidesWhenStopped)
        defaultImage = try container.decodeIfPresent(String.self, forKey: .defaultImage)
        errorImage = try container.decodeIfPresent(String.self, forKey: .errorImage)
        loadingImage = try container.decodeIfPresent(String.self, forKey: .loadingImage)
        highlighted = try? container.decodeIfPresent(Bool.self, forKey: .highlighted)
        events = try container.decodeIfPresent(AnyCodable.self, forKey: .events)
        partialAttributes = try container.decodeIfPresent(AnyCodable.self, forKey: .partialAttributes)
        highlightAttributes = try container.decodeIfPresent(AnyCodable.self, forKey: .highlightAttributes)
        hintAttributes = try container.decodeIfPresent(AnyCodable.self, forKey: .hintAttributes)
        // Check/Radio attributes
        onSrc = try container.decodeIfPresent(String.self, forKey: .onSrc)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        selectedIcon = try container.decodeIfPresent(String.self, forKey: .selectedIcon)
        iconSize = try container.decodeIfPresent(CGFloat.self, forKey: .iconSize)
        checkedColor = try container.decodeIfPresent(String.self, forKey: .checkedColor)
        uncheckedColor = try container.decodeIfPresent(String.self, forKey: .uncheckedColor)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        // Segment attributes
        normalColor = try container.decodeIfPresent(String.self, forKey: .normalColor)
        selectedColor = try container.decodeIfPresent(String.self, forKey: .selectedColor)
        // TextField events
        onTextChange = try container.decodeIfPresent(String.self, forKey: .onTextChange)
        // TextField accessory
        accessoryBackground = try container.decodeIfPresent(String.self, forKey: .accessoryBackground)
        accessoryTextColor = try container.decodeIfPresent(String.self, forKey: .accessoryTextColor)
        doneText = try container.decodeIfPresent(String.self, forKey: .doneText)
        // SelectBox attributes
        caretAttributes = try container.decodeIfPresent(AnyCodable.self, forKey: .caretAttributes)
        dividerAttributes = try container.decodeIfPresent(AnyCodable.self, forKey: .dividerAttributes)
        labelAttributes = try container.decodeIfPresent(AnyCodable.self, forKey: .labelAttributes)
        canBack = try container.decodeIfPresent(Bool.self, forKey: .canBack)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        includePromptWhenDataBinding = try container.decodeIfPresent(Bool.self, forKey: .includePromptWhenDataBinding)
        minuteInterval = try container.decodeIfPresent(Int.self, forKey: .minuteInterval)
        // Web attributes
        html = try container.decodeIfPresent(String.self, forKey: .html)
        allowsBackForwardNavigationGestures = try container.decodeIfPresent(Bool.self, forKey: .allowsBackForwardNavigationGestures)
        allowsLinkPreview = try container.decodeIfPresent(Bool.self, forKey: .allowsLinkPreview)
        // View touch disable attributes
        touchDisabledState = try container.decodeIfPresent(String.self, forKey: .touchDisabledState)
        touchEnabledViewIds = try container.decodeIfPresent([String].self, forKey: .touchEnabledViewIds)
        // IconLabel attributes
        selectedFontColor = try container.decodeIfPresent(String.self, forKey: .selectedFontColor)
        iconMargin = try container.decodeIfPresent(CGFloat.self, forKey: .iconMargin)
        // GradientView attributes
        locations = try container.decodeIfPresent([CGFloat].self, forKey: .locations)
        // Collection attributes
        itemWeight = try container.decodeIfPresent(CGFloat.self, forKey: .itemWeight)
        layout = try container.decodeIfPresent(String.self, forKey: .layout)
        cellClasses = try container.decodeIfPresent(AnyCodable.self, forKey: .cellClasses)
        headerClasses = try container.decodeIfPresent(AnyCodable.self, forKey: .headerClasses)
        footerClasses = try container.decodeIfPresent(AnyCodable.self, forKey: .footerClasses)
        sections = try container.decodeIfPresent(AnyCodable.self, forKey: .sections)?.value as? [[String: Any]]
        setTargetAsDelegate = try container.decodeIfPresent(Bool.self, forKey: .setTargetAsDelegate)
        setTargetAsDataSource = try container.decodeIfPresent(Bool.self, forKey: .setTargetAsDataSource)
        // Switch/Toggle event
        
        // Style properties. `cornerRadius` / `borderWidth` / `opacity` have
        // no slot any more — they are number|binding and read off
        // CommonAttributes. `alpha` still decodes here.
        // Use try? because these can be binding strings like "@{sendButtonOpacity}"
        // decodeIfPresent throws (not returns nil) when the key exists but has wrong type
        alpha = try? container.decodeIfPresent(CGFloat.self, forKey: .alpha)
        shadow = try container.decodeIfPresent(AnyCodable.self, forKey: .shadow)
        
        // Size constraints
        // idealWidth/idealHeight are plain `number` (no binding) — leave typed.
        idealWidth = try container.decodeIfPresent(CGFloat.self, forKey: .idealWidth)
        idealHeight = try container.decodeIfPresent(CGFloat.self, forKey: .idealHeight)
        
        // Interaction (weight is number|binding — tolerate `@{binding}`).
        // Z-order
        indexBelow = try container.decodeIfPresent(String.self, forKey: .indexBelow)
        indexAbove = try container.decodeIfPresent(String.self, forKey: .indexAbove)
        
        // Child handling - decode both 'child' and 'children' keys
        child = DynamicDecodingHelper.decodeChildren(from: container, forKey: .child)
        children = DynamicDecodingHelper.decodeChildren(from: container, forKey: .children)
        
        // Component specific
        orientation = try container.decodeIfPresent(String.self, forKey: .orientation)
        direction = try container.decodeIfPresent(String.self, forKey: .direction)
        distribution = try container.decodeIfPresent(String.self, forKey: .distribution)
        systemIcon = try container.decodeIfPresent(Bool.self, forKey: .systemIcon)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        renderingMode = try container.decodeIfPresent(String.self, forKey: .renderingMode)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
        hint = try container.decodeIfPresent(String.self, forKey: .hint)
        // hintColor is already decoded above with hintAttributes
        hintFont = try container.decodeIfPresent(String.self, forKey: .hintFont)
        hintFontSize = try container.decodeIfPresent(CGFloat.self, forKey: .hintFontSize)
        hintLineHeightMultiple = try container.decodeIfPresent(CGFloat.self, forKey: .hintLineHeightMultiple)
        fieldPadding = try container.decodeIfPresent(CGFloat.self, forKey: .fieldPadding)
        flexible = try container.decodeIfPresent(Bool.self, forKey: .flexible)
        // Handle containerInset as either single value or array
        if let singleValue = try? container.decode(CGFloat.self, forKey: .containerInset) {
            containerInset = [singleValue, singleValue, singleValue, singleValue]
        } else if let arrayValue = try? container.decode([CGFloat].self, forKey: .containerInset) {
            containerInset = arrayValue
        } else {
            containerInset = nil
        }
        hideOnFocused = try container.decodeIfPresent(Bool.self, forKey: .hideOnFocused)
        returnKeyType = try container.decodeIfPresent(String.self, forKey: .returnKeyType)
        borderStyle = try container.decodeIfPresent(String.self, forKey: .borderStyle)
        input = try container.decodeIfPresent(String.self, forKey: .input)
        action = try container.decodeIfPresent(String.self, forKey: .action)
        iconOn = try container.decodeIfPresent(String.self, forKey: .iconOn)
        iconOff = try container.decodeIfPresent(String.self, forKey: .iconOff)
        iconColor = try container.decodeIfPresent(String.self, forKey: .iconColor)
        iconPosition = try container.decodeIfPresent(String.self, forKey: .iconPosition)
        minValue = try? container.decodeIfPresent(Double.self, forKey: .minValue)
        maxValue = try? container.decodeIfPresent(Double.self, forKey: .maxValue)
        indicatorStyle = try container.decodeIfPresent(String.self, forKey: .indicatorStyle)
        // TabView properties
        tabs = try container.decodeIfPresent(AnyCodable.self, forKey: .tabs)?.value as? [[String: Any]]
        onTabChange = try container.decodeIfPresent(String.self, forKey: .onTabChange)
        contentInsetAdjustmentBehavior = try container.decodeIfPresent(String.self, forKey: .contentInsetAdjustmentBehavior)
        showsHorizontalScrollIndicator = try container.decodeIfPresent(Bool.self, forKey: .showsHorizontalScrollIndicator)
        showsVerticalScrollIndicator = try container.decodeIfPresent(Bool.self, forKey: .showsVerticalScrollIndicator)
        paging = try container.decodeIfPresent(Bool.self, forKey: .paging)
        bounces = try container.decodeIfPresent(Bool.self, forKey: .bounces)
        scrollAnchor = try container.decodeIfPresent(String.self, forKey: .scrollAnchor)
        defaultScrollAnchor = try container.decodeIfPresent(String.self, forKey: .defaultScrollAnchor)

        // SelectBox/DatePicker properties
        selectItemType = try container.decodeIfPresent(String.self, forKey: .selectItemType)
        datePickerMode = try container.decodeIfPresent(String.self, forKey: .datePickerMode)
        datePickerStyle = try container.decodeIfPresent(String.self, forKey: .datePickerStyle)
        dateStringFormat = try container.decodeIfPresent(String.self, forKey: .dateStringFormat)

        // Event handlers
        onAppear = try container.decodeIfPresent(String.self, forKey: .onAppear)
        onDisappear = try container.decodeIfPresent(String.self, forKey: .onDisappear)
        onChange = try container.decodeIfPresent(String.self, forKey: .onChange)
        onSubmit = try container.decodeIfPresent(String.self, forKey: .onSubmit)
        onToggle = try container.decodeIfPresent(String.self, forKey: .onToggle)
        onSelect = try container.decodeIfPresent(String.self, forKey: .onSelect)
        
        // Include support
        include = try container.decodeIfPresent(String.self, forKey: .include)
        variables = try container.decodeIfPresent([String: AnyCodable].self, forKey: .variables)

        // Handle 'data' key conditionally based on whether it's an include component
        if include != nil {
            // For include components, decode 'data' as a dictionary
            includeData = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data)
            sharedData = try container.decodeIfPresent([String: AnyCodable].self, forKey: .sharedData)
            data = nil
        } else {
            // For non-include components, decode 'data' as an array
            data = try container.decodeIfPresent([AnyCodable].self, forKey: .data)
            includeData = nil
            sharedData = nil
        }
        
        // Layout properties
        gravity = DynamicDecodingHelper.decodeGravity(from: container)
        alignment = DynamicDecodingHelper.gravityToAlignment(gravity)
        
        // Relative positioning
        alignLeftOfView = try container.decodeIfPresent(String.self, forKey: .alignLeftOfView)
        alignRightOfView = try container.decodeIfPresent(String.self, forKey: .alignRightOfView)
        alignTopOfView = try container.decodeIfPresent(String.self, forKey: .alignTopOfView)
        alignBottomOfView = try container.decodeIfPresent(String.self, forKey: .alignBottomOfView)
        alignTopView = try container.decodeIfPresent(String.self, forKey: .alignTopView)
        alignBottomView = try container.decodeIfPresent(String.self, forKey: .alignBottomView)
        alignLeftView = try container.decodeIfPresent(String.self, forKey: .alignLeftView)
        alignRightView = try container.decodeIfPresent(String.self, forKey: .alignRightView)
        alignCenterVerticalView = try container.decodeIfPresent(String.self, forKey: .alignCenterVerticalView)
        alignCenterHorizontalView = try container.decodeIfPresent(String.self, forKey: .alignCenterHorizontalView)
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
        
        // Try primitive types first
        if let string = try? container.decode(String.self) {
            self.value = string
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        }
        // Try to decode as array of dictionaries (for partialAttributes)
        else if let dictArray = try? container.decode([[String: AnyCodable]].self) {
            // Convert AnyCodable dictionary to Any dictionary
            self.value = dictArray.map { dict in
                dict.mapValues { $0.value }
            }
        }
        // Try to decode as dictionary (for objects with unknown structure)
        else if let dict = try? container.decode([String: AnyCodable].self) {
            // Convert AnyCodable dictionary to Any dictionary
            self.value = dict.mapValues { $0.value }
        }
        // Try to decode as array of DynamicComponents (for child arrays)
        else if let componentArray = try? container.decode([DynamicComponent].self) {
            self.value = componentArray
        }
        // Try to decode as single DynamicComponent
        else if let component = try? container.decode(DynamicComponent.self) {
            self.value = component
        }
        // Try to decode as array (general case, might contain mixed types)
        else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
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

// MARK: - Reading shared attributes through the generated extraction

extension DynamicComponent {
    /// The layout spelling of a `common` string attribute — the static value,
    /// or `"@{expr}"` for a bound one — read off the generated table.
    ///
    /// Exists because plan 50 deletes the hand-written decode slots: every
    /// `component.background` style read has to move here, and spelling the
    /// full `typedAttributes(CommonAttributes.self).x?.rawRepresentation as?
    /// String` at ~90 call sites would bury the change it is making.
    ///
    /// The result still goes through `getColor(_:data:)` / `processText` to
    /// resolve a binding — this returns what the layout wrote, not what it
    /// means.
    func commonString(_ keyPath: KeyPath<CommonAttributes, AttrValue<String>?>) -> String? {
        typedAttributes(CommonAttributes.self)[keyPath: keyPath]?.rawRepresentation as? String
    }

    /// The STATIC value of a `common` number attribute, or nil when it is
    /// bound. Callers that can resolve a binding should go through
    /// `DynamicHelpers.resolveNumber` with the attribute itself instead —
    /// this is for the paths that only ever had a literal.
    func commonNumber(_ keyPath: KeyPath<CommonAttributes, AttrValue<Double>?>) -> CGFloat? {
        typedAttributes(CommonAttributes.self)[keyPath: keyPath]?.value.map { CGFloat($0) }
    }

    /// The layout spelling of a `common` untyped attribute (event handlers
    /// carry `@{handlerName}` here).
    func commonAny(_ keyPath: KeyPath<CommonAttributes, AttrValue<Any>?>) -> String? {
        typedAttributes(CommonAttributes.self)[keyPath: keyPath]?.rawRepresentation as? String
    }

    /// A number attribute off ANY generated table, binding resolved.
    ///
    /// `commonNumber` only reaches `CommonAttributes` and only returns the
    /// static value; most of the numeric slots being retired live on
    /// component tables (`LabelAttributes.fontSize`, `SliderAttributes.maximum`
    /// …) and their call sites do have `data` in hand. One shape for all of
    /// them, so the retirement does not spawn a second vocabulary.
    func number<T: JsonUIGeneratedAttributes>(
        _ type: T.Type,
        _ keyPath: KeyPath<T, AttrValue<Double>?>,
        data: [String: Any] = [:]
    ) -> CGFloat? {
        DynamicHelpers.resolveNumber(
            typedAttributes(type)[keyPath: keyPath], legacy: nil, data: data
        )
    }

    /// The layout spelling of a string attribute off ANY generated table —
    /// the static value, or `"@{expr}"` for a bound one.
    ///
    /// `commonString` only reaches `CommonAttributes`; the string slots being
    /// retired here (`text`, `font`, `fontColor`, `src` …) live on component
    /// tables. Same shape as `number(_:_:data:)` so the retirement does not
    /// spawn a second vocabulary. Resolution (`getColor` / `processText`)
    /// still happens at the call site — this returns what the layout wrote.
    ///
    /// A table can be passed for a component it does not belong to: the
    /// extraction reads `rawData`, so the table only decides which spellings
    /// are recognised. That is how a helper with no component type in hand
    /// reads a spelling declared on eleven tables (the same reason
    /// `fontFromComponent` reads `fontSize` off `LabelAttributes`).
    func string<T: JsonUIGeneratedAttributes>(
        _ type: T.Type,
        _ keyPath: KeyPath<T, AttrValue<String>?>
    ) -> String? {
        typedAttributes(type)[keyPath: keyPath]?.rawRepresentation as? String
    }

    /// A count attribute off any generated table. The tables carry `Double`
    /// (JSON has one number type), so the rounding rule lives in one place:
    /// `columns` / `lines` / `selectedIndex` are all counts, and a count
    /// rounds to nearest — `2.6 columns` is 3, not 2.
    func int<T: JsonUIGeneratedAttributes>(
        _ type: T.Type,
        _ keyPath: KeyPath<T, AttrValue<Double>?>,
        data: [String: Any] = [:]
    ) -> Int? {
        number(type, keyPath, data: data).map { Int($0.rounded()) }
    }

    /// A declared-enum attribute as its string spelling.
    ///
    /// Two shapes exist and both are declared: `AttrValue<AttrEnum<E>>?`
    /// where the attribute also accepts a binding, and a bare `AttrEnum<E>?`
    /// where it does not. `textAlign` is BOTH — `AttrValue`-wrapped on Label,
    /// bare on Button / TextField / TextView / EditText / Input — so a single
    /// call shape needs the two overloads rather than one guess.
    ///
    /// `.known` returns the CANONICAL spelling, not what the author typed:
    /// matching is case-insensitive, so `"left"` and `"Left"` both arrive as
    /// `.left` and leave as `"Left"`. Every string switch downstream already
    /// accepts both, but a new one must switch on the canonical value —
    /// the `contentType`/`tel` regression was exactly this.
    /// `.unknown` passes the author's value through untouched (open enum).
    func enumString<T: JsonUIGeneratedAttributes, E: RawRepresentable>(
        _ type: T.Type,
        _ keyPath: KeyPath<T, AttrValue<AttrEnum<E>>?>,
        data: [String: Any] = [:]
    ) -> String? where E.RawValue == String {
        switch typedAttributes(type)[keyPath: keyPath] {
        case .some(.value(let declared)):
            return Self.spelling(of: declared)
        case .some(.binding(let expression)):
            return DynamicBindingResolver.resolveString(expression: expression, data: data)
        case nil:
            return nil
        }
    }

    func enumString<T: JsonUIGeneratedAttributes, E: RawRepresentable>(
        _ type: T.Type,
        _ keyPath: KeyPath<T, AttrEnum<E>?>
    ) -> String? where E.RawValue == String {
        typedAttributes(type)[keyPath: keyPath].map(Self.spelling(of:))
    }

    private static func spelling<E: RawRepresentable>(
        of declared: AttrEnum<E>
    ) -> String where E.RawValue == String {
        switch declared {
        case .known(let value): return value.rawValue
        case .unknown(let raw): return raw as? String ?? String(describing: raw)
        }
    }

    /// `visibility` — declared `AttrValue<AttrEnum<Visibility>>?` on common.
    ///
    /// Returns the LAYOUT spelling, `"@{expr}"` included, because that is
    /// what the hand-decoded slot returned and several call sites lean on
    /// it: `needsVisibilityWrapper` asks "was it declared", the container's
    /// visible-child count treats a bound visibility as not-definitely-
    /// visible, and `VisibilityWrapper` re-parses the binding itself.
    /// Resolving here would quietly turn all three into "visible".
    func visibilitySpelling() -> String? {
        typedAttributes(CommonAttributes.self).visibility.map(Self.enumRawSpelling(of:))
    }

    /// `textAlign` — the one attribute declared in BOTH enum shapes.
    /// Label wraps it in `AttrValue` (it accepts a binding); Button,
    /// TextField, TextView, EditText and Input declare the bare `AttrEnum`.
    /// Reading the wrapped shape first covers every component, because the
    /// extraction only coerces `rawData` — but the bare tables are what a
    /// TextField actually declares, so both are consulted rather than
    /// guessing from `type`.
    func textAlignSpelling(data: [String: Any] = [:]) -> String? {
        typedAttributes(LabelAttributes.self).textAlign.map(Self.enumRawSpelling(of:))
            ?? enumString(TextFieldAttributes.self, \.textAlign)
    }

    /// The layout spelling of a wrapped enum: canonical for a declared
    /// value, the author's text for an undeclared one, `"@{expr}"` for a
    /// binding — i.e. exactly what a hand-decoded `String?` slot held.
    private static func enumRawSpelling<E: RawRepresentable>(
        of attr: AttrValue<AttrEnum<E>>
    ) -> String where E.RawValue == String {
        switch attr {
        case .value(let declared): return spelling(of: declared)
        case .binding(let expression): return "@{\(expression)}"
        }
    }

    /// A string-array attribute (`items`) off any generated table.
    /// `AttrValue<[Any]>` on Collection / SelectBox, a bare `[Any]?` on
    /// Segment — the element cast is the same either way.
    func stringList<T: JsonUIGeneratedAttributes>(
        _ type: T.Type,
        _ keyPath: KeyPath<T, AttrValue<[Any]>?>
    ) -> [String]? {
        typedAttributes(type)[keyPath: keyPath]?.value.map { Self.asStrings($0) }
    }

    func stringList<T: JsonUIGeneratedAttributes>(
        _ type: T.Type,
        _ keyPath: KeyPath<T, [Any]?>
    ) -> [String]? {
        typedAttributes(type)[keyPath: keyPath].map { Self.asStrings($0) }
    }

    /// JSON arrays arrive as `[Any]`; the numeric spelling (`items: [1, 2]`)
    /// is as declared as the string one, and the hand-decoded `[String]?`
    /// slot dropped the whole array when a single element was not a string.
    private static func asStrings(_ raw: [Any]) -> [String] {
        raw.compactMap { element in
            if let text = element as? String { return text }
            if let number = element as? NSNumber { return number.stringValue }
            return nil
        }
    }

    /// `fontWeight` — declared `string|number|binding`, so the generated
    /// table carries `AttrValue<Any>` (Button) or a bare `Any?` (Label).
    /// Returns the layout spelling; the weight vocabulary downstream
    /// lowercases it.
    func fontWeightSpelling() -> String? {
        if let wrapped = typedAttributes(ButtonAttributes.self).fontWeight {
            return Self.weightSpelling(wrapped.rawRepresentation)
        }
        return Self.weightSpelling(typedAttributes(LabelAttributes.self).fontWeight)
    }

    /// `fontWeight` is declared `string|number|binding`, so the NUMERIC
    /// spelling (`fontWeight: 600`) is as declared as `"semibold"`. Casting
    /// `rawRepresentation as? String` dropped it — the generated table
    /// carries the Int the layout wrote, and the cast is nil for it.
    /// `font_helper.rb#font_weight_to_swiftui` maps `600` through the shared
    /// table, so dynamic dropping it split the two halves (run 4 parity,
    /// Button/Label `fontWeight__600`).
    private static func weightSpelling(_ raw: Any?) -> String? {
        if let text = raw as? String { return text }
        if let number = raw as? NSNumber { return number.stringValue }
        return nil
    }

    /// `onValueChange` — declared on seven component tables, and in two
    /// value types: `AttrValue<Any>` on the value-carrying controls and
    /// `AttrValue<String>` on Collection / TabView. Every reader wants the
    /// same thing, the handler spelling, so the tables are consulted in turn
    /// rather than dispatched on `type`.
    func onValueChangeSpelling() -> String? {
        if let any = typedAttributes(SwitchAttributes.self).onValueChange {
            return any.rawRepresentation as? String
        }
        return typedAttributes(TabViewAttributes.self).onValueChange?.rawRepresentation as? String
    }

    /// The declared `width` / `height`, in the sentinel encoding every
    /// caller already speaks: `.infinity` for `matchParent`, nil for
    /// `wrapContent` or undeclared, the number otherwise.
    ///
    /// `DimensionValue` carries those three states as a type; this maps
    /// them back rather than changing 35 call sites' vocabulary in the same
    /// commit that retires the slot. A bound spelling (`width: "@{w}"`) is
    /// nil here, exactly as the `CGFloat?` slot was — resolving it is a
    /// separate change, and doing it silently here would move layout.
    var declaredWidth: CGFloat? { dimension(\.width, raw: widthRaw) }
    var declaredHeight: CGFloat? { dimension(\.height, raw: heightRaw) }

    private func dimension(
        _ keyPath: KeyPath<CommonAttributes, AttrValue<DimensionValue>?>,
        raw: String?
    ) -> CGFloat? {
        switch typedAttributes(CommonAttributes.self)[keyPath: keyPath]?.value {
        case .number(let value): return CGFloat(value)
        case .matchParent: return .infinity
        case .wrapContent: return nil
        case nil:
            // `DimensionValue.parse` still matches `"matchParent"` /
            // `"wrapContent"` EXACTLY — no lowercasing, no snake_case. The
            // layout vocabulary is wider and codegen honors the wider one:
            // frame_helper.rb:107 lowercases and accepts `wrap_content`,
            // relative_positioning_helper.rb:560 accepts `match_parent`. So
            // `height: "match_parent"` parses in the generator and NOT in the
            // typed extraction, and this branch is what keeps the two halves
            // saying the same thing.
            //
            // The NUMERIC-STRING half of this gap is closed (49-E, jsonui-cli
            // 957fa1c): `AttrCoerce.number` takes `"100"` now, and
            // `DimensionValue.parse` asks it first — so `.number` above
            // catches it and nothing falls through to here. The keyword
            // spellings are the remainder, still with E.
            switch raw?.lowercased() {
            case "matchparent", "match_parent": return .infinity
            case "wrapcontent", "wrap_content": return nil
            default: return nil
            }
        }
    }

    /// `onValueChanged` — the declared ALIAS of `onValueChange`.
    ///
    /// The generated tables carry it as its own `AttrValue<Any>` field rather
    /// than folding it into the canonical name, so the alias needs its own
    /// read. Three converters were reaching for it through `rawAttribute`
    /// although the receiver had been there all along (plan 50, owner-50 rows).
    func onValueChangedSpelling() -> String? {
        typedAttributes(SelectBoxAttributes.self).onValueChanged?
            .rawRepresentation as? String
    }

    /// `underline` / `strikethrough` — declared `boolean|object|array`, where
    /// the object form carries `lineStyle` / `color` styling.
    ///
    /// The hand-decoded `Bool?` slot THREW on the object form, and children
    /// go through FailableDecodable, so `underline: {"lineStyle": "Single"}`
    /// replaced the whole Label with an error placeholder — the same
    /// node-deletion mechanism `fontSize: "@{x}"` had. codegen never threw:
    /// label_converter.rb tests Ruby truthiness, so an object means
    /// `underline: true` (the styling is not rendered, but the line is).
    /// This mirrors that: Bool reads as itself, any other declared value
    /// means the decoration is on.
    func decorationFlag(_ keyPath: KeyPath<LabelAttributes, Any?>) -> Bool {
        guard let raw = typedAttributes(LabelAttributes.self)[keyPath: keyPath] else {
            return false
        }
        if let flag = raw as? Bool { return flag }
        return true
    }

    /// The six per-side margins.
    ///
    /// They exist as one accessor because the margin spelling has three
    /// forms — the number, the `@{binding}`, and the numeric STRING
    /// (`"topMargin": "12"`) that `margin_expression_helper.rb` accepts.
    /// The third used to need a raw read: `AttrCoerce.number` coerced only
    /// the first two, so the generated `AttrValue<Double>?` was nil for it.
    /// 49-E closed that (jsonui-cli 957fa1c — a numeric string IS a number),
    /// so the raw branch and its six allowlist rows are gone.
    enum MarginEdge: String, CaseIterable {
        case topMargin, bottomMargin, leftMargin, rightMargin, startMargin, endMargin

        var keyPath: KeyPath<CommonAttributes, AttrValue<Double>?> {
            switch self {
            case .topMargin: return \.topMargin
            case .bottomMargin: return \.bottomMargin
            case .leftMargin: return \.leftMargin
            case .rightMargin: return \.rightMargin
            case .startMargin: return \.startMargin
            case .endMargin: return \.endMargin
            }
        }
    }

    /// A margin as CGFloat. Undeclared, or a binding that does not resolve,
    /// is 0 — the value `marginValueToCGFloat` returned.
    func margin(_ edge: MarginEdge, data: [String: Any] = [:]) -> CGFloat {
        number(CommonAttributes.self, edge.keyPath, data: data) ?? 0
    }

    /// Whether the layout DECLARED this margin, regardless of whether it
    /// resolves. `applyFlexibleMargins` needs declared-ness, not the value:
    /// a fixed margin suppresses the min/max pair even when it is bound.
    func hasMargin(_ edge: MarginEdge) -> Bool {
        typedAttributes(CommonAttributes.self)[keyPath: edge.keyPath] != nil
    }

    /// The LITERAL value of a `common` boolean attribute — `nil` when the
    /// layout wrote `@{expr}`, which the call site resolves itself (either
    /// with `DynamicHelpers.resolveBool(_:legacy:data:)`, or with its own
    /// reactive path where one exists, as `hidden` has).
    ///
    /// Same reason as `commonString`: the hand-written `Bool?` slots are
    /// gone, and a `@{expr}` decoded to `nil` in them — so `component.x ==
    /// true` silently dropped every bound boolean (plan 50 §4, group C).
    func commonBool(_ keyPath: KeyPath<CommonAttributes, AttrValue<Bool>?>) -> Bool? {
        typedAttributes(CommonAttributes.self)[keyPath: keyPath]?.value
    }
}
// The DEBUG guard closes at end-of-file so every DynamicComponent extension
// stays inside it — the typed-attr helpers landed AFTER the old `#endif` and
// Release builds (where DynamicComponent does not exist) failed to compile
// the extension. Debug-only verification (unit + conformance) cannot see
// this class of break; the CI Release lane exists for it.
#endif // DEBUG
