//
//  TypedAttributes.swift
//  SwiftJsonUI
//
//  Bridge between the generated typed-attribute extraction structs
//  (Dynamic/Generated/Attributes/, emitted by `jui generate
//  attr-bindings --lang swift` from shared/core/attribute_definitions.json)
//  and the Dynamic converters.
//
//  Converters obtain a typed view of a component's attributes through
//  `component.typedAttributes(LabelAttributes.self)` instead of raw
//  `component.rawData["key"]` dictionary reads. The generated
//  extraction handles alias fallback (raw L0 layouts), type coercion
//  and lenient enum matching; L1-normalized layouts (`$jui` marker →
//  `DynamicComponent.isNormalized`) take the canonical-only path.
//
//  Keys that are NOT declared in attribute_definitions.json (legacy /
//  extension keys a converter still honors) go through
//  `component.undeclaredAttribute(_:)` so every remaining raw read is
//  explicit and greppable — the allowed set is pinned by
//  scripts/check_converter_raw_reads.sh.
//

import Foundation

#if DEBUG

// MARK: - Generated struct protocol

/// Common surface of every generated per-component extraction struct.
public protocol JsonUIGeneratedAttributes {
    init(json: [String: Any], canonicalOnly: Bool)
    static var declaredAttributes: Set<String> { get }
    static var aliasMap: [String: String] { get }
}

extension BlurAttributes: JsonUIGeneratedAttributes {}
extension ButtonAttributes: JsonUIGeneratedAttributes {}
extension CheckAttributes: JsonUIGeneratedAttributes {}
extension CheckBoxAttributes: JsonUIGeneratedAttributes {}
extension CircleViewAttributes: JsonUIGeneratedAttributes {}
extension CollectionAttributes: JsonUIGeneratedAttributes {}
extension EditTextAttributes: JsonUIGeneratedAttributes {}
extension EmbedAttributes: JsonUIGeneratedAttributes {}
extension GradientViewAttributes: JsonUIGeneratedAttributes {}
extension IconLabelAttributes: JsonUIGeneratedAttributes {}
extension ImageAttributes: JsonUIGeneratedAttributes {}
extension IndicatorAttributes: JsonUIGeneratedAttributes {}
extension InputAttributes: JsonUIGeneratedAttributes {}
extension LabelAttributes: JsonUIGeneratedAttributes {}
extension NetworkImageAttributes: JsonUIGeneratedAttributes {}
extension ProgressAttributes: JsonUIGeneratedAttributes {}
extension RadioAttributes: JsonUIGeneratedAttributes {}
extension SafeAreaViewAttributes: JsonUIGeneratedAttributes {}
extension ScrollViewAttributes: JsonUIGeneratedAttributes {}
extension SegmentAttributes: JsonUIGeneratedAttributes {}
extension SelectBoxAttributes: JsonUIGeneratedAttributes {}
extension SliderAttributes: JsonUIGeneratedAttributes {}
extension SwitchAttributes: JsonUIGeneratedAttributes {}
extension TabViewAttributes: JsonUIGeneratedAttributes {}
extension TextFieldAttributes: JsonUIGeneratedAttributes {}
extension TextViewAttributes: JsonUIGeneratedAttributes {}
extension ToggleAttributes: JsonUIGeneratedAttributes {}
extension ViewAttributes: JsonUIGeneratedAttributes {}
extension WebAttributes: JsonUIGeneratedAttributes {}

// MARK: - DynamicComponent bridge

extension DynamicComponent {
    /// Typed attribute extraction for this component. Alias spellings
    /// are honored for raw (L0) layouts and ignored for L1-normalized
    /// ones (`isNormalized`).
    public func typedAttributes<T: JsonUIGeneratedAttributes>(_ type: T.Type) -> T {
        return T(json: rawData, canonicalOnly: isNormalized)
    }

    /// Explicit passthrough for keys a converter honors although they
    /// are NOT declared in attribute_definitions.json (legacy /
    /// extension keys). Keeping these behind a named accessor makes the
    /// remaining raw reads greppable; the allowed key set is pinned by
    /// scripts/check_converter_raw_reads.sh.
    public func undeclaredAttribute(_ key: String) -> Any? {
        let value = rawData[key]
        if value is NSNull { return nil }
        return value
    }
}

// MARK: - AttrValue conveniences

extension AttrValue {
    /// The original `"@{expr}"` layout spelling when this is a binding.
    public var bindingString: String? {
        return bindingExpression.map { "@{\($0)}" }
    }
}

extension AttrValue where T == String {
    /// The raw layout string: `"@{expr}"` for bindings, the static
    /// string otherwise. For handing to helpers that resolve both
    /// shapes themselves (DynamicBindingHelper / DynamicHelpers).
    public var rawString: String {
        switch self {
        case .value(let v): return v
        case .binding(let e): return "@{\(e)}"
        }
    }
}

extension AttrEnum where T: RawRepresentable, T.RawValue == String {
    /// The raw layout spelling of the enum value: the declared case's
    /// rawValue for `.known`, the passthrough author input for
    /// `.unknown`.
    public var rawStringValue: String? {
        switch self {
        case .known(let v): return v.rawValue
        case .unknown(let v): return v as? String
        }
    }
}

// MARK: - Per-type metadata registry (unapplied-attribute audit)

/// Maps a layout `type` spelling (as routed by DynamicComponentBuilder)
/// to the generated metadata of the component it renders as.
public enum JsonUITypedAttributesRegistry {

    /// Structural / infrastructure keys that are legitimately present
    /// in component dictionaries but are not component attributes.
    public static let structuralKeys: Set<String> = [
        "type", "id", "child", "children", "data", "include",
        "shared_data", "variables", "binding_id", "style", "styles",
        "parent_orientation", "cellClasses", "sections",
        JsonUINormalization.markerKey
    ]

    /// Undeclared keys the converters still honor (legacy / extension
    /// keys — see `DynamicComponent.undeclaredAttribute`). Mirrors the
    /// allowlist in scripts/check_converter_raw_reads.sh.
    public static let consumedUndeclaredKeys: [String: Set<String>] = [
        "checkbox": ["fontStyle", "toggleStyle"],
        "check": ["fontStyle", "toggleStyle"],
        "gradientview": ["colors", "startPoint", "endPoint"],
        "gradient": ["colors", "startPoint", "endPoint"],
        "image": ["onSrc"],
        "indicator": ["animating"],
        "activityindicator": ["animating"],
        "scrollview": ["defaultScrollAnchor"],
        "scroll": ["defaultScrollAnchor"],
        "segment": ["selectedTabIndex", "backgroundColor", "selectedSegmentTintColor"],
        "segmentedcontrol": ["selectedTabIndex", "backgroundColor", "selectedSegmentTintColor"],
        "collection": ["hideSeparator", "cellWidth", "cellHeight", "defaultScrollAnchor"],
        "table": ["hideSeparator", "cellWidth", "cellHeight", "listStyle", "defaultScrollAnchor"],
        "list": ["hideSeparator", "cellWidth", "cellHeight", "listStyle", "defaultScrollAnchor"],
        "slider": ["range"],
        "radio": ["selectedValue"],
        "toggle": ["toggleStyle"],
        "switch": ["toggleStyle"]
    ]

    /// Generated metadata for a builder-routed type spelling, or nil
    /// for types without a definitions section (Spacer, Divider,
    /// Picker, custom components).
    public static func metadata(
        forType type: String
    ) -> (declared: Set<String>, aliasMap: [String: String])? {
        let generated: JsonUIGeneratedAttributes.Type?
        switch type.lowercased() {
        case "text", "label": generated = LabelAttributes.self
        case "button": generated = ButtonAttributes.self
        case "textfield": generated = TextFieldAttributes.self
        case "edittext": generated = EditTextAttributes.self
        case "input": generated = InputAttributes.self
        case "textview": generated = TextViewAttributes.self
        case "image": generated = ImageAttributes.self
        case "networkimage", "circleimage": generated = NetworkImageAttributes.self
        case "view": generated = ViewAttributes.self
        case "safeareaview": generated = SafeAreaViewAttributes.self
        case "scrollview", "scroll": generated = ScrollViewAttributes.self
        case "toggle": generated = ToggleAttributes.self
        case "switch": generated = SwitchAttributes.self
        case "checkbox": generated = CheckBoxAttributes.self
        case "check": generated = CheckAttributes.self
        case "radio": generated = RadioAttributes.self
        case "segment", "segmentedcontrol": generated = SegmentAttributes.self
        case "selectbox": generated = SelectBoxAttributes.self
        case "slider": generated = SliderAttributes.self
        case "progress", "progressbar": generated = ProgressAttributes.self
        case "indicator", "activityindicator": generated = IndicatorAttributes.self
        case "iconlabel": generated = IconLabelAttributes.self
        case "collection", "table", "list": generated = CollectionAttributes.self
        case "tabview": generated = TabViewAttributes.self
        case "embed": generated = EmbedAttributes.self
        case "web", "webview": generated = WebAttributes.self
        case "gradientview", "gradient": generated = GradientViewAttributes.self
        case "blur", "blurview": generated = BlurAttributes.self
        case "circleview": generated = CircleViewAttributes.self
        default: generated = nil
        }
        guard let generated = generated else { return nil }
        return (generated.declaredAttributes, generated.aliasMap)
    }
}

// MARK: - Unapplied-attribute audit

/// Debug-build detection of attributes that were parsed from the layout
/// but are not declared for the component — i.e. the author wrote a key
/// no converter will apply (typo, or a definitions gap). The renderer
/// SSoT counterpart of the attribute validator: it fires at render time
/// against the actual dispatch table.
public enum JsonUIAttributeAudit {
    /// Hook for tests / apps; defaults to Logger.debug.
    public static var warningHandler: ((String) -> Void)?

    /// One warning per (type, key) pair per process — layouts re-render
    /// constantly, warnings should not.
    private static var reported = Set<String>()
    private static let lock = NSLock()

    public static func audit(component: DynamicComponent) {
        guard let type = component.type,
              let meta = JsonUITypedAttributesRegistry.metadata(forType: type) else {
            return
        }
        let allowed = JsonUITypedAttributesRegistry.consumedUndeclaredKeys[type.lowercased()] ?? []
        for key in component.rawData.keys {
            if meta.declared.contains(key) { continue }
            if meta.aliasMap[key] != nil { continue }
            if allowed.contains(key) { continue }
            if JsonUITypedAttributesRegistry.structuralKeys.contains(key) { continue }
            if key.hasPrefix("_") { continue }

            let fingerprint = "\(type).\(key)"
            lock.lock()
            let firstTime = reported.insert(fingerprint).inserted
            lock.unlock()
            guard firstTime else { continue }

            let message = "[JsonUIAttributeAudit] '\(key)' on component type "
                + "'\(type)' is not a declared attribute — it was parsed but "
                + "will not be applied (typo, or missing from "
                + "attribute_definitions.json)"
            if let handler = warningHandler {
                handler(message)
            } else {
                Logger.debug(message)
            }
        }
    }

    /// Test support: forget previously reported pairs.
    public static func reset() {
        lock.lock()
        reported.removeAll()
        lock.unlock()
    }
}

#endif
