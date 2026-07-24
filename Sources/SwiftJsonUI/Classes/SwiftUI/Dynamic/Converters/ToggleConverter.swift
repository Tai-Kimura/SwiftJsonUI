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

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let id = component.id ?? "toggle"
        let attrs = component.typedAttributes(ToggleAttributes.self)

        // Resolve isOn binding: check isOn first, then checked
        let isOnExpr: String? = attrs.isOn?.bindingString ?? attrs.checked?.bindingString

        // Two-way bound var if the expression resolves to a Binding<Bool> in
        // data; otherwise the toggle gets local state (an unbound native
        // switch is still flippable on every other JsonUI runtime).
        let boundBinding = DynamicBindingHelper.extractBoolBinding(from: isOnExpr, data: data)
        let initialValue: Bool = {
            if let bound = boundBinding { return bound.wrappedValue }
            return DynamicBindingHelper.bool(
                isOnExpr,
                data: data,
                fallback: attrs.isOn?.value ?? attrs.checked?.value ?? false
            ).wrappedValue
        }()

        // onValueChange handler (+ onValueChanged alias)
        let handlerExpr: String? = component.onValueChange
            ?? (component.rawAttribute("onValueChanged") as? String)

        // Label text
        let text = component.text ?? component.label ?? ""

        // Build Toggle with label
        var result: AnyView

        // Determine font from component or labelAttributes
        let labelAttrsDict = attrs.labelAttributes

        // Build the label Text view with font and color modifiers
        let labelFont: Font? = {
            if let labelAttrs = labelAttrsDict {
                // labelAttributes override component-level font settings
                let fontSize = labelAttrs["fontSize"] as? CGFloat ?? component.fontSize
                let fontName = labelAttrs["font"] as? String ?? component.font
                let fontWeight = labelAttrs["fontWeight"] as? String ?? labelAttrs["fontStyle"] as? String ?? component.fontWeight
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
                return DynamicHelpers.fontFromComponent(component)
            }
        }()

        let labelColor: Color? = {
            if let labelAttrs = labelAttrsDict {
                let colorStr = labelAttrs["fontColor"] as? String ?? labelAttrs["color"] as? String
                if let colorStr = colorStr {
                    return DynamicHelpers.getColor(colorStr)
                }
            }
            if let fontColor = component.fontColor {
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
