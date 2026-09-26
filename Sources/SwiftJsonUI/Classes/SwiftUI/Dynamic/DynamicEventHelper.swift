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
    /// Both resolve to the same data-dict closure in Dynamic mode. A `:` —
    /// UIKit's sender mark (`handlerName:`), which means nothing here — is
    /// not part of the name (4f's ruling on
    /// control-onclick-is-called-differently-on-every-path, 1.9.0; kjui and
    /// KJUI Dynamic strip it, sjui reads the name without it): `handlerName:`
    /// looked up a closure named with the colon, and nothing was called.
    public static func handlerName(from value: String?) -> String? {
        if let name = extractPropertyName(from: value) { return withoutSenderMark(name) }
        guard let value = value, !value.isEmpty, !value.contains("@{") else { return nil }
        return withoutSenderMark(value)
    }

    private static func withoutSenderMark(_ name: String) -> String? {
        let bare = name.replacingOccurrences(of: ":", with: "")
        return bare.isEmpty ? nil : bare
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

    /// A handler that takes no value — a tap, a control's or a Button's
    /// onClick, a long press, onAppear / onDisappear, a Web's onLoadFailed —
    /// called as the closure the data holds asks (4f's ruling on
    /// control-onclick-is-called-differently-on-every-path, 1.9.0):
    /// `(String) -> Void` with the viewId (LayoutPath.viewId: the id, else
    /// the drawn type and the position), `() -> Void` with nothing — what the
    /// codegen writes from the declaration (sjui no_value_call,
    /// get_event_handler_invocation). They were called through `call`, which
    /// calls `() -> Void` only: a `(String)` handler was silently not called.
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
    ///
    /// `userInteractionEnabled` shuts it as canTap does (the tap rule,
    /// TapAccessibility): false, or a binding resolving false, on the
    /// component or on one around it (`interactionStoppedAround`). Its
    /// `.allowsHitTesting` stopped a touch, not VoiceOver, which activates a
    /// Button through its action and announced the tap as a button.
    static func tapGateOpen(_ component: DynamicComponent, data: [String: Any]) -> Bool {
        let attributes = component.typedAttributes(CommonAttributes.self)
        return DynamicHelpers.resolveBool(attributes.canTap, legacy: nil, data: data) != false
            && DynamicHelpers.resolveBool(attributes.userInteractionEnabled, legacy: nil, data: data) != false
            && !component.interactionStoppedAround
    }

    // MARK: - A control's onClick: from its own operation

    /// Types whose declared onClick is not a tap on the view. A control —
    /// Switch / Toggle, CheckBox, Radio, Segment, Slider, SelectBox — calls it
    /// from its own operation (`operationClick`); a text field does not call
    /// it at all, its tap focuses it. `applyOnClick` attaches nothing to them:
    /// a tap around a control either never fires (the control's own gesture
    /// wins) or fires beside the operation, so a CheckBox's check and a group
    /// Radio's selection called the handler while a Switch's, a Segment's, a
    /// Slider's and a SelectBox's did not (ticket
    /// control-onclick-is-called-differently-on-every-path, measured with
    /// ConformanceHost OnClickProbeUITests). The same list as kjui_tools'
    /// operation_click_call and the sjui codegen.
    static let operationClickTypes: Set<String> = [
        "switch", "toggle", "checkbox", "check", "radio", "segment", "slider", "selectbox",
        "textfield", "edittext", "input", "textview"
    ]

    static func callsOnClickFromItsOperation(_ component: DynamicComponent) -> Bool {
        guard let type = component.type?.lowercased() else { return false }
        return operationClickTypes.contains(type)
    }

    /// A control's declared onClick, for its operation to call after its own
    /// update (and after onValueChange): every handler in declaration order,
    /// behind `canTap` — the gate on the call, read when the call is made.
    /// `enabled: false` is the control's own: it stops the operation, and so
    /// the call. Nil when there is no handler.
    static func operationClick(_ component: DynamicComponent, data: [String: Any]) -> (() -> Void)? {
        let handlers = component.effectiveOnClickHandlers
        guard !handlers.isEmpty else { return nil }
        return {
            guard tapGateOpen(component, data: data) else { return }
            for handler in handlers {
                DynamicEventHelper.callWithId(handler, id: LayoutPath.viewId(of: component), data: data)
            }
        }
    }

    /// `binding`, with `onValueChange` after each of the control's own writes
    /// that changes the value — the user's operation. A view model's change
    /// never goes through the control's binding, so it reports nothing
    /// (4f's ruling: the control's update, then onValueChange, then onClick,
    /// all from the user's operation; kjui and KotlinJsonUI's Dynamic call it
    /// from the operation only). The bound paths observed the value with
    /// `.onChange(of:)`, which ran on the next update — after the call — and
    /// for the view model's writes as well.
    static func reporting<Value: Equatable>(
        _ onValueChange: ((Value) -> Void)?,
        after binding: SwiftUI.Binding<Value>
    ) -> SwiftUI.Binding<Value> {
        guard let onValueChange else { return binding }
        return SwiftUI.Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                let changed = newValue != binding.wrappedValue
                binding.wrappedValue = newValue
                if changed { onValueChange(newValue) }
            }
        )
    }

    /// `binding`, with `click` after each of the control's own writes — the
    /// user's operation, and not the view model's change, which never goes
    /// through the control's binding.
    static func calling<Value>(_ click: (() -> Void)?, after binding: SwiftUI.Binding<Value>) -> SwiftUI.Binding<Value> {
        guard let click else { return binding }
        return SwiftUI.Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = newValue
                click()
            }
        )
    }

    /// Apply onTapGesture if onClick is defined
    /// Matches tool pattern: .onTapGesture { data.onClick?() }
    static func applyOnClick(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        // Skip if component is disabled
        if component.commonBool(\.enabled) == false { return view }

        // A control calls its onClick from its own operation, and a text
        // field not at all (operationClickTypes): no tap here.
        if callsOnClickFromItsOperation(component) { return view }

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
                        DynamicEventHelper.callWithId(handler, id: LayoutPath.viewId(of: component), data: data)
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
                        DynamicEventHelper.callWithId(onLongPress, id: LayoutPath.viewId(of: component), data: data)
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
                        DynamicEventHelper.callWithValue(onPan, id: LayoutPath.viewId(of: component), value: value.translation, data: data)
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
                        DynamicEventHelper.callWithValue(onPinch, id: LayoutPath.viewId(of: component), value: value.magnification, data: data)
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
                DynamicEventHelper.callWithId(component.onAppear, id: LayoutPath.viewId(of: component), data: data)
            }
        )
    }

    /// Apply onDisappear handler
    static func applyOnDisappear(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        guard component.onDisappear != nil else { return view }
        return AnyView(
            view.onDisappear {
                DynamicEventHelper.callWithId(component.onDisappear, id: LayoutPath.viewId(of: component), data: data)
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
        if !tabViewOperationsShut(component, data: data) {
            result = applyOnClick(result, component: component, data: data)
            result = applyOnLongPress(result, component: component, data: data)
            result = applyOnPan(result, component: component, data: data)
            result = applyOnPinch(result, component: component, data: data)
        }
        result = applyLifecycleEvents(result, component: component, data: data)
        return result
    }

    /// A TabView is not `.disabled` by its `enabled` (applyDisabled: it stops
    /// the tab items, not what a tab shows), so its own tap and gestures
    /// follow a bound `enabled` here — a literal false already attaches none
    /// (each apply reads it). Its lifecycle events are not operations.
    static func tabViewOperationsShut(_ component: DynamicComponent, data: [String: Any]) -> Bool {
        DynamicModifierHelper.isTabView(component)
            && DynamicModifierHelper.enabledBinding(component, data: data)?.wrappedValue == false
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
