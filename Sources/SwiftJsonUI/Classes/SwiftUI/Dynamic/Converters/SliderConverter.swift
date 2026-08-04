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
        let attrs = component.typedAttributes(SliderAttributes.self)

        // Min/Max values. Canonical names are minimum/maximum; the
        // minimumValue/minValue and maximumValue/maxValue alias
        // spellings are resolved inside the generated extraction
        // (raw L0 layouts only).
        var minValue: Double = attrs.minimum?.value ?? 0
        var maxValue: Double = attrs.maximum?.value ?? 1

        // range property (array format: [min, max] — undeclared legacy key)
        if let range = component.rawAttribute("range") as? [Double], range.count == 2 {
            minValue = range[0]
            maxValue = range[1]
        }

        // Value binding expression ("@{prop}")
        let valueExpr = attrs.value?.bindingString
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
        //
        // `progressTintColor` is the specific spelling for the filled part of
        // the track, which is exactly what `.tint()` colours on a SwiftUI
        // Slider — so it wins over the generic `tintColor`, the same
        // precedence progress_converter.rb:54 uses. The SSoT called it
        // "deprecated on swift — SwiftUI Slider uses unified tint only";
        // ProgressConverter had already disproved that, and 49-E retracted it.
        let sliderTint = attrs.progressTintColor ?? component.tintColor
        if let tintColor = sliderTint, let color = DynamicHelpers.getColor(tintColor) {
            // .tint is the modern accent path — .accentColor alone left the
            // conformance render untinted (33 cross-effect, ios inert).
            result = AnyView(result.tint(color).accentColor(color))
        }

        // trackTintColor — the UNFILLED part of the track. `.tint()` colours
        // the filled part and SwiftUI exposes nothing for the rest, so this
        // goes through UISlider.appearance() at appear time. Same route
        // ToggleConverter already takes for thumbTintColor, which is why the
        // "SwiftUI Slider uses unified tint only" deprecation was wrong twice
        // over: the filled track has a modifier, and the unfilled one has a
        // precedent in this repo.
        if let track = attrs.trackTintColor,
           let color = DynamicHelpers.getColor(track) {
            result = AnyView(result.onAppear {
                UISlider.appearance().maximumTrackTintColor = UIColor(color)
            })
        }

        // Disabled state
        if component.enabled?.value as? Bool == false {
            result = AnyView(result.disabled(true))
        }

        // onValueChange handler (onValueChanged alias resolved inside
        // the generated extraction, L0 only)
        let handler = attrs.onValueChange?.rawRepresentation as? String
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
