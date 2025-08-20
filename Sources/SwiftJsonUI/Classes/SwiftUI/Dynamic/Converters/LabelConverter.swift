//
//  LabelConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Text view
//

import SwiftUI

public struct LabelConverter {
    
    /// Convert DynamicComponent to SwiftUI Text view
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = viewModel.processText(component.text) ?? ""
        
        // Check for partialAttributes first
        if let partialAttributesValue = component.partialAttributes?.value,
           let partialAttributesDict = partialAttributesValue as? [[String: Any]],
           !partialAttributesDict.isEmpty {
            // Convert dictionary to PartialAttribute structs
            let partialAttributes = partialAttributesDict.compactMap { dict -> PartialAttribute? in
                // Get range
                if let rangeArray = dict["range"] as? [Int], rangeArray.count == 2 {
                    // Numeric range
                    let range = rangeArray[0]..<rangeArray[1]
                    
                    // Parse colors
                    let fontColor = (dict["fontColor"] as? String).flatMap { DynamicHelpers.colorFromHex($0) }
                    let backgroundColor = (dict["background"] as? String).flatMap { DynamicHelpers.colorFromHex($0) }
                    
                    // Parse font properties
                    let fontSize = dict["fontSize"] as? CGFloat
                    let fontWeight = (dict["fontWeight"] as? String).flatMap { Font.Weight.from(string: $0) }
                    
                    // Parse decorations
                    let underline = dict["underline"] as? Bool ?? false
                    let strikethrough = dict["strikethrough"] as? Bool ?? false
                    
                    // Parse onClick
                    var onClick: (() -> Void)?
                    var onClickActionName: String?
                    if let action = dict["onclick"] as? String {
                        onClickActionName = action
                        onClick = {
                            let context = DynamicEventContext(
                                componentId: component.id,
                                eventType: .onClick,
                                action: action,
                                component: component,
                                viewModel: viewModel
                            )
                            DynamicEventManager.shared.handleEvent(context)
                        }
                    }
                    
                    return PartialAttribute(
                        range: range,
                        fontColor: fontColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        underline: underline,
                        strikethrough: strikethrough,
                        backgroundColor: backgroundColor,
                        onClick: onClick,
                        onClickActionName: onClickActionName
                    )
                } else if let pattern = dict["range"] as? String {
                    // Text pattern
                    let fontColor = (dict["fontColor"] as? String).flatMap { DynamicHelpers.colorFromHex($0) }
                    let backgroundColor = (dict["background"] as? String).flatMap { DynamicHelpers.colorFromHex($0) }
                    let fontSize = dict["fontSize"] as? CGFloat
                    let fontWeight = (dict["fontWeight"] as? String).flatMap { Font.Weight.from(string: $0) }
                    let underline = dict["underline"] as? Bool ?? false
                    let strikethrough = dict["strikethrough"] as? Bool ?? false
                    
                    var onClick: (() -> Void)?
                    var onClickActionName: String?
                    if let action = dict["onclick"] as? String {
                        onClickActionName = action
                        onClick = {
                            let context = DynamicEventContext(
                                componentId: component.id,
                                eventType: .onClick,
                                action: action,
                                component: component,
                                viewModel: viewModel
                            )
                            DynamicEventManager.shared.handleEvent(context)
                        }
                    }
                    
                    return PartialAttribute(
                        textPattern: pattern,
                        fontColor: fontColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        underline: underline,
                        strikethrough: strikethrough,
                        backgroundColor: backgroundColor,
                        onClick: onClick,
                        onClickActionName: onClickActionName
                    )
                }
                return nil
            }
            
            // Use PartialAttributedText component
            return AnyView(
                PartialAttributedText(
                    text,
                    partialAttributes: partialAttributes,
                    fontSize: component.fontSize,
                    fontWeight: component.fontWeight.flatMap { Font.Weight.from(string: $0) },
                    fontColor: DynamicHelpers.colorFromHex(component.fontColor),
                    underline: component.underline == true,
                    strikethrough: component.strikethrough == true,
                    lineSpacing: component.lineHeightMultiple != nil
                        ? (component.lineHeightMultiple! - 1) * (component.fontSize ?? 17)
                        : nil,
                    lineLimit: component.autoShrink == true ? 1 : nil
                )
                .shadow(
                    color: getTextShadowColor(component),
                    radius: getTextShadowRadius(component),
                    x: getTextShadowX(component),
                    y: getTextShadowY(component)
                )
                .padding(component.edgeInset ?? 0)
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
        
        // If linkable is true, detect URLs and make them clickable
        if component.linkable == true {
            // Use attributed string with link detection
            if let attributedString = createLinkableAttributedString(from: text, component: component) {
                return AnyView(
                    Text(attributedString)
                        .modifier(CommonModifiers(component: component, viewModel: viewModel))
                )
            }
        }
        
        // Build the text view with all modifiers applied at once
        var textView = Text(text)
            .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
        
        if let font = DynamicHelpers.fontFromComponent(component) {
            textView = textView.font(font)
        }
        
        return AnyView(
            textView
                .underline(component.underline == true)
                .strikethrough(component.strikethrough == true)
                .lineSpacing(
                    component.lineHeightMultiple != nil
                        ? (component.lineHeightMultiple! - 1) * (component.fontSize ?? 17)
                        : 0
                )
                .minimumScaleFactor(
                    component.autoShrink == true
                        ? (component.minimumScaleFactor ?? 0.5)
                        : (component.minimumScaleFactor ?? 1.0)
                )
                .lineLimit(component.autoShrink == true ? 1 : nil)
                .shadow(
                    color: getTextShadowColor(component),
                    radius: getTextShadowRadius(component),
                    x: getTextShadowX(component),
                    y: getTextShadowY(component)
                )
                .padding(component.edgeInset ?? 0)
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func getTextShadowColor(_ component: DynamicComponent) -> Color {
        if let textShadowValue = component.textShadow?.value {
            if let shadowDict = textShadowValue as? [String: Any] {
                let color = shadowDict["color"] as? String ?? "#000000"
                return DynamicHelpers.colorFromHex(color) ?? .clear
            } else if let shadowArray = textShadowValue as? [Any], shadowArray.count >= 3 {
                let color = (shadowArray.count > 3 ? shadowArray[3] as? String : nil) ?? "#000000"
                return DynamicHelpers.colorFromHex(color) ?? .clear
            }
        }
        return .clear
    }
    
    private static func getTextShadowRadius(_ component: DynamicComponent) -> CGFloat {
        if let textShadowValue = component.textShadow?.value {
            if let shadowDict = textShadowValue as? [String: Any] {
                return CGFloat(shadowDict["radius"] as? Double ?? 0.0)
            } else if let shadowArray = textShadowValue as? [Any], shadowArray.count >= 3 {
                return CGFloat((shadowArray[2] as? Double) ?? 0.0)
            }
        }
        return 0
    }
    
    private static func getTextShadowX(_ component: DynamicComponent) -> CGFloat {
        if let textShadowValue = component.textShadow?.value {
            if let shadowDict = textShadowValue as? [String: Any] {
                return CGFloat(shadowDict["x"] as? Double ?? 0.0)
            } else if let shadowArray = textShadowValue as? [Any], shadowArray.count >= 1 {
                return CGFloat((shadowArray[0] as? Double) ?? 0.0)
            }
        }
        return 0
    }
    
    private static func getTextShadowY(_ component: DynamicComponent) -> CGFloat {
        if let textShadowValue = component.textShadow?.value {
            if let shadowDict = textShadowValue as? [String: Any] {
                return CGFloat(shadowDict["y"] as? Double ?? 0.0)
            } else if let shadowArray = textShadowValue as? [Any], shadowArray.count >= 2 {
                return CGFloat((shadowArray[1] as? Double) ?? 0.0)
            }
        }
        return 0
    }
    
    private static func createLinkableAttributedString(from text: String, component: DynamicComponent) -> AttributedString? {
        var attributedString = AttributedString(text)
        
        // Apply font and color to the entire string
        let font = DynamicHelpers.fontFromComponent(component)
        attributedString.font = font
        
        if let color = DynamicHelpers.colorFromHex(component.fontColor) {
            attributedString.foregroundColor = color
        }
        
        // Detect URLs and make them clickable
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
        
        for match in matches {
            if let range = Range(match.range, in: text),
               let url = match.url {
                if let attributedRange = Range(range, in: attributedString) {
                    attributedString[attributedRange].link = url
                    // Optionally style links differently
                    attributedString[attributedRange].underlineStyle = .single
                }
            }
        }
        
        return attributedString
    }
}