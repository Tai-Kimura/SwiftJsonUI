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
//  `userInteractionEnabled` stops the node and everything in it, and the rule
//  reads it as it reads `canTap: false`: `false` makes the node and every
//  node inside it no tap — no gesture, no trait (a tap `.allowsHitTesting`
//  had stopped was still announced as a button). DynamicComponentBuilder
//  marks each component inside one whose flag is false, or whose binding
//  resolves false (`interactionStoppedAround`, the codegen's `_tapStopped`);
//  a binding on the component itself is resolved where the tap is attached
//  (DynamicEventHelper.tapGateOpen). A control's own type still counts inside.
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

    /// Asked of the type the node is drawn as (TypeSynonyms.drawnType): an
    /// HStack is a View, a Textarea a TextView. Read as written, a synonym
    /// the lists do not hold counted as a custom component (operable), so
    /// the tappable around it was not flattened where the same layout
    /// spelled canonically was.
    static func isInteractiveType(_ type: String?) -> Bool {
        guard let type = type else { return true }
        let drawn = TypeSynonyms.drawnType(type).lowercased()
        return interactive.contains(drawn) || !known.contains(drawn)
    }

    /// The interactive types that hold the operated things rather than being
    /// one (jsonui-cli shared/core/tap_accessibility.rb STOP_CONTAINER_TYPES).
    private static let stopContainers: Set<String> = [
        "tabview", "scrollview", "collection", "table", "tableview", "recyclerview", "web", "embed"
    ]

    /// A control a stop holds — operated where it is, not a container
    /// (jsonui-cli shared/core/tap_accessibility.rb `control?`): the stop takes
    /// its operation without a tap on it, a screen reader's activation too
    /// (DynamicModifierHelper.applyHitTesting, JsonUIStoppedControl). Asked of
    /// the type it is drawn as, as isInteractiveType is.
    static func isControl(_ type: String?) -> Bool {
        guard let type = type else { return false }
        let drawn = TypeSynonyms.drawnType(type).lowercased()
        return interactive.contains(drawn) && !stopContainers.contains(drawn)
    }

    /// A handler names a method that is not blank: a binding's inside
    /// (`@{onOpen}`), a bare selector, or each string of an `onclick` array.
    /// `""`, `"   "`, `"@{}"`, `[]` and `[""]` name none, so they are no tap
    /// (jsonui-cli shared/core/tap_accessibility.rb `handler?`; blank is
    /// Unicode white space, a full-width space too). They used to attach a
    /// tap that called nothing and took the tap from the view around it.
    static func namesAMethod(_ value: String) -> Bool {
        var inner = Substring(value)
        if inner.hasPrefix("@{") && inner.hasSuffix("}") && inner.count >= 3 {
            inner = inner.dropFirst(2).dropLast()
        }
        return !inner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The elements of a handler value that name a method, in the order written.
    static func handlerValues(_ value: Any?) -> [String] {
        if let single = value as? String { return namesAMethod(single) ? [single] : [] }
        if let many = value as? [Any] { return many.compactMap { $0 as? String }.filter(namesAMethod) }
        return []
    }

    /// A tap the Dynamic runtime attaches: a handler, not statically disabled,
    /// not gated shut (`canTap: false`, the SwiftUI tap gate), and not
    /// stopped — by its own `userInteractionEnabled: false`, or by a component
    /// around it (`interactionStoppedAround`).
    static func isTappable(_ component: DynamicComponent) -> Bool {
        if component.commonBool(\.enabled) == false { return false }
        if case .value(false)? = component.typedAttributes(CommonAttributes.self).canTap { return false }
        if stops(component) || component.interactionStoppedAround { return false }
        return !component.effectiveOnClickHandlers.isEmpty
    }

    /// `userInteractionEnabled: false`: the component and everything in it
    /// take no interaction.
    static func stops(_ component: DynamicComponent) -> Bool {
        if case .value(false)? = component.typedAttributes(CommonAttributes.self).userInteractionEnabled { return true }
        return false
    }

    /// The same, on a layout node as written.
    static func stops(node: [String: Any]) -> Bool {
        node["userInteractionEnabled"] as? Bool == false
    }

    /// A Label that carries links of its own: `linkable` (true or bound), or
    /// a partialAttributes range with its own tap.
    static func isLinkedText(_ component: DynamicComponent) -> Bool {
        guard let type = component.type, TypeSynonyms.drawnType(type).lowercased() == "label" else { return false }
        switch component.typedAttributes(LabelAttributes.self).linkable {
        case .value(true)?, .binding(_)?:
            return true
        default:
            break
        }
        guard let ranges = component.partialAttributes?.value as? [[String: Any]] else { return false }
        return ranges.contains { range in
            ["onClick", "onclick"].contains { key in !handlerValues(range[key]).isEmpty }
        }
    }

    /// Operable inside a tappable even when its type is not: its own tap, a
    /// long press (a screen-reader action), or links of its own. A tappable
    /// whose only handler is a long press is not a tap: nothing to call a
    /// button. `canTap` without onClick has no handler either.
    /// `stopped`: a component around it has `userInteractionEnabled: false`,
    /// so its own tap and long press are none (its type still says whether it
    /// is a control) — and so are its links: a Label's links stop with it
    /// (PartialAttributedText reads the stop), so they do not count
    /// (jsonui-cli 1.9.0; shared/core/tap_accessibility.rb `operable?`).
    static func isOperable(_ component: DynamicComponent, stopped: Bool = false) -> Bool {
        let linksStopped = stopped || stops(component) || component.interactionStoppedAround
        if isInteractiveType(component.type) || (!stopped && isTappable(component))
            || (!linksStopped && isLinkedText(component)) { return true }
        // A long press is a handler too (`handlerValues`): an empty or blank
        // one names no method. `!= nil` counted `""` (tap_accessibility_vectors
        // "an empty long press inside does not count"). The flag stops it as
        // it stops a tap, on the component or around it.
        if stopped || stops(component) || component.interactionStoppedAround { return false }
        return component.commonBool(\.enabled) != false
            && !handlerValues(component.commonAny(\.onLongPress)).isEmpty
    }

    /// The same tap, read off a layout node as written — what the image rule
    /// (ImageAccessibility) asks: a handler on onClick / onclick, `enabled`
    /// not false, `canTap` not false, `userInteractionEnabled` not false on it
    /// or on a node around it (`stopped`). A bound gate still taps.
    static func isTappable(node: [String: Any], stopped: Bool = false) -> Bool {
        if stopped || stops(node: node) { return false }
        if node["enabled"] as? Bool == false || node["canTap"] as? Bool == false { return false }
        return ["onClick", "onclick"].contains { !handlerValues(node[$0]).isEmpty }
    }

    /// A long press on a layout node as written: a handler, `enabled` not
    /// false (`canTap` gates the tap, not the long press), and
    /// `userInteractionEnabled` not false on it or on a node around it
    /// (`stopped`), as for a tap. A bound flag still presses.
    static func hasLongPress(node: [String: Any], stopped: Bool = false) -> Bool {
        if stopped || stops(node: node) { return false }
        return node["enabled"] as? Bool != false && !handlerValues(node["onLongPress"]).isEmpty
    }

    /// The keys the tools write on a node that the layout did not: the
    /// position stamp and the rule's own marks (jsonui-cli
    /// shared/core/tap_accessibility.rb WRITTEN_STAMPS).
    private static let writtenStamps: Set<String> = ["_layoutPath", "_tapShape", "_tapStopped", "_tapGates"]

    /// A data-only element — `data` the only key the layout wrote — declares
    /// the data and draws nothing (jsonui-cli `data_only?`).
    static func isDataOnly(_ component: DynamicComponent) -> Bool {
        Set(component.rawData.keys).subtracting(writtenStamps) == ["data"]
    }

    /// The children a component draws: the shapes do not count a data-only
    /// one (jsonui-cli `drawn_children`). It read as a child of unknown type,
    /// a control, and a Label with onClick whose only child declared its data
    /// was no button (4f's ruling, jsonui-cli 1.9.0).
    static func drawnChildren(_ component: DynamicComponent) -> [DynamicComponent] {
        (component.childComponents ?? []).filter { !isDataOnly($0) }
    }

    static func holdsAControl(_ component: DynamicComponent, stopped: Bool = false) -> Bool {
        drawnChildren(component).contains {
            let inner = stopped || stops($0)
            return isOperable($0, stopped: inner) || holdsAControl($0, stopped: inner)
        }
    }

    static func shape(of component: DynamicComponent) -> Shape? {
        guard isTappable(component) else { return nil }
        if isInteractiveType(component.type) { return .unchanged }
        if drawnChildren(component).isEmpty { return .button }
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
            let combined = base.accessibilityElement(children: .combine).accessibilityAddTraits(.isButton)
            // An id-less combined tap takes its children's identifiers as its
            // own (measured, XCUITest 2026-09-25): one child's id was found
            // twice — on the button and on the child — and two children's
            // were joined ("a-b") on the button. An explicit empty identifier
            // keeps the button's own; a component with an id gets it on the
            // button from applyAccessibilityId instead.
            if component.id == nil {
                return AnyView(combined.accessibilityIdentifier(""))
            }
            return AnyView(combined)
        default:
            return view
        }
    }
}

extension DynamicComponent {
    /// The component as it is, marked as inside one that stops interaction.
    func markedStopped() -> DynamicComponent {
        var marked = self
        marked.interactionStoppedAround = true
        return marked
    }
}
#endif // DEBUG
