//
//  SliderConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Slider.
//
//  Modifier order (matches slider_converter.rb):
//    Slider(value:in:) -> .accentColor(tintColor) -> .disabled()
//    -> .onChange(onValueChange) -> applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct SliderConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        // Min/Max values: check range array first, then individual properties
        var minValue: Double = component.rawData["minimumValue"] as? Double ?? component.minValue ?? 0
        var maxValue: Double = component.rawData["maximumValue"] as? Double ?? component.maxValue ?? 1

        // range property (array format: [min, max])
        if let range = component.rawData["range"] as? [Double], range.count == 2 {
            minValue = range[0]
            maxValue = range[1]
        }

        // Value binding: check "value" key in rawData for binding expression
        let valueExpr = component.rawData["value"] as? String
        let valueBinding = DynamicBindingHelper.double(
            valueExpr,
            data: data,
            fallback: component.value ?? minValue
        )

        // Slider
        var result = AnyView(
            Slider(value: valueBinding, in: minValue...maxValue)
        )

        // Tint color (.accentColor to match Ruby converter)
        if let tintColor = component.tintColor, let color = DynamicHelpers.getColor(tintColor) {
            result = AnyView(result.accentColor(color))
        }

        // Disabled state
        if component.enabled?.value as? Bool == false {
            result = AnyView(result.disabled(true))
        }

        // onValueChange / onValueChanged handler
        let handler = component.onValueChange ?? component.rawData["onValueChanged"] as? String
        if let handler = handler,
           let _ = DynamicEventHelper.extractPropertyName(from: handler) {
            // Determine the binding property to observe
            let observeProperty: String? = {
                if let v = valueExpr {
                    return DynamicEventHelper.extractPropertyName(from: v)
                }
                return nil
            }()

            if let propName = observeProperty,
               let binding = data[propName] as? SwiftUI.Binding<Double> {
                let id = component.id ?? "slider"
                result = AnyView(
                    result.onChange(of: binding.wrappedValue) { newValue in
                        DynamicEventHelper.callWithValue(
                            handler,
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
}
#endif // DEBUG
