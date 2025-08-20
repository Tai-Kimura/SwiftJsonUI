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
           let partialAttributes = partialAttributesValue as? [[String: Any]],
           !partialAttributes.isEmpty {
            // Create attributed string with partial attributes
            let result = createAttributedStringWithPartialAttributes(
                from: text,
                partialAttributes: partialAttributes,
                component: component,
                viewModel: viewModel
            )
            
            return AnyView(
                Text(result.attributedString)
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
                    .environment(\.openURL, OpenURLAction { url in
                        // Handle app:// URLs for onclick actions
                        if url.scheme == "app", let host = url.host {
                            // Check if this is an onClick action
                            if let action = result.urlMapping[host] {
                                action()
                                return .handled
                            }
                            return .handled
                        }
                        return .systemAction
                    })
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
    
    private static func createAttributedStringWithPartialAttributes(
        from text: String,
        partialAttributes: [[String: Any]],
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> (attributedString: AttributedString, urlMapping: [String: () -> Void]) {
        var attributedString = AttributedString(text)
        var urlMapping: [String: () -> Void] = [:]
        
        // Apply base font and color to the entire string
        if let font = DynamicHelpers.fontFromComponent(component) {
            attributedString.font = font
        }
        
        if let color = DynamicHelpers.colorFromHex(component.fontColor) {
            attributedString.foregroundColor = color
        }
        
        // Apply partial attributes
        for partial in partialAttributes {
            // Get the range - can be either [Int, Int] array or String pattern
            var startOffset: Int
            var endOffset: Int
            
            if let rangeArray = partial["range"] as? [Int], rangeArray.count == 2 {
                startOffset = rangeArray[0]
                endOffset = rangeArray[1]
            } else if let pattern = partial["range"] as? String {
                // Find the pattern in the text
                guard let range = text.range(of: pattern) else {
                    continue
                }
                startOffset = text.distance(from: text.startIndex, to: range.lowerBound)
                endOffset = text.distance(from: text.startIndex, to: range.upperBound)
            } else {
                continue
            }
            
            // Convert character offsets to String.Index
            guard let startIndex = text.index(text.startIndex, offsetBy: startOffset, limitedBy: text.endIndex),
                  let endIndex = text.index(text.startIndex, offsetBy: endOffset, limitedBy: text.endIndex),
                  startIndex < endIndex else {
                continue
            }
            
            let range = startIndex..<endIndex
            
            // Convert to AttributedString range
            guard let attributedRange = Range(range, in: attributedString) else {
                continue
            }
            
            // Apply fontColor
            if let fontColorHex = partial["fontColor"] as? String,
               let color = DynamicHelpers.colorFromHex(fontColorHex) {
                attributedString[attributedRange].foregroundColor = color
            }
            
            // Apply fontSize
            if let fontSize = partial["fontSize"] as? CGFloat {
                attributedString[attributedRange].font = .system(size: fontSize)
            }
            
            // Apply fontWeight
            if let fontWeight = partial["fontWeight"] as? String {
                let weight = DynamicHelpers.fontWeightFromString(fontWeight)
                if let currentFont = attributedString[attributedRange].font {
                    attributedString[attributedRange].font = currentFont.weight(weight)
                } else {
                    attributedString[attributedRange].font = .system(size: 17, weight: weight)
                }
            }
            
            // Apply underline
            if let underline = partial["underline"] {
                if underline as? Bool == true {
                    attributedString[attributedRange].underlineStyle = .single
                } else if let underlineDict = underline as? [String: Any] {
                    // Could handle lineStyle here if needed
                    attributedString[attributedRange].underlineStyle = .single
                }
            }
            
            // Apply strikethrough
            if partial["strikethrough"] as? Bool == true {
                attributedString[attributedRange].strikethroughStyle = .single
            }
            
            // Apply background color
            if let backgroundHex = partial["background"] as? String,
               let backgroundColor = DynamicHelpers.colorFromHex(backgroundHex) {
                attributedString[attributedRange].backgroundColor = backgroundColor
            }
            
            // Handle onclick (as link)
            if let onclick = partial["onclick"] as? String {
                // Generate a unique ID for this onClick action
                let actionId = UUID().uuidString
                // Store the mapping for this onClick
                urlMapping[actionId] = {
                    viewModel.handleEvent(onclick, data: [:])
                }
                // Create a custom URL scheme for internal actions
                if let url = URL(string: "app://\(actionId)") {
                    attributedString[attributedRange].link = url
                }
            }
        }
        
        return (attributedString, urlMapping)
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