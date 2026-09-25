//
//  TapAccessibility.swift
//  SwiftJsonUI
//
//  Whether VoiceOver is told a tappable is a button — the rule jsonui-cli's
//  sjui / kjui codegen and KotlinJsonUI's Dynamic runtime also run
//  (shared/core/tap_accessibility.rb, and its table
//  shared/core/tap_accessibility_vectors.json, copied byte-identical into
//  Tests/SwiftJsonUITests/Fixtures and compared by CI's vendored-attr-guard).
//
//  A tap is `.onTapGesture`, which says nothing to VoiceOver. Each tappable
//  gets one shape:
//    button  — it holds no children: `.accessibilityAddTraits(.isButton)`.
//    combine — it holds children and nothing inside is operable on its own:
//              ONE button named by its content,
//              `.accessibilityElement(children: .combine)` + `.isButton`,
//              and applyAccessibilityId puts the id on that element instead
//              of making a container of it.
//    none    — its own type is a control already, or something inside is
//              operable on its own: left as it was. Measured (XCUITest
//              elementType, 2026-09-25): `.isButton` under `.contain` makes
//              every child a button; `.combine` turns the container into the
//              control inside it. That is the silence the rule chooses.
//
//  Which types are operable is declared per type (`interactive`) in
//  jsonui-cli's shared/core/component_metadata.json. The two lists below are
//  that declaration with its aliases, held equal to the vendored table by
//  TapAccessibilityVectorsTests. A type the declaration does not know (a
//  custom component) counts as operable.
//

import SwiftUI

#if DEBUG
enum TapAccessibility {
    /// `unchanged` is spelled "none" in the table; as a case name `.none`
    /// would read as Optional.none wherever a `Shape?` is expected.
    enum Shape: String { case button, combine, unchanged = "none" }

    static let interactiveTypes: [String] = [
        "Button", "Check", "CheckBox", "Checkbox", "Collection", "EditText",
        "Embed", "Input", "Radio", "RecyclerView", "ScrollView", "Segment",
        "SelectBox", "Slider", "Switch", "TabView", "Table", "TableView",
        "TextField", "TextView", "Toggle", "Web"
    ]

    static let knownTypes: [String] = interactiveTypes + [
        "Blur", "CircleImage", "CircleImageView", "CircleView", "GradientView", "IconLabel",
        "Image", "ImageView", "Img", "Indicator", "Label", "NetworkImage",
        "Progress", "SafeAreaView", "Text", "View"
    ]

    private static let interactive = Set(interactiveTypes.map { $0.lowercased() })
    private static let known = Set(knownTypes.map { $0.lowercased() })

    static func isInteractiveType(_ type: String?) -> Bool {
        guard let type = type?.lowercased() else { return true }
        return interactive.contains(type) || !known.contains(type)
    }

    /// A tap the Dynamic runtime attaches: a handler, not statically disabled.
    static func isTappable(_ component: DynamicComponent) -> Bool {
        if component.commonBool(\.enabled) == false { return false }
        return component.effectiveOnClickHandlers.contains { !$0.isEmpty }
    }

    /// A Label that carries links of its own: `linkable` (true or bound), or
    /// a partialAttributes range with its own tap.
    static func isLinkedText(_ component: DynamicComponent) -> Bool {
        guard let type = component.type?.lowercased(), type == "label" || type == "text" else { return false }
        switch component.typedAttributes(LabelAttributes.self).linkable {
        case .value(true)?, .binding(_)?:
            return true
        default:
            break
        }
        guard let ranges = component.partialAttributes?.value as? [[String: Any]] else { return false }
        return ranges.contains { range in
            ["onClick", "onclick"].contains { key in
                if let text = range[key] as? String { return !text.isEmpty }
                return range[key] != nil && !(range[key] is NSNull)
            }
        }
    }

    /// Operable inside a tappable even when its type is not: its own tap, a
    /// long press (a screen-reader action), or links of its own. A tappable
    /// whose only handler is a long press is not a tap: nothing to call a
    /// button. `canTap` without onClick has no handler either.
    static func isOperable(_ component: DynamicComponent) -> Bool {
        if isInteractiveType(component.type) || isTappable(component) || isLinkedText(component) { return true }
        return component.commonBool(\.enabled) != false && component.commonAny(\.onLongPress) != nil
    }

    static func holdsAControl(_ component: DynamicComponent) -> Bool {
        (component.childComponents ?? []).contains { isOperable($0) || holdsAControl($0) }
    }

    static func shape(of component: DynamicComponent) -> Shape? {
        guard isTappable(component) else { return nil }
        if isInteractiveType(component.type) { return .unchanged }
        if (component.childComponents ?? []).isEmpty { return .button }
        if holdsAControl(component) { return .unchanged }
        return .combine
    }

    /// The traits for a view whose tap has just been attached.
    static func apply(_ view: AnyView, component: DynamicComponent) -> AnyView {
        switch shape(of: component) {
        case .button?:
            return AnyView(view.accessibilityAddTraits(.isButton))
        case .combine?:
            // The anchor makeAccessibilityContainer uses, for the same
            // single-child merge: with one accessible child, `.combine` took
            // the child's own identifier away (measured, XCUITest). Before
            // `.combine`, so the anchor is one of the children it combines.
            var base = view
            if DynamicModifierHelper.accessibilityMergeHazard(component) {
                base = AnyView(view.overlay(alignment: .topLeading) {
                    SwiftUI.Color.clear
                        .frame(width: 0.5, height: 0.5)
                        .accessibilityElement(children: .ignore)
                })
            }
            return AnyView(base.accessibilityElement(children: .combine).accessibilityAddTraits(.isButton))
        default:
            return view
        }
    }
}
#endif // DEBUG
