//
//  SegmentConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI segmented Picker.
//
//  Modifier order (matches segment_converter.rb):
//    Picker(.segmented) -> .onChange(onValueChange) -> applyStandardModifiers()
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

        // Picker with .segmented style
        var result = AnyView(
            Picker("", selection: selectedBinding) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Text(item.dynamicLocalized()).tag(index)
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

        // onValueChange handler - called when selection changes
        if let onValueChange = component.onValueChangeSpelling(),
           let handlerName = DynamicEventHelper.extractPropertyName(from: onValueChange) {
            // Determine the binding property to observe
            // `selectedTabIndex` folds into `selectedIndex` in the generated
            // extraction (declared alias, plan 51-E), so one read covers both.
            let observeProperty: String? = attrs.selectedIndex?.bindingExpression

            if let propName = observeProperty,
               let binding = data[propName] as? SwiftUI.Binding<Int> {
                let id = component.id ?? "segment"
                result = AnyView(
                    result.onChange(of: binding.wrappedValue) { newValue in
                        DynamicEventHelper.callWithValue(
                            onValueChange,
                            id: id,
                            value: newValue,
                            data: data
                        )
                    }
                )
            }
        }

        // Standard modifiers (padding -> frame -> background -> cornerRadius -> border -> margins -> ...)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
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
#endif // DEBUG
