//
//  ToggleConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Toggle.
//  Matches toggle_converter.rb behavior and modifier order.
//
//  Modifier order (matches toggle_converter.rb):
//    1. Toggle(isOn:) { Text(...) with font/color modifiers }
//    2. .toggleStyle() (if toggleStyle set)
//    3. .onChange() (onValueChange)
//    4. applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct ToggleConverter {

    /// Label/content font through the data overload — the data-less read
    /// dropped a bound `font` / `fontSize` to the configured defaults (same
    /// family as Radio, 49-B (2); ruled 2026-08-06). Internal so the test
    /// pins this converter's own read.
    static func declaredFont(_ component: DynamicComponent, data: [String: Any]) -> Font? {
        DynamicHelpers.fontFromComponent(component, data: data)
    }

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let id = component.id ?? "toggle"
        let attrs = component.typedAttributes(ToggleAttributes.self)

        // Resolve isOn binding: isOn first, then checked, then `value` —
        // the cross-platform alias of the on/off state (toggle_converter.rb
        // reads the same chain).
        let isOnExpr: String? = attrs.isOn?.bindingString
            ?? attrs.checked?.bindingString
            ?? attrs.value?.bindingString

        // Two-way bound var if the expression resolves to a Binding<Bool> in
        // data; otherwise the toggle gets local state (an unbound native
        // switch is still flippable on every other JsonUI runtime).
        let boundBinding = DynamicBindingHelper.extractBoolBinding(from: isOnExpr, data: data)
        let initialValue: Bool = {
            if let bound = boundBinding { return bound.wrappedValue }
            return DynamicBindingHelper.bool(
                isOnExpr,
                data: data,
                fallback: attrs.isOn?.value ?? attrs.checked?.value ?? attrs.value?.value ?? false
            ).wrappedValue
        }()

        // onValueChange handler (+ onValueChanged alias)
        let handlerExpr: String? = component.onValueChangeSpelling()
            ?? component.onValueChangedSpelling()

        // Label text
        let text = component.string(LabelAttributes.self, \.text)
            ?? component.string(CheckAttributes.self, \.label) ?? ""

        // Build Toggle with label
        var result: AnyView

        // Determine font from component or labelAttributes
        let labelAttrsDict = attrs.labelAttributes

        // Build the label Text view with font and color modifiers
        let labelFont: Font? = {
            if let labelAttrs = labelAttrsDict {
                // labelAttributes override component-level font settings
                // Switch/Toggle declares no fontSize of its own, so there is
                // no typed slot to resolve. toggle_converter.rb DOES honor it
                // (`@component.merge(label_attrs)` → apply_font_modifiers), so
                // the read has to survive — through the sanctioned raw
                // passthrough, not a hand-decoded slot. Reported to E as an
                // SSoT declaration gap.
                let rawFontSize = component.rawAttribute("fontSize")
                let componentFontSize = (rawFontSize as? Double).map { CGFloat($0) }
                    ?? (rawFontSize as? Int).map { CGFloat($0) }
                let fontSize = labelAttrs["fontSize"] as? CGFloat ?? componentFontSize
                let fontName = labelAttrs["font"] as? String
                    ?? component.string(LabelAttributes.self, \.font)
                let fontWeight = labelAttrs["fontWeight"] as? String ?? labelAttrs["fontStyle"] as? String ?? component.fontWeightSpelling()
                guard fontSize != nil || fontName != nil || fontWeight != nil else { return nil }
                if let name = fontName, let size = fontSize ?? 17 as CGFloat? {
                    return Font.custom(name, size: size)
                }
                if let size = fontSize {
                    let weight = DynamicHelpers.fontWeightFromString(fontWeight)
                    return Font.system(size: size, weight: weight)
                }
                return nil
            } else {
                return declaredFont(component, data: data)
            }
        }()

        let labelColor: Color? = {
            if let labelAttrs = labelAttrsDict {
                let colorStr = labelAttrs["fontColor"] as? String ?? labelAttrs["color"] as? String
                if let colorStr = colorStr {
                    return DynamicHelpers.getColor(colorStr)
                }
            }
            if let fontColor = component.string(LabelAttributes.self, \.fontColor) {
                return DynamicHelpers.getColor(fontColor)
            }
            return nil
        }()

        // Toggle construction shared by the bound and local-state paths
        let buildToggle: (SwiftUI.Binding<Bool>) -> AnyView = { isOnBinding in
            var built = AnyView(
                Toggle(isOn: isOnBinding) {
                    buildLabelText(text: text, font: labelFont, color: labelColor)
                }
            )

            // toggleStyle (undeclared legacy key — see check_converter_raw_reads.sh)
            if let toggleStyle = component.rawAttribute("toggleStyle") as? String {
                switch toggleStyle {
                case "switch":
                    built = AnyView(AnyViewWrapper(view: built).toggleStyle(SwitchToggleStyle()))
                case "button":
                    if #available(iOS 15.0, *) {
                        built = AnyView(AnyViewWrapper(view: built).toggleStyle(.button))
                    }
                default:
                    built = AnyView(AnyViewWrapper(view: built).toggleStyle(DefaultToggleStyle()))
                }
            }

            // No label: hide the (empty) label slot so the control is just
            // the switch — otherwise SwiftUI keeps a full-width row whose
            // center (where taps land) is empty space, making the control
            // effectively untappable. Matches kjui/rjui: an unlabeled
            // switch hugs the control.
            if text.isEmpty {
                built = AnyView(built.labelsHidden())
            }

            // Explicit wrapContent: hug content instead of Toggle's greedy
            // full-width layout.
            if component.widthRaw == "wrapContent" {
                built = AnyView(built.fixedSize(horizontal: true, vertical: false))
            }
            return built
        }

        if let bound = boundBinding {
            result = buildToggle(bound)

            // onValueChange handler - observe the bound var for changes
            if let onValueChange = handlerExpr,
               DynamicEventHelper.handlerName(from: onValueChange) != nil {
                result = AnyView(
                    result.onChange(of: bound.wrappedValue) { newValue in
                        DynamicEventHelper.callWithValue(
                            onValueChange,
                            id: id,
                            value: newValue,
                            data: data
                        )
                    }
                )
            }
        } else {
            // Unbound: local state; onValueChange fires from the binding set
            result = AnyView(
                DynamicLocalState(
                    initial: initialValue,
                    onChange: { newValue in
                        guard let onValueChange = handlerExpr else { return }
                        DynamicEventHelper.callWithValue(
                            onValueChange,
                            id: id,
                            value: newValue,
                            data: data
                        )
                    },
                    content: buildToggle
                )
            )
        }

        // onTintColor — the ON-state track (UISwitch heritage). `.tint()`
        // is the SwiftUI spelling; it only shows when the switch is on
        // (33 cross-effect: ios rendered the default green for a declared
        // onTintColor on an ON switch).
        // `trackTintColor` is the third spelling of the same thing. The SSoT
        // called it "deprecated on swift — SwiftUI Toggle uses unified tint
        // only", but ProgressConverter has mapped the same name onto a real
        // modifier all along; the limit was this converter's fallback chain,
        // not the platform. 49-E retracted the deprecation.
        let switchAttrs = component.typedAttributes(SwitchAttributes.self)
        if let onTint = switchAttrs.onTintColor
            ?? (switchAttrs.tint?.rawRepresentation as? String)
            ?? switchAttrs.trackTintColor,
           let trackColor = DynamicHelpers.getColor(onTint, data: data) {
            result = AnyView(result.tint(trackColor))
        }

        // thumbTintColor — the knob, not the track. `.tint()` colours the
        // track and SwiftUI exposes nothing for the knob, so this goes
        // through UISwitch.appearance() at appear time — the same route the
        // codegen takes (toggle_converter.rb apply_thumb_tint_color).
        if let thumb = switchAttrs.thumbTintColor?.rawRepresentation as? String,
           let color = DynamicHelpers.getColor(thumb, data: data) {
            result = AnyView(result.onAppear {
                UISwitch.appearance().thumbTintColor = UIColor(color)
            })
        }

        // Standard modifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Private helpers

    @ViewBuilder
    private static func buildLabelText(text: String, font: Font?, color: Color?) -> some View {
        let baseText = Text(text.dynamicLocalized())
        if let font = font, let color = color {
            baseText.font(font).foregroundColor(color)
        } else if let font = font {
            baseText.font(font)
        } else if let color = color {
            baseText.foregroundColor(color)
        } else {
            baseText
        }
    }
}

/// Helper to apply toggleStyle to AnyView (toggleStyle requires ToggleStyle conformance on the View)
private struct AnyViewWrapper: View {
    let view: AnyView
    var body: some View { view }
}

#endif // DEBUG
