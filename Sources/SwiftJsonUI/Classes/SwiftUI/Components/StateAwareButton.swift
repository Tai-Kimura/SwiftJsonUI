//
//  StateAwareButton.swift
//  SwiftJsonUI
//
//  Button component that tracks pressed and disabled states
//  Supports hilightColor, disabledFontColor, disabledBackground, tapBackground
//  Used by both Static and Dynamic modes
//

import SwiftUI

public struct StateAwareButton: View {
    let component: DynamicComponent
    let viewModel: DynamicViewModel
    let action: () -> Void
    
    @State private var isPressed = false
    
    // Compute if button is disabled
    private var isDisabled: Bool {
        if let enabled = component.enabled {
            if let boolValue = enabled.value as? Bool {
                return !boolValue
            } else if let stringValue = enabled.value as? String {
                return stringValue.lowercased() == "false" || stringValue == "0"
            }
        }
        return false
    }
    
    // Get text color based on state
    private var textColor: Color {
        if isDisabled {
            // Use disabledFontColor if available
            if let disabledColor = component.disabledFontColor {
                return DynamicHelpers.colorFromHex(disabledColor) ?? .gray
            }
            return .gray
        } else if isPressed {
            // Use highlightColor if available when pressed
            if let highlightColor = component.highlightColor {
                return DynamicHelpers.colorFromHex(highlightColor) ?? .white
            }
            return .white
        } else {
            // Normal state - use fontColor
            if let fontColor = component.fontColor {
                return DynamicHelpers.colorFromHex(fontColor) ?? .white
            }
            return .white
        }
    }
    
    // Get background color based on state
    private var backgroundColor: Color {
        if isDisabled {
            // Use disabledBackground if available
            if let disabledBg = component.disabledBackground {
                return DynamicHelpers.colorFromHex(disabledBg) ?? Color.gray.opacity(0.3)
            }
            return Color.gray.opacity(0.3)
        } else if isPressed {
            // Use tapBackground if available when pressed
            if let tapBg = component.tapBackground {
                return DynamicHelpers.colorFromHex(tapBg) ?? Color.blue.opacity(0.8)
            }
            // Darken the normal background when pressed
            if let bg = component.background {
                return (DynamicHelpers.colorFromHex(bg) ?? .blue).opacity(0.8)
            }
            return Color.blue.opacity(0.8)
        } else {
            // Normal state
            if let bg = component.background {
                return DynamicHelpers.colorFromHex(bg) ?? .blue
            }
            return .blue
        }
    }
    
    public var body: some View {
        Button(action: action) {
            Text(component.text ?? "")
                .font(getFont())
                .foregroundColor(textColor)
                .padding(DynamicHelpers.getPadding(from: component))
                .frame(
                    maxWidth: component.width == .infinity ? .infinity : nil,
                    maxHeight: component.height == .infinity ? .infinity : nil
                )
        }
        .frame(
            width: component.width == .infinity || component.width == nil ? nil : component.width,
            height: component.height == .infinity || component.height == nil ? nil : component.height
        )
        .background(backgroundColor)
        .cornerRadius(component.cornerRadius ?? 8)
        .disabled(isDisabled)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Handle tap
                }
        )
    }
    
    private func getFont() -> Font {
        var font: Font = .system(size: component.fontSize ?? 17)
        
        if let fontName = component.font {
            if fontName.lowercased() == "bold" {
                font = font.bold()
            } else {
                font = Font.custom(fontName, size: component.fontSize ?? 17)
            }
        }
        
        if let weight = component.fontWeight {
            switch weight.lowercased() {
            case "bold":
                font = font.bold()
            case "heavy":
                font = font.weight(.heavy)
            case "light":
                font = font.weight(.light)
            case "medium":
                font = font.weight(.medium)
            case "semibold":
                font = font.weight(.semibold)
            case "thin":
                font = font.weight(.thin)
            case "ultralight":
                font = font.weight(.ultraLight)
            case "black":
                font = font.weight(.black)
            default:
                break
            }
        }
        
        return font
    }
}