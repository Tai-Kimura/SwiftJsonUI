//
//  ControlAccessibility.swift
//  SwiftJsonUI
//
//  What VoiceOver is told about a control beyond what it shows — the rule
//  jsonui-cli's codegen applies (shared/core/control_accessibility.rb),
//  last on the chain as sjui writes it (modifier_order.json after_bag
//  `control_accessibility`):
//  - accessibilityLabel (alias contentDescription): the name a control is
//    read by in place of its text, a strings.json key or text localized like
//    `text`, or a binding — `.accessibilityLabel(Text(…))`. Declared on the
//    types a user operates; on a View only when the View is one button to
//    VoiceOver (TapAccessibility's `button` / `combine`): a View that taps
//    nothing is no element, and a name on it lands on its children. A Radio
//    forms its own element and names it there (RadioConverter).
//  - accessibilityLiveRegion (polite / assertive / off): on a Label whose
//    text is bound, an announcement of the new text whenever it changes
//    (assertive at high priority). iOS has no live region, so a View's does
//    nothing (jsonui-cli declares it for web and Android).
//

import SwiftUI

#if DEBUG

public enum ControlAccessibility {
    /// The section a component is drawn as, lowercased (a synonym as its
    /// type; an alias section — Check, Toggle — is its own generated table).
    static func section(_ component: DynamicComponent) -> String {
        guard let type = component.type else { return "view" }
        return (TypeSynonyms.entries[type]?.canonical ?? type).lowercased()
    }

    /// The accessibilityLabel as written (a key, text or `@{…}`), or nil.
    static func writtenLabel(_ component: DynamicComponent) -> String? {
        let value: AttrValue<String>?
        switch section(component) {
        case "button": value = component.typedAttributes(ButtonAttributes.self).accessibilityLabel
        case "checkbox": value = component.typedAttributes(CheckBoxAttributes.self).accessibilityLabel
        case "check": value = component.typedAttributes(CheckAttributes.self).accessibilityLabel
        case "switch": value = component.typedAttributes(SwitchAttributes.self).accessibilityLabel
        case "toggle": value = component.typedAttributes(ToggleAttributes.self).accessibilityLabel
        case "radio": value = component.typedAttributes(RadioAttributes.self).accessibilityLabel
        case "segment": value = component.typedAttributes(SegmentAttributes.self).accessibilityLabel
        case "slider": value = component.typedAttributes(SliderAttributes.self).accessibilityLabel
        case "selectbox": value = component.typedAttributes(SelectBoxAttributes.self).accessibilityLabel
        case "textfield": value = component.typedAttributes(TextFieldAttributes.self).accessibilityLabel
        case "edittext": value = component.typedAttributes(EditTextAttributes.self).accessibilityLabel
        case "input": value = component.typedAttributes(InputAttributes.self).accessibilityLabel
        case "view":
            guard isOneButton(component) else { return nil }
            value = component.typedAttributes(ViewAttributes.self).accessibilityLabel
        default: value = nil
        }
        guard let raw = value?.rawString, !raw.isEmpty else { return nil }
        return raw
    }

    static func isOneButton(_ component: DynamicComponent) -> Bool {
        switch TapAccessibility.shape(of: component) {
        case .button?, .combine?: return true
        default: return false
        }
    }

    /// The name VoiceOver reads, resolved and localized, or nil.
    public static func label(_ component: DynamicComponent, data: [String: Any]) -> String? {
        guard let raw = writtenLabel(component) else { return nil }
        return DynamicHelpers.processText(raw, data: data).dynamicLocalized()
    }

    /// A Label's live region: polite or assertive, nil for off / none.
    public static func live(_ component: DynamicComponent) -> LabelAttributes.AccessibilityLiveRegion? {
        guard section(component) == "label",
              case .known(let value)? = component.typedAttributes(LabelAttributes.self).accessibilityLiveRegion,
              value != .off else { return nil }
        return value
    }

    /// The chain's last stage (DynamicModifierHelper.standardOrder).
    static func apply(_ view: AnyView, component: DynamicComponent, data: [String: Any]) -> AnyView {
        var result = view
        if section(component) != "radio", let name = label(component, data: data) {
            result = AnyView(result.accessibilityLabel(Text(name)))
        }
        if let live = live(component),
           let text = component.typedAttributes(LabelAttributes.self).text,
           text.bindingExpression != nil {
            let current = DynamicHelpers.processText(text.rawString, data: data)
            result = AnyView(result.modifier(LiveAnnouncement(text: current, assertive: live == .assertive)))
        }
        return result
    }
}

/// Posts the text as an announcement whenever it changes — at high
/// priority (interrupting) when assertive.
struct LiveAnnouncement: ViewModifier {
    let text: String
    let assertive: Bool

    func body(content: Content) -> some View {
        content.onChange(of: text) { _, newValue in
            var announcement = AttributedString(newValue)
            announcement.accessibilitySpeechAnnouncementPriority = assertive ? .high : .default
            AccessibilityNotification.Announcement(announcement).post()
        }
    }
}

#endif
