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

    /// Process text with @{} variable placeholders.
    /// Canonical mixed-text interpolation (binding_semantics.json `text`
    /// context) — flat-first / dot-path / bracket-index lookup, `??`
    /// defaults, empty string per unresolved occurrence. One implementation:
    /// DynamicBindingResolver.interpolate.
    public static func processText(_ text: String?, data: [String: Any]) -> String {
        guard let text = text else { return "" }
        return DynamicBindingResolver.interpolate(text, data: data)
    }

    /// Process any value that might contain @{} reference
    /// Automatically unwraps SwiftUI.Binding<T> from data dictionary
    public static func processValue<T>(_ value: Any?, data: [String: Any]) -> T? {
        guard let value = value else { return nil }
        if let stringValue = value as? String,
           let inner = DynamicBindingResolver.inner(of: stringValue) {
            return DynamicBindingResolver.resolveTyped(expression: inner, data: data)
        }
        return value as? T
    }

    public static func processBool(_ value: Any?, data: [String: Any]) -> Bool {
        if let stringValue = value as? String,
           let inner = DynamicBindingResolver.inner(of: stringValue) {
            return DynamicBindingResolver.resolveBool(expression: inner, data: data) ?? false
        }
        return DynamicBindingResolver.coerceBool(value) ?? false
    }

    public static func processDouble(_ value: Any?, data: [String: Any]) -> Double {
        if let stringValue = value as? String,
           let inner = DynamicBindingResolver.inner(of: stringValue) {
            return DynamicBindingResolver.resolveDouble(expression: inner, data: data) ?? 0.0
        }
        return DynamicBindingResolver.coerceDouble(value) ?? 0.0
    }

    public static func processInt(_ value: Any?, data: [String: Any]) -> Int {
        if let stringValue = value as? String,
           let inner = DynamicBindingResolver.inner(of: stringValue) {
            return DynamicBindingResolver.resolveInt(expression: inner, data: data) ?? 0
        }
        if let int = value as? Int { return int }
        return DynamicBindingResolver.coerceDouble(value).flatMap { Int(exactly: $0.rounded()) } ?? 0
    }

    public static func processString(_ value: Any?, data: [String: Any]) -> String? {
        guard let value = value else { return nil }
        if let stringValue = value as? String {
            if let inner = DynamicBindingResolver.inner(of: stringValue) {
                return DynamicBindingResolver.resolveString(expression: inner, data: data)
            }
            return stringValue
        }
        return value as? String
    }

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
           let fontInner = DynamicBindingResolver.inner(of: fontRaw) {
            // Canonical value-context resolution (flat / dot-path / default);
            // Binding<String> unwraps at the value layer.
            let resolvedFontName = DynamicBindingResolver.resolveString(
                expression: fontInner, data: data)

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
        if let inner = DynamicBindingResolver.inner(of: identifier) {
            let expression = DynamicBindingResolver.parse(inner)
            if !expression.negated,
               let raw = DynamicBindingResolver.lookupRaw(path: expression.path, in: data) {
                // Color-typed values are checked at the value layer (they
                // have no canonical string form).
                if let binding = raw as? SwiftUI.Binding<Color> {
                    return binding.wrappedValue
                }
                if let color = DynamicBindingResolver.unwrap(raw) as? Color {
                    return color
                }
                if let colorString = DynamicBindingResolver.stringify(raw) {
                    return DynamicDecodingHelper.getColor(colorString)
                }
            }
            if case .string(let fallback)? = expression.defaultLiteral {
                return DynamicDecodingHelper.getColor(fallback)
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

    // MARK: - Binding-capable common-attribute resolution
    //
    // The generated `CommonAttributes` (built from the component's raw JSON via
    // `component.typedAttributes(...)`) exposes number|binding / boolean|binding
    // attrs as `AttrValue<Double>?` / `AttrValue<Bool>?`. When the layout wrote
    // a `@{binding}` string, the legacy typed slot on `DynamicComponent` is nil
    // (the tolerant decode swallowed the type mismatch); the binding must be
    // resolved from `data` at render time. These mirror
    // CollectionConverter.resolveGlobalColumns' `.value` / `.binding` handling.

    /// Resolve an `AttrValue<Double>?` (number|binding) to a CGFloat.
    /// - `.value(n)`   → the literal.
    /// - `.binding(e)` → `data[e]` unwrapped (Double / CGFloat / Int / NSNumber /
    ///   `SwiftUI.Binding<Double>`), or `legacy` when the binding is unresolved.
    /// - `nil`         → `legacy` (the value the legacy typed decode captured for
    ///   a plain-number layout).
    public static func resolveNumber(
        _ attr: AttrValue<Double>?,
        legacy: CGFloat?,
        data: [String: Any]
    ) -> CGFloat? {
        switch attr {
        case .some(.value(let number)):
            return CGFloat(number)
        case .some(.binding(let expression)):
            if let resolved = DynamicBindingResolver.resolveDouble(expression: expression, data: data) {
                return CGFloat(resolved)
            }
            return legacy
        case nil:
            return legacy
        }
    }

    /// Resolve an `AttrValue<Bool>?` (boolean|binding) to a Bool?.
    /// Same shape as `resolveNumber`; a `@{!prop}` negation is honored.
    public static func resolveBool(
        _ attr: AttrValue<Bool>?,
        legacy: Bool?,
        data: [String: Any]
    ) -> Bool? {
        switch attr {
        case .some(.value(let flag)):
            return flag
        case .some(.binding(let expression)):
            if let resolved = DynamicBindingResolver.resolveBool(expression: expression, data: data) {
                return resolved
            }
            return legacy
        case nil:
            return legacy
        }
    }

    /// Unwrap a data-dictionary value to a Double (Binding / numeric types).
    private static func unwrapDouble(_ raw: Any?) -> Double? {
        guard let value = DynamicBindingResolver.unwrap(raw) else { return nil }
        if let f = value as? CGFloat { return Double(f) }
        if let n = value as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() {
            return n.doubleValue
        }
        return nil
    }

    /// Resolve the effective `weight` (number|binding) for a component.
    /// `CommonAttributes.weight` is `AttrValue<Any>?` (passthrough coercion),
    /// so a literal number arrives as `.value(<NSNumber/Int/Double>)` and a
    /// `@{binding}` as `.binding(expr)`. Returns the resolved CGFloat, or the
    /// legacy typed `component.weight` when there is no binding / it is
    /// unresolved. Mirrors the weight read the WeightedStack / converters do.
    public static func resolveWeight(from component: DynamicComponent, data: [String: Any]) -> CGFloat? {
        let weightAttr = component.typedAttributes(CommonAttributes.self).weight
        switch weightAttr {
        case .some(.value(let raw)):
            if let number = unwrapDouble(raw) { return CGFloat(number) }
            return component.weight
        case .some(.binding(let expression)):
            if let number = DynamicBindingResolver.resolveDouble(expression: expression, data: data) {
                return CGFloat(number)
            }
            return component.weight
        case nil:
            return component.weight
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
