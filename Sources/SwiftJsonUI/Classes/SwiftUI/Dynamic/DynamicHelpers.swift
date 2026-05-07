//
//  DynamicHelpers.swift
//  SwiftJsonUI
//
//  Helper functions for dynamic views
//

import SwiftUI
#if DEBUG


// MARK: - Helper Functions
public struct DynamicHelpers {

    // MARK: - Variable Processing (moved from DynamicViewModel)

    /// Process text with @{} variable placeholders
    public static func processText(_ text: String?, data: [String: Any]) -> String {
        guard let text = text else { return "" }
        guard text.contains("@{") else { return text }

        var result = text
        let pattern = "@\\{([^}]+)\\}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            for match in matches.reversed() {
                if let range = Range(match.range, in: text),
                   let varRange = Range(match.range(at: 1), in: text) {
                    let varName = String(text[varRange])
                    let cleanVarName = varName
                        .replacingOccurrences(of: " ?? ''", with: "")
                        .replacingOccurrences(of: "?", with: "")
                        .trimmingCharacters(in: .whitespaces)

                    let value: String
                    if let dataValue = data[cleanVarName] {
                        // Unwrap SwiftUI.Binding if present (from toDictionary(binding:))
                        if let binding = dataValue as? SwiftUI.Binding<String> {
                            value = binding.wrappedValue
                        } else if let binding = dataValue as? SwiftUI.Binding<Int> {
                            value = String(binding.wrappedValue)
                        } else if let binding = dataValue as? SwiftUI.Binding<Double> {
                            value = String(binding.wrappedValue)
                        } else if let binding = dataValue as? SwiftUI.Binding<Bool> {
                            value = String(binding.wrappedValue)
                        } else {
                            value = String(describing: dataValue)
                        }
                        Logger.debug("[DynamicHelpers] processText: '\(cleanVarName)' = '\(value)'")
                    } else {
                        value = ""
                        Logger.debug("[DynamicHelpers] processText: '\(cleanVarName)' NOT FOUND in data. Available keys: \(Array(data.keys))")
                    }
                    result.replaceSubrange(range, with: value)
                }
            }
        }
        return result
    }

    /// Process any value that might contain @{} reference
    /// Automatically unwraps SwiftUI.Binding<T> from data dictionary
    public static func processValue<T>(_ value: Any?, data: [String: Any]) -> T? {
        guard let value = value else { return nil }
        if let stringValue = value as? String {
            if stringValue.hasPrefix("@{") && stringValue.hasSuffix("}") {
                let startIndex = stringValue.index(stringValue.startIndex, offsetBy: 2)
                let endIndex = stringValue.index(stringValue.endIndex, offsetBy: -1)
                let varName = String(stringValue[startIndex..<endIndex])
                // Unwrap SwiftUI.Binding if present
                if let binding = data[varName] as? SwiftUI.Binding<T> {
                    return binding.wrappedValue
                }
                return data[varName] as? T
            }
        }
        return value as? T
    }

    public static func processBool(_ value: Any?, data: [String: Any]) -> Bool { processValue(value, data: data) ?? false }
    public static func processDouble(_ value: Any?, data: [String: Any]) -> Double { processValue(value, data: data) ?? 0.0 }
    public static func processInt(_ value: Any?, data: [String: Any]) -> Int { processValue(value, data: data) ?? 0 }
    public static func processString(_ value: Any?, data: [String: Any]) -> String? { processValue(value, data: data) }

    /// Handle action by posting notification
    public static func handleAction(_ action: String?) {
        guard let action = action else { return }
        Logger.debug("[DynamicView] Action: \(action)")
        NotificationCenter.default.post(
            name: Notification.Name("DynamicViewAction"),
            object: nil,
            userInfo: ["action": action]
        )
    }

    // MARK: - Wrapper methods for JSON data transformations (delegate to DynamicDecodingHelper)

    public static func fontFromComponent(_ component: DynamicComponent) -> Font? {
        return DynamicDecodingHelper.fontFromComponent(component)
    }

    /// Get font from component with data binding support for the `font` attribute.
    /// If `font` is a binding expression like @{fontProp}, resolves the font name/weight from data.
    public static func fontFromComponent(_ component: DynamicComponent, data: [String: Any]) -> Font? {
        // Check if font attribute is a binding expression
        if let fontRaw = component.rawData["font"] as? String,
           fontRaw.hasPrefix("@{") && fontRaw.hasSuffix("}") {
            let propertyName = String(fontRaw.dropFirst(2).dropLast(1))
            var resolvedFontName: String? = nil

            // Try to get font name from data
            if let binding = data[propertyName] as? SwiftUI.Binding<String> {
                resolvedFontName = binding.wrappedValue
            } else if let fontString = data[propertyName] as? String {
                resolvedFontName = fontString
            }

            if let fontName = resolvedFontName {
                let config = SwiftJsonUIConfiguration.shared
                let size = component.fontSize ?? config.font.size

                // Weight-only font names
                let weightNames = ["bold", "semibold", "medium", "light", "thin", "ultralight", "heavy", "black", "normal", "regular"]
                let fontWeight: Font.Weight = {
                    switch fontName.lowercased() {
                    case "bold": return .bold
                    case "semibold": return .semibold
                    case "medium": return .medium
                    case "light": return .light
                    case "thin": return .thin
                    case "ultralight": return .ultraLight
                    case "heavy": return .heavy
                    case "black": return .black
                    case "normal", "regular": return .regular
                    default: return config.font.weight
                    }
                }()

                if weightNames.contains(fontName.lowercased()) {
                    return .system(size: size, weight: fontWeight)
                } else {
                    return .custom(fontName, size: size)
                }
            }
        }

        // No binding or binding not resolved, fall back to standard resolution
        return DynamicDecodingHelper.fontFromComponent(component)
    }

    public static func getColor(_ identifier: String?) -> Color? {
        return DynamicDecodingHelper.getColor(identifier)
    }

    /// Get color with data binding support
    /// If identifier is a binding expression like @{propertyName}, resolves from data dictionary
    public static func getColor(_ identifier: String?, data: [String: Any]) -> Color? {
        guard let identifier = identifier else { return nil }

        // Check if it's a binding expression
        if identifier.hasPrefix("@{") && identifier.hasSuffix("}") {
            let propertyName = String(identifier.dropFirst(2).dropLast(1))
            // Try SwiftUI.Binding<Color>
            if let binding = data[propertyName] as? SwiftUI.Binding<Color> {
                return binding.wrappedValue
            }
            // Try to get Color from data
            if let color = data[propertyName] as? Color {
                return color
            }
            // Try SwiftUI.Binding<String> and convert
            if let binding = data[propertyName] as? SwiftUI.Binding<String> {
                return DynamicDecodingHelper.getColor(binding.wrappedValue)
            }
            // Try to get color string from data and convert
            if let colorString = data[propertyName] as? String {
                return DynamicDecodingHelper.getColor(colorString)
            }
            return nil
        }

        // Not a binding, use normal color resolution
        return DynamicDecodingHelper.getColor(identifier)
    }

    public static func getContentMode(from component: DynamicComponent) -> ContentMode {
        return DynamicDecodingHelper.toContentMode(component.contentMode)
    }

    public static func getNetworkImageContentMode(from component: DynamicComponent) -> NetworkImage.ContentMode {
        return DynamicDecodingHelper.toNetworkImageContentMode(component.contentMode)
    }

    public static func getRenderingMode(from component: DynamicComponent) -> Image.TemplateRenderingMode? {
        return DynamicDecodingHelper.toRenderingMode(component.renderingMode)
    }

    public static func getIconPosition(from component: DynamicComponent) -> IconLabelView.IconPosition {
        return DynamicDecodingHelper.toIconPosition(component.iconPosition)
    }

    public static func getTextAlignment(from component: DynamicComponent) -> TextAlignment {
        return DynamicDecodingHelper.toTextAlignment(component.textAlign)
    }

    // Keep old methods for backward compatibility (deprecated)
    @available(*, deprecated, renamed: "getContentMode(from:)")
    public static func contentModeFromString(_ mode: String?) -> ContentMode {
        return DynamicDecodingHelper.toContentMode(mode)
    }

    @available(*, deprecated, renamed: "getNetworkImageContentMode(from:)")
    public static func networkImageContentMode(_ mode: String?) -> NetworkImage.ContentMode {
        return DynamicDecodingHelper.toNetworkImageContentMode(mode)
    }

    @available(*, deprecated, renamed: "getRenderingMode(from:)")
    public static func renderingModeFromString(_ mode: String?) -> Image.TemplateRenderingMode? {
        return DynamicDecodingHelper.toRenderingMode(mode)
    }

    @available(*, deprecated, renamed: "getIconPosition(from:)")
    public static func iconPositionFromString(_ position: String?) -> IconLabelView.IconPosition {
        return DynamicDecodingHelper.toIconPosition(position)
    }

    @available(*, deprecated, renamed: "getTextAlignment(from:)")
    public static func textAlignmentFromString(_ alignment: String?) -> TextAlignment {
        return DynamicDecodingHelper.toTextAlignment(alignment)
    }

    // Unified method to get padding EdgeInsets from component
    // skipInsetPadding: When true, insetHorizontal/insetVertical are not added to padding (for Collection which handles them separately)
    public static func getPadding(from component: DynamicComponent, skipInsetPadding: Bool = false) -> EdgeInsets {
        var resultPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        // Check for paddings array or value（UIKitに合わせてpaddingsに統一）
        if let paddingInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.paddings) {
            resultPadding = paddingInsets
        } else {
            // Fallback to individual padding properties (UIKitに合わせてpaddingTop形式に統一)
            // RTL-aware: paddingStart/paddingEnd take precedence over paddingLeft/paddingRight
            let top = component.paddingTop ?? 0
            let leading = component.paddingStart ?? component.paddingLeft ?? 0
            let bottom = component.paddingBottom ?? 0
            let trailing = component.paddingEnd ?? component.paddingRight ?? 0

            resultPadding = EdgeInsets(
                top: top,
                leading: leading,
                bottom: bottom,
                trailing: trailing
            )
        }

        // Apply insets if present (additive) - skip if skipInsetPadding is true
        if !skipInsetPadding {
            if let insetInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.insets) {
                resultPadding.top += insetInsets.top
                resultPadding.leading += insetInsets.leading
                resultPadding.bottom += insetInsets.bottom
                resultPadding.trailing += insetInsets.trailing
            }

            // Apply insetHorizontal if present (additive)
            if let value = component.insetHorizontal {
                resultPadding.leading += value
                resultPadding.trailing += value
            }

            // Apply insetVertical if present (additive)
            if let value = component.insetVertical {
                resultPadding.top += value
                resultPadding.bottom += value
            }
        }

        return resultPadding
    }

    // Unified method to get margins EdgeInsets from component
    // Supports binding expressions like @{propertyName} which can be resolved via data dictionary
    public static func getMargins(from component: DynamicComponent, data: [String: Any] = [:]) -> EdgeInsets {
        // Check for margins array or value
        if let marginInsets = DynamicDecodingHelper.edgeInsetsFromAnyCodable(component.margins) {
            return marginInsets
        }

        // Fallback to individual margin properties
        // RTL-aware: startMargin/endMargin take precedence over leftMargin/rightMargin
        let top = DynamicDecodingHelper.marginValueToCGFloat(component.topMargin, data: data)
        let leading = DynamicDecodingHelper.marginValueToCGFloat(component.startMargin ?? component.leftMargin, data: data)
        let bottom = DynamicDecodingHelper.marginValueToCGFloat(component.bottomMargin, data: data)
        let trailing = DynamicDecodingHelper.marginValueToCGFloat(component.endMargin ?? component.rightMargin, data: data)

        return EdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }

    // Get background color from component
    public static func getBackground(from component: DynamicComponent) -> Color {
        return DynamicDecodingHelper.getColor(component.background) ?? .clear
    }

    // Get opacity from component
    public static func getOpacity(from component: DynamicComponent) -> Double {
        if let opacity = component.opacity {
            return Double(opacity)
        }
        if let alpha = component.alpha {
            return Double(alpha)
        }
        return 1.0
    }

    // Check if component should be hidden
    public static func isHidden(_ component: DynamicComponent) -> Bool {
        return component.hidden == true || component.visibility == "gone"
    }

    // Convert font weight string to Font.Weight
    public static func fontWeightFromString(_ weight: String?) -> Font.Weight {
        switch weight?.lowercased() {
        case "bold":
            return .bold
        case "semibold":
            return .semibold
        case "medium":
            return .medium
        case "light":
            return .light
        case "thin":
            return .thin
        case "ultralight":
            return .ultraLight
        case "heavy":
            return .heavy
        case "black":
            return .black
        default:
            return .regular
        }
    }
}

// MARK: - Conditional View Extension
extension View {
    /// Apply a transform only when the optional value is non-nil
    @ViewBuilder
    func ifLet<T, Result: View>(_ value: T?, @ViewBuilder transform: (Self, T) -> Result) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

#endif // DEBUG
