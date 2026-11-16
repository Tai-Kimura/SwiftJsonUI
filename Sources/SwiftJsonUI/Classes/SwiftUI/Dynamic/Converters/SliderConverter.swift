//
//  SliderConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Slider.
//
//  Modifier order (matches slider_converter.rb):
//    Slider(value:in:) -> .accentColor(tintColor) -> .disabled()
//    -> applyStandardModifiers(); each value of the user's drag writes the
//    value, then calls onValueChange; onClick at the drag's end
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
        //
        // Read through `number(_:_:data:)`, NOT `?.value`: the latter answers
        // only the `.value` case, so a bound bound resolved to the `?? 0` /
        // `?? 1` default and the thumb sat at the wrong fraction of the
        // track. `value` below has always taken this route.
        var minValue: Double = component.number(
            SliderAttributes.self, \.minimum, data: data
        ).map { Double($0) } ?? 0
        var maxValue: Double = component.number(
            SliderAttributes.self, \.maximum, data: data
        ).map { Double($0) } ?? 1

        // range property (array format: [min, max]). Declared and generated
        // since plan 51-E, so the typed field carries it; the elements arrive
        // as `Any` because JSON has one number type.
        if let range = attrs.range, range.count == 2,
           let lo = DynamicBindingResolver.coerceDouble(range[0]),
           let hi = DynamicBindingResolver.coerceDouble(range[1]) {
            minValue = lo
            maxValue = hi
        }

        // Value binding expression ("@{prop}")
        let valueExpr = attrs.value?.bindingString
        let valueBinding = DynamicBindingHelper.double(
            valueExpr,
            data: data,
            fallback: component.number(SliderAttributes.self, \.value, data: data).map { Double($0) } ?? minValue
        )

        // The declared onClick, called when the user's change of the value
        // finishes — the end of a drag, as kjui's onValueChangeFinished; no
        // tap around it (DynamicEventHelper.operationClick).
        let click = DynamicEventHelper.operationClick(component, data: data)

        // Slider — built over whichever value it moves (the view model's, or
        // its own below).
        let buildSlider: (SwiftUI.Binding<Double>) -> AnyView = { value in
            var result = AnyView(
                Slider(value: value, in: minValue...maxValue, onEditingChanged: { editing in
                    if !editing { click?() }
                })
            )

            // Tint color (.accentColor to match Ruby converter)
            //
            // `progressTintColor` is the specific spelling for the filled part of
            // the track, which is exactly what `.tint()` colours on a SwiftUI
            // Slider — so it wins over the generic `tintColor`, the same
            // precedence progress_converter.rb:54 uses. The SSoT called it
            // "deprecated on swift — SwiftUI Slider uses unified tint only";
            // ProgressConverter had already disproved that, and 49-E retracted it.
            let sliderTint = attrs.progressTintColor ?? attrs.tintColor
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
            if component.commonBool(\.enabled) == false {
                result = AnyView(result.disabled(true))
            }
            return result
        }

        // onValueChange handler (onValueChanged alias resolved inside
        // the generated extraction, L0 only)
        let handler = attrs.onValueChange?.rawRepresentation as? String
        // Its handlers' viewId: the id, else the drawn type and the position
        // (LayoutPath.viewId — `slider` for every id-less one before).
        let id = LayoutPath.viewId(of: component)

        // No two-way binding in the data — a literal, no value (the minimum),
        // or a plain value: the slider holds its own state seeded from it
        // (DynamicLocalState). It was a `.constant`, and a drag did nothing.
        guard let bound: SwiftUI.Binding<Double> = DynamicBindingHelper.twoWay(valueExpr, data: data) else {
            let local = AnyView(DynamicLocalState(
                initial: valueBinding.wrappedValue,
                onChange: { newValue in
                    guard let handler, DynamicEventHelper.extractPropertyName(from: handler) != nil else { return }
                    DynamicEventHelper.callWithValue(handler, id: id, value: newValue, data: data)
                },
                content: buildSlider
            ))
            return DynamicModifierHelper.applyStandardModifiers(local, component: component, data: data)
        }
        // onValueChange from every value of the user's drag, after the bound
        // value is written — onClick follows at the drag's end
        // (DynamicEventHelper.reporting) — and not from the view model's own
        // writes, which an `.onChange(of:)` here reported too.
        let report: ((Double) -> Void)? = handler
            .flatMap { DynamicEventHelper.extractPropertyName(from: $0) != nil ? $0 : nil }
            .map { handler in
                { newValue in DynamicEventHelper.callWithValue(handler, id: id, value: newValue, data: data) }
            }
        var result = buildSlider(DynamicEventHelper.reporting(report, after: bound))

        // Standard modifiers (padding -> frame -> background -> cornerRadius -> border -> margins -> ...)
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }
}
#endif // DEBUG
