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

    // MARK: - Simple call: data.handler?()

    /// Call a () -> Void closure from data dictionary
    /// Matches tool pattern: data.onMyClick?()
    static func call(_ bindingExpr: String?, data: [String: Any]) {
        guard let name = extractPropertyName(from: bindingExpr) else { return }
        if let closure = data[name] as? () -> Void {
            closure()
        }
    }

    // MARK: - Call with id: data.handler?("viewId")

    /// Call a (String) -> Void closure with component id
    /// Matches tool pattern: data.onMyClick?("viewId")
    static func callWithId(_ bindingExpr: String?, id: String?, data: [String: Any]) {
        guard let name = extractPropertyName(from: bindingExpr) else { return }

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
        guard let name = extractPropertyName(from: bindingExpr) else { return }

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

    /// Apply onTapGesture if onClick is defined
    /// Matches tool pattern: .onTapGesture { data.onClick?() }
    static func applyOnClick(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        // Skip if component is disabled
        if component.enabled?.value as? Bool == false { return view }

        guard let onClick = component.onClick else { return view }

        // Note: canTap is a UIKit concept. In SwiftUI Dynamic mode,
        // if onClick is explicitly set in JSON, always apply the tap gesture.

        return AnyView(
            view
                .contentShape(Rectangle())
                .onTapGesture {
                    DynamicEventHelper.call(onClick, data: data)
                }
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

    /// Apply onClick + lifecycle events (common pattern for most components)
    static func applyEvents(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        var result = view
        result = applyOnClick(result, component: component, data: data)
        result = applyLifecycleEvents(result, component: component, data: data)
        return result
    }
}
#endif // DEBUG
