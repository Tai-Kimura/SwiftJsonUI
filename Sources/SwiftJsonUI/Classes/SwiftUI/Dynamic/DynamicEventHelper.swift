//
//  DynamicEventHelper.swift
//  SwiftJsonUI
//
//  Direct closure invocation from data dictionary (matches tool-generated code pattern)
//

import SwiftUI
#if DEBUG

/// Calls closures directly from data dictionary, matching tool-generated code pattern:
///   data.onMyClick?()
///   data.onValueChange?("viewId", newValue)
public struct DynamicEventHelper {

    /// Extract property name from @{propertyName} binding syntax
    public static func extractPropertyName(from value: String?) -> String? {
        guard let value = value,
              value.hasPrefix("@{") && value.hasSuffix("}") else {
            return nil
        }
        return String(value.dropFirst(2).dropLast(1))
    }

    /// Resolve a handler reference to the closure name in the data dictionary.
    /// Handler attributes come in two canonical formats
    /// (shared/core/attribute_definitions.json):
    ///   - binding:  "@{handlerName}"  (camelCase attrs, e.g. onClick)
    ///   - selector: "handlerName"     (legacy lowercase attrs, e.g. onclick)
    /// Both resolve to the same data-dict closure in Dynamic mode.
    public static func handlerName(from value: String?) -> String? {
        if let name = extractPropertyName(from: value) { return name }
        guard let value = value, !value.isEmpty, !value.contains("@{") else { return nil }
        return value
    }

    // MARK: - Simple call: data.handler?()

    /// Call a () -> Void closure from data dictionary
    /// Matches tool pattern: data.onMyClick?()
    static func call(_ bindingExpr: String?, data: [String: Any]) {
        guard let name = handlerName(from: bindingExpr) else { return }
        if let closure = data[name] as? () -> Void {
            closure()
        }
    }

    // MARK: - Call with id: data.handler?("viewId")

    /// Call a (String) -> Void closure with component id
    /// Matches tool pattern: data.onMyClick?("viewId")
    static func callWithId(_ bindingExpr: String?, id: String?, data: [String: Any]) {
        guard let name = handlerName(from: bindingExpr) else { return }

        // Try (String) -> Void first
        if let closure = data[name] as? (String) -> Void {
            closure(id ?? "")
            return
        }
        // Fallback to () -> Void
        if let closure = data[name] as? () -> Void {
            closure()
        }
    }

    // MARK: - Call with id and value: data.handler?("viewId", value)

    /// Call a (String, T) -> Void closure with component id and value
    /// Matches tool pattern: data.onValueChange?("viewId", newValue)
    static func callWithValue<T>(_ bindingExpr: String?, id: String?, value: T, data: [String: Any]) {
        guard let name = handlerName(from: bindingExpr) else { return }

        // Try (String, T) -> Void
        if let closure = data[name] as? (String, T) -> Void {
            closure(id ?? "", value)
            return
        }
        // Try (T) -> Void
        if let closure = data[name] as? (T) -> Void {
            closure(value)
            return
        }
        // Fallback to () -> Void
        if let closure = data[name] as? () -> Void {
            closure()
        }
    }

    // MARK: - onClick / onTapGesture support

    /// Whether `canTap` lets the onClick / onclick handler be called: it
    /// gates the handler's call and nothing else — a control's own operation
    /// (a Radio's selection, a Checkbox's value, a Button's press state) is
    /// `enabled`'s. Absent, there is no gate.
    static func tapGateOpen(_ component: DynamicComponent, data: [String: Any]) -> Bool {
        DynamicHelpers.resolveBool(
            component.typedAttributes(CommonAttributes.self).canTap, legacy: nil, data: data
        ) != false
    }

    /// Apply onTapGesture if onClick is defined
    /// Matches tool pattern: .onTapGesture { data.onClick?() }
    static func applyOnClick(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        // Skip if component is disabled
        if component.commonBool(\.enabled) == false { return view }

        let handlers = component.effectiveOnClickHandlers
        guard !handlers.isEmpty else { return view }

        // common.canTap is the SwiftUI tap gate (attribute_definitions.json;
        // on UIKit it is the pressed state instead): false, or a binding that
        // resolves false, shuts the tap and leaves the view as it is. It used
        // to be ignored here, so `canTap: false` still tapped.
        if !tapGateOpen(component, data: data) { return view }

        let tapped = AnyView(
            view
                .contentShape(Rectangle())
                .onTapGesture {
                    // All of them, in declaration order — the array spelling
                    // names a sequence, and codegen emits one call per name.
                    for handler in handlers {
                        DynamicEventHelper.call(handler, data: data)
                    }
                }
        )
        // What VoiceOver is told about the tap (TapAccessibility): a button,
        // one button made of its content, or nothing where it holds a control.
        return TapAccessibility.apply(tapped, component: component)
    }

    // MARK: - onLongPress support

    /// Apply a long-press gesture if onLongPress is defined
    /// (common attribute, binding-only: "onLongPress": "@{handlerName}").
    /// Uses simultaneousGesture so it composes with Button actions and
    /// onClick tap gestures instead of swallowing them.
    static func applyOnLongPress(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        // Skip if component is disabled
        if component.commonBool(\.enabled) == false { return view }

        guard let onLongPress = component.commonAny(\.onLongPress) else { return view }

        return AnyView(
            view
                .contentShape(Rectangle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                        DynamicEventHelper.call(onLongPress, data: data)
                    }
                )
        )
    }

    // MARK: - onPan / onPinch support

    /// Apply a drag gesture if onPan is defined (common attribute,
    /// binding-only: "onPan": "@{handlerName}"). Fires on every drag change
    /// with the cumulative translation (CGSize) since the gesture began;
    /// callWithValue's ladder lets () -> Void handlers ignore the payload.
    static func applyOnPan(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        // Skip if component is disabled
        if component.commonBool(\.enabled) == false { return view }

        guard let onPan = component.commonAny(\.onPan) else { return view }

        return AnyView(
            view
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10).onChanged { value in
                        DynamicEventHelper.callWithValue(onPan, id: component.id, value: value.translation, data: data)
                    }
                )
        )
    }

    /// Apply a pinch gesture if onPinch is defined. Fires on every
    /// magnification change with the cumulative scale factor (CGFloat).
    /// MagnifyGesture is the iOS 17+ replacement for the deprecated
    /// MagnificationGesture — the package floor is iOS 17.
    static func applyOnPinch(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        // Skip if component is disabled
        if component.commonBool(\.enabled) == false { return view }

        guard let onPinch = component.commonAny(\.onPinch) else { return view }

        return AnyView(
            view
                .contentShape(Rectangle())
                .simultaneousGesture(
                    MagnifyGesture().onChanged { value in
                        DynamicEventHelper.callWithValue(onPinch, id: component.id, value: value.magnification, data: data)
                    }
                )
        )
    }

    // MARK: - Lifecycle events

    /// Apply onAppear handler
    static func applyOnAppear(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        guard component.onAppear != nil else { return view }
        return AnyView(
            view.onAppear {
                DynamicEventHelper.call(component.onAppear, data: data)
            }
        )
    }

    /// Apply onDisappear handler
    static func applyOnDisappear(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        guard component.onDisappear != nil else { return view }
        return AnyView(
            view.onDisappear {
                DynamicEventHelper.call(component.onDisappear, data: data)
            }
        )
    }

    /// Apply all lifecycle events (onAppear + onDisappear)
    static func applyLifecycleEvents(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        var result = view
        result = applyOnAppear(result, component: component, data: data)
        result = applyOnDisappear(result, component: component, data: data)
        return result
    }

    /// Apply onClick + onLongPress + onPan + onPinch + lifecycle events
    /// (common pattern for most components)
    static func applyEvents(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        var result = view
        result = applyOnClick(result, component: component, data: data)
        result = applyOnLongPress(result, component: component, data: data)
        result = applyOnPan(result, component: component, data: data)
        result = applyOnPinch(result, component: component, data: data)
        result = applyLifecycleEvents(result, component: component, data: data)
        return result
    }
}

extension DynamicComponent {
    /// Click handler with both canonical spellings resolved:
    /// `onClick` (camelCase, binding format) falls back to the legacy
    /// `onclick` (lowercase, selector format) — attribute_definitions.json
    /// declares both.
    ///
    /// First of `effectiveOnClickHandlers`, kept for the callers that only
    /// ever need one name.
    var effectiveOnClick: String? {
        effectiveOnClickHandlers.first
    }

    /// EVERY handler the click should fire.
    ///
    /// `onclick` is declared `["string", "array"]`, and the array spelling
    /// names several selectors: base_view_converter.rb:658 emits
    /// `names = value.is_a?(Array) ? value : [value]` and calls all of them
    /// in one `.onTapGesture`. Reading it as `as? String` returned nil for
    /// the array, so dynamic fired NOTHING where codegen fired two handlers.
    ///
    /// `onClick` (camelCase) is binding-only — one `@{handler}` — so it
    /// contributes at most one name and wins when both are declared, which
    /// is the precedence the single-value accessor always had.
    ///
    /// Only names (TapAccessibility.namesAMethod): an empty or blank onClick
    /// leaves the tap to onclick, a blank element is not called, and none at
    /// all is no tap — `applyOnClick` attaches nothing.
    var effectiveOnClickHandlers: [String] {
        if let onClick = commonAny(\.onClick), TapAccessibility.namesAMethod(onClick) { return [onClick] }
        return TapAccessibility.handlerValues(typedAttributes(CommonAttributes.self).onclick)
    }
}
#endif // DEBUG
