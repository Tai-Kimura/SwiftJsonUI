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
        
        var textView = Text(text)
            .font(DynamicHelpers.fontFromComponent(component))
            .foregroundColor(DynamicHelpers.colorFromHex(component.fontColor) ?? .primary)
        
        // Apply underline
        if component.underline == true {
            textView = textView.underline()
        }
        
        // Apply strikethrough
        if component.strikethrough == true {
            textView = textView.strikethrough()
        }
        
        // Apply line height multiple
        if let lineHeightMultiple = component.lineHeightMultiple {
            let fontSize = component.fontSize ?? 17
            let lineSpacing = (lineHeightMultiple - 1) * fontSize
            textView = textView.lineSpacing(lineSpacing)
        }
        
        // Apply auto shrink and minimum scale factor
        if component.autoShrink == true {
            // Use minimumScaleFactor if provided, otherwise default to 0.5
            let scaleFactor = component.minimumScaleFactor ?? 0.5
            textView = textView
                .minimumScaleFactor(scaleFactor)
                .lineLimit(1)  // Auto shrink typically works with single line
        } else if let minimumScaleFactor = component.minimumScaleFactor {
            // If only minimumScaleFactor is specified without autoShrink
            textView = textView.minimumScaleFactor(minimumScaleFactor)
        }
        
        // Apply text shadow
        if let textShadowValue = component.textShadow?.value {
            if let shadowDict = textShadowValue as? [String: Any] {
                let color = shadowDict["color"] as? String ?? "#000000"
                let radius = CGFloat(shadowDict["radius"] as? Double ?? 2.0)
                let x = CGFloat(shadowDict["x"] as? Double ?? 0.0)
                let y = CGFloat(shadowDict["y"] as? Double ?? 0.0)
                
                textView = textView.shadow(
                    color: DynamicHelpers.colorFromHex(color) ?? .black,
                    radius: radius,
                    x: x,
                    y: y
                )
            } else if let shadowArray = textShadowValue as? [Any], shadowArray.count >= 3 {
                // Support array format: [x, y, radius, color?]
                let x = CGFloat((shadowArray[0] as? Double) ?? 0.0)
                let y = CGFloat((shadowArray[1] as? Double) ?? 0.0)
                let radius = CGFloat((shadowArray[2] as? Double) ?? 2.0)
                let color = (shadowArray.count > 3 ? shadowArray[3] as? String : nil) ?? "#000000"
                
                textView = textView.shadow(
                    color: DynamicHelpers.colorFromHex(color) ?? .black,
                    radius: radius,
                    x: x,
                    y: y
                )
            }
        }
        
        // Apply text alignment
        if let textAlign = component.textAlign {
            textView = applyTextAlignment(textView, alignment: textAlign)
        }
        
        // Apply edgeInset (text padding)
        if let edgeInset = component.edgeInset {
            textView = textView.padding(edgeInset)
        }
        
        // Apply common modifiers
        return AnyView(
            textView
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    
    private static func applyTextAlignment(_ text: Text, alignment: String) -> Text {
        // Text alignment is handled by the frame modifier in CommonModifiers
        return text
    }
    
    private static func createLinkableAttributedString(from text: String, component: DynamicComponent) -> AttributedString? {
        var attributedString = AttributedString(text)
        
        // Apply font and color to the entire string
        if let font = DynamicHelpers.fontFromComponent(component) {
            attributedString.font = font
        }
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

