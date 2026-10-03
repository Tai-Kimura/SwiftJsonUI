//
//  SegmentConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI segmented Picker.
//
//  Modifier order (matches segment_converter.rb):
//    Picker(.segmented) -> applyStandardModifiers(); the user's choice writes
//    the selection, then calls onValueChange, then onClick
//

import SwiftUI
import UIKit
#if DEBUG


public struct SegmentConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let attrs = component.typedAttributes(SegmentAttributes.self)

        // Selection binding. `selectedTabIndex` is a declared alias of
        // `selectedIndex` (plan 51-E, 57a527a — the same alias TabView already
        // had), so the generated extraction folds it.
        let selectionExpr: String? = attrs.selectedIndex?.bindingString

        let selectedBinding = DynamicBindingHelper.int(
            selectionExpr,
            data: data,
            fallback: component.int(SegmentAttributes.self, \.selectedIndex, data: data) ?? 0
        )

        let items = component.stringList(SegmentAttributes.self, \.items) ?? []

        // Resolve segment color attributes
        let bgColor = DynamicHelpers.getColor(
            component.rawAttribute("backgroundColor") as? String, data: data)
        // fontColor is the unselected label and selectedFontColor the selected
        // one, falling back to fontColor (contract: semantics.segmentLabelColors).
        // normalColor / selectedColor are declared aliases — the generated
        // extraction resolves them, so only the canonical names appear here.
        let normalColor = DynamicHelpers.getColor(attrs.fontColor, data: data)
        let selectedFontColor = DynamicHelpers.getColor(
            attrs.selectedFontColor ?? attrs.fontColor, data: data)
        // tintColor is the SELECTED segment's accent on every platform.
        // `selectedSegmentTintColor` is a declared alias of it (plan 51-E,
        // 57a527a), folded by the generated extraction.
        let selectedColor = DynamicHelpers.getColor(attrs.tintColor, data: data)

        // The declared onClick, called from the user's choice of a segment —
        // after the selection is written (and, on the local path, after
        // onValueChange); no tap around it (DynamicEventHelper.operationClick).
        let click = DynamicEventHelper.operationClick(component, data: data)

        // Picker with .segmented style
        let buildPicker: (SwiftUI.Binding<Int>) -> AnyView = { selection in
            AnyView(
                Picker("", selection: DynamicEventHelper.calling(click, after: selection)) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        Text(item.dynamicLocalized()).tag(index)
                            .modifier(SegmentTabIdentifier(id: tabIdentifier(component, index: index)))
                    }
                }
                .pickerStyle(.segmented)
                .onAppear {
                    configureSegmentAppearance(
                        backgroundColor: bgColor,
                        normalColor: normalColor,
                        selectedFontColor: selectedFontColor,
                        selectedColor: selectedColor
                    )
                }
            )
        }
        // Its handlers' viewId: the id, else the drawn type and the position
        // (LayoutPath.viewId — `segment` for every id-less one before).
        let id = LayoutPath.viewId(of: component)
        // onValueChange — or, where none is declared, `valueChange`, the
        // selector spelling (Segment's own attribute in the definitions, no
        // platform named). UIKit wires it to .valueChanged, and sjui build,
        // kjui build and rjui call it where onValueChange is not declared, from
        // the user's choice; this runtime read it not at all, so a DEBUG build
        // did not call what the release build called (4f's ruling).
        let handler = component.onValueChangeSpelling()
            .flatMap { DynamicEventHelper.extractPropertyName(from: $0) != nil ? $0 : nil }
            ?? Self.valueChangeSelector(attrs.valueChange)

        // No two-way binding in the data — a literal, no value, or a plain
        // value: the segment holds its own state seeded from it
        // (DynamicLocalState). It was a `.constant`, and a tap did nothing.
        guard let bound: SwiftUI.Binding<Int> = DynamicBindingHelper.twoWay(selectionExpr, data: data) else {
            let local = AnyView(DynamicLocalState(
                initial: selectedBinding.wrappedValue,
                onChange: { newValue in
                    guard let handler else { return }
                    DynamicEventHelper.callWithValue(handler, id: id, value: newValue, data: data)
                },
                content: buildPicker
            ))
            return DynamicModifierHelper.applyStandardModifiers(local, component: component, data: data)
        }
        // onValueChange from the user's choice, after the bound selection is
        // written and before onClick (DynamicEventHelper.reporting) — not from
        // the view model's own writes, which an `.onChange(of:)` here reported
        // too, on the next update and so after the call.
        let report: ((Int) -> Void)? = handler.map { handler in
            { newValue in DynamicEventHelper.callWithValue(handler, id: id, value: newValue, data: data) }
        }
        var result = buildPicker(DynamicEventHelper.reporting(report, after: bound))

        // Standard modifiers (padding -> frame -> background -> cornerRadius -> border -> margins -> ...)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
    /// The handler a `valueChange` names: a binding as written (`@{h}` — the
    /// attribute is declared "string", so the binding and the bare name are
    /// both its spellings; the binding was refused as "onValueChange's" and,
    /// with no onValueChange, called nothing: jsonui-cli ticket
    /// sjui-segment-valuechange-binding-is-never-called), or a selector
    /// camelCased as the code generators name it (`seg_changed` →
    /// `segChanged`: sjui's to_camel_case, kjui's camelize_selector). Nil for
    /// none or a blank one.
    static func valueChangeSelector(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if DynamicEventHelper.extractPropertyName(from: value) != nil { return value }
        let parts = value.split(separator: "_", omittingEmptySubsequences: false).map(String.init)
        return parts.dropFirst().reduce(parts[0]) { name, part in
            name + part.prefix(1).uppercased() + part.dropFirst().lowercased()
        }
    }

    // MARK: - UISegmentedControl Appearance

    /// Configure UISegmentedControl.appearance() colors for segmented Picker.
    /// This uses UIKit appearance proxy since SwiftUI Picker(.segmented) wraps UISegmentedControl.
    /// - backgroundColor: container background color
    /// - normalColor: text color for unselected segments (.normal state)
    /// - selectedFontColor: text color for the selected segment (.selected state)
    /// - selectedColor: tint color for the selected segment's background
    private static func configureSegmentAppearance(
        backgroundColor: Color?,
        normalColor: Color?,
        selectedFontColor: Color?,
        selectedColor: Color?
    ) {
        let appearance = UISegmentedControl.appearance()

        if let bgColor = backgroundColor {
            appearance.backgroundColor = UIColor(bgColor)
        }

        if let selectedColor = selectedColor {
            appearance.selectedSegmentTintColor = UIColor(selectedColor)
        }

        if let normalColor = normalColor {
            appearance.setTitleTextAttributes(
                [.foregroundColor: UIColor(normalColor)],
                for: .normal
            )
        }

        if let selectedFontColor = selectedFontColor {
            appearance.setTitleTextAttributes(
                [.foregroundColor: UIColor(selectedFontColor)],
                for: .selected
            )
        }
    }
}

extension SegmentConverter {
    /// `<id>_tab_<n>` for a segment: the id every driver's selectTab looks
    /// for, and the one sjui codegen and rjui give each segment. Nil without
    /// an id, as the Segment then has no identifier of its own. The segments
    /// were id-less until 10.29.3, so a Segment could not be selected from a
    /// UI test on iOS (jsonui-cli ticket
    /// jui-segment-tabs-carry-no-tab-ids-so-selecttab-cannot-reach-them).
    /// Measured 2026-10-03 (iOS 26.5 simulator, Xcode 26.6): an identifier
    /// on a segment's Text reaches XCUITest as that segment's button, and a
    /// tap on it selects the segment.
    static func tabIdentifier(_ component: DynamicComponent, index: Int) -> String? {
        component.id.map { "\($0)_tab_\(index)" }
    }
}

/// The segment's identifier when there is one; nothing otherwise.
struct SegmentTabIdentifier: ViewModifier {
    let id: String?
    func body(content: Content) -> some View {
        if let id { content.accessibilityIdentifier(id) } else { content }
    }
}

#endif // DEBUG
