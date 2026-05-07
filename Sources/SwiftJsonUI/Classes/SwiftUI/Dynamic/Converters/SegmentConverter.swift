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
        // Selection binding: check selectedIndex first, then selectedTabIndex
        let selectionExpr: String? = {
            if let si = component.rawData["selectedIndex"] as? String, si.hasPrefix("@{") {
                return si
            }
            if let sti = component.rawData["selectedTabIndex"] as? String, sti.hasPrefix("@{") {
                return sti
            }
            return nil
        }()

        let selectedBinding = DynamicBindingHelper.int(
            selectionExpr,
            data: data,
            fallback: component.selectedIndex ?? 0
        )

        let items = component.items ?? []

        // Resolve segment color attributes
        let bgColor = DynamicHelpers.getColor(component.rawData["backgroundColor"] as? String, data: data)
        let normalColor = DynamicHelpers.getColor(component.rawData["normalColor"] as? String, data: data)
        let selectedColor = DynamicHelpers.getColor(
            component.rawData["selectedColor"] as? String
                ?? component.rawData["selectedSegmentTintColor"] as? String
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
                    selectedColor: selectedColor
                )
            }
        )

        // onValueChange handler - called when selection changes
        if let onValueChange = component.onValueChange,
           let handlerName = DynamicEventHelper.extractPropertyName(from: onValueChange) {
            // Determine the binding property to observe
            let observeProperty: String? = {
                if let si = component.rawData["selectedIndex"] as? String {
                    return DynamicEventHelper.extractPropertyName(from: si)
                }
                if let sti = component.rawData["selectedTabIndex"] as? String {
                    return DynamicEventHelper.extractPropertyName(from: sti)
                }
                return nil
            }()

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
    /// - selectedColor: tint color for selected segment background + selected text color
    private static func configureSegmentAppearance(
        backgroundColor: Color?,
        normalColor: Color?,
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
    }
}
#endif // DEBUG
