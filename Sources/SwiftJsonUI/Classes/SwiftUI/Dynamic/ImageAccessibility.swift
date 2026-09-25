//
//  ImageAccessibility.swift
//  SwiftJsonUI
//
//  What VoiceOver reads for an image — the rule jsonui-cli's codegen
//  applies (shared/core/image_accessibility.rb), and the table both run
//  (image_accessibility_vectors.json, copied byte for byte into the tests).
//
//  `alt` (aliases `accessibilityLabel`, `contentDescription`) is the spoken
//  text: a strings.json key or literal, or a binding. An image is
//  - label: alt is a non-empty string — it is read;
//  - decorative: alt is "", or there is no alt and the image operates
//    nothing — `.accessibilityHidden(true)`; without it SwiftUI reads the
//    asset name;
//  - control: there is no alt and the image operates a control (a tap
//    handler of its own, or it sits in the nearest tappable whose content
//    names nothing) — left as it was. Hiding it would leave a
//    `.onTapGesture` tappable with no accessibility element at all.
//
//  The nearest tappable is carried as environment: DynamicComponentBuilder
//  marks every component with a tap handler (ImageTappableMark), the way
//  ScrollingAncestorContext carries a scrolling ancestor.
//

import SwiftUI

#if DEBUG

public enum ImageAccessibility {
    public enum Role: String {
        case label, decorative, control
    }

    /// What VoiceOver gets for an image.
    public enum Spoken: Equatable {
        case label(String)
        case hidden
        case unchanged
    }

    /// Image, its type aliases (component_metadata.json) and NetworkImage.
    static let imageTypes: Set<String> = ["image", "circleimage", "circleimageview", "imageview", "img", "networkimage"]

    /// The canonical spelling first, then the declared aliases.
    public static let altKeys = ["alt", "accessibilityLabel", "contentDescription"]

    /// What a screen-reader user activates: a tap and a long press.
    public static let tapKeys = ["onClick", "onclick", "onLongPress"]

    /// Text that names a control it sits in (on an image, hint / placeholder name an image).
    public static let textKeys = ["text", "hint", "placeholder", "label", "prompt"]

    static func isImage(_ node: [String: Any]) -> Bool {
        (node["type"] as? String).map { imageTypes.contains($0.lowercased()) } ?? false
    }

    static func isTappable(_ node: [String: Any]) -> Bool {
        tapKeys.contains { node[$0] != nil }
    }

    /// The image's alt as written, or nil when it declares none (JSON null counts as none).
    static func alt(_ node: [String: Any]) -> String? {
        for key in altKeys {
            guard let value = node[key] else { continue }
            if value is NSNull { return nil }
            if let string = value as? String { return string }
            return "\(value)"
        }
        return nil
    }

    static func children(_ node: [String: Any]) -> [[String: Any]] {
        ["child", "children"].flatMap { key -> [[String: Any]] in
            if let array = node[key] as? [Any] { return array.compactMap { $0 as? [String: Any] } }
            if let one = node[key] as? [String: Any] { return [one] }
            return []
        }
    }

    private static func nonEmptyString(_ value: Any?) -> Bool {
        (value as? String).map { !$0.isEmpty } ?? false
    }

    /// True when something inside `node` (itself included) names a control:
    /// text on a non-image, or an image whose alt is a non-empty string. An
    /// include not expanded yet names nothing, which errs toward control —
    /// the image stays readable rather than hidden.
    static func namesSomething(_ node: [String: Any]) -> Bool {
        if isImage(node) {
            guard let key = altKeys.first(where: { node[$0] != nil }) else { return false }
            return nonEmptyString(node[key])
        }
        if textKeys.contains(where: { nonEmptyString(node[$0]) }) { return true }
        if let items = node["items"] as? [Any], items.contains(where: { nonEmptyString($0) }) { return true }
        return children(node).contains { namesSomething($0) }
    }

    /// The role of an image, given the nearest tappable around it (nil when none).
    public static func role(_ node: [String: Any], nearestTappable: [String: Any]?) -> Role {
        if let value = alt(node) { return value.isEmpty ? .decorative : .label }
        if isTappable(node) { return .control }
        if let tappable = nearestTappable, !namesSomething(tappable) { return .control }
        return .decorative
    }

    /// The resolved alt for a label ("" — a bound alt that resolved to nothing — is decorative).
    public static func spoken(role: Role, resolvedAlt: () -> String) -> Spoken {
        switch role {
        case .label:
            let text = resolvedAlt()
            return text.isEmpty ? .hidden : .label(text)
        case .decorative:
            return .hidden
        case .control:
            return .unchanged
        }
    }

    /// The alt resolved as a Label's text is: bindings interpolated, then localized.
    static func resolvedAlt(_ node: [String: Any], data: [String: Any]) -> String {
        DynamicHelpers.processText(alt(node), data: data).dynamicLocalized()
    }
}

private struct ImageTappableKey: EnvironmentKey {
    static var defaultValue: [String: Any]? { nil }
}

public extension EnvironmentValues {
    /// The raw JSON of the nearest component with a tap handler around the
    /// one being rendered by the dynamic path, or nil.
    var jsonuiImageTappable: [String: Any]? {
        get { self[ImageTappableKey.self] }
        set { self[ImageTappableKey.self] = newValue }
    }
}

/// Makes a component with a tap handler (`node` non-nil) the nearest
/// tappable for everything rendered inside it; otherwise leaves whatever the
/// environment already says.
struct ImageTappableMark: ViewModifier {
    let node: [String: Any]?
    @Environment(\.jsonuiImageTappable) private var inherited

    func body(content: Content) -> some View {
        content.environment(\.jsonuiImageTappable, node ?? inherited)
    }
}

/// Applies an image's role, reading the nearest tappable from the environment.
struct ImageAccessibilityModifier: ViewModifier {
    let component: DynamicComponent
    let data: [String: Any]
    @Environment(\.jsonuiImageTappable) private var nearestTappable

    @ViewBuilder
    func body(content: Content) -> some View {
        let role = ImageAccessibility.role(component.rawData, nearestTappable: nearestTappable)
        switch ImageAccessibility.spoken(role: role, resolvedAlt: {
            ImageAccessibility.resolvedAlt(component.rawData, data: data)
        }) {
        case .label(let text):
            content.accessibilityLabel(Text(text))
        case .hidden:
            content.accessibilityHidden(true)
        case .unchanged:
            content
        }
    }
}

#endif
