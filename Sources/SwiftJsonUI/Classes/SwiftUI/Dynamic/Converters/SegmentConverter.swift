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

        // Selection binding: selectedIndex first, then the undeclared
        // legacy selectedTabIndex spelling
        let selectionExpr: String? = attrs.selectedIndex?.bindingString
            ?? (component.rawAttribute("selectedTabIndex") as? String).flatMap {
                DynamicBindingResolver.isBindingExpression($0) ? $0 : nil
            }

        let selectedBinding = DynamicBindingHelper.int(
            selectionExpr,
            data: data,
            fallback: component.selectedIndex ?? 0
        )

        let items = component.items ?? []

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
        let selectedColor = DynamicHelpers.getColor(
            component.rawAttribute("selectedSegmentTintColor") as? String
                ?? component.tintColor,
            data: data
        )

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
        if let onValueChange = component.onValueChange,
           let handlerName = DynamicEventHelper.extractPropertyName(from: onValueChange) {
            // Determine the binding property to observe
            let observeProperty: String? = attrs.selectedIndex?.bindingExpression
                ?? DynamicEventHelper.extractPropertyName(
                    from: component.rawAttribute("selectedTabIndex") as? String)

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
