//
//  RadioConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI radio button(s).
//  Matches radio_converter.rb behavior and modifier order.
//
//  Modifier order (matches radio_converter.rb):
//    1. HStack/VStack { Image(.onTapGesture) Text } (radio content)
//    2. .disabled(true) + .opacity(0.6) if enabled == false
//    3. applyStandardModifiers()
//

import SwiftUI
#if DEBUG


public struct RadioConverter {

    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let id = component.id ?? "radio"
        let items = component.items ?? []
        let text = component.text ?? ""

        var result: AnyView

        if !items.isEmpty {
            // Radio group with items
            result = buildRadioGroup(
                component: component,
                id: id,
                items: items,
                text: text,
                data: data
            )
        } else {
            // Single radio button
            result = buildSingleRadio(
                component: component,
                id: id,
                text: text,
                data: data
            )
        }

        // Disabled state + opacity (before standard modifiers, matching Ruby order)
        if component.enabled?.value as? Bool == false {
            result = AnyView(result.disabled(true).opacity(0.6))
        }

        // Standard modifiers
        result = DynamicModifierHelper.applyStandardModifiers(result, component: component, data: data)

        return result
    }

    // MARK: - Radio Group (multiple items)

    private static func buildRadioGroup(
        component: DynamicComponent,
        id: String,
        items: [String],
        text: String,
        data: [String: Any]
    ) -> AnyView {
        // Get selection binding
        let selectionExpr: String? = {
            if let expr = component.rawData["selectedValue"] as? String, expr.hasPrefix("@{") {
                return expr
            }
            return nil
        }()

        let selectionBinding = DynamicBindingHelper.string(
            selectionExpr,
            data: data,
            fallback: ""
        )

        // Font and color for group title
        let titleFont = DynamicHelpers.fontFromComponent(component)
        let titleColor: Color? = {
            if let fc = component.fontColor {
                return DynamicHelpers.getColor(fc)
            }
            return nil
        }()

        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                // Group title text
                if !text.isEmpty {
                    buildTitleText(text: text, font: titleFont, color: titleColor)
                }

                // Radio items
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Image(systemName: selectionBinding.wrappedValue == item ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                selectionBinding.wrappedValue = item
                                // onValueChange handler
                                if let onValueChange = component.onValueChange {
                                    DynamicEventHelper.callWithValue(
                                        onValueChange,
                                        id: id,
                                        value: index,
                                        data: data
                                    )
                                }
                            }
                        Text(item.dynamicLocalized())
                    }
                }
            }
        )
    }

    // MARK: - Single Radio Button

    private static func buildSingleRadio(
        component: DynamicComponent,
        id: String,
        text: String,
        data: [String: Any]
    ) -> AnyView {
        let group = component.group ?? "defaultGroup"

        // Selection binding for the group
        let groupBinding = DynamicBindingHelper.string(
            nil, // Single radios use group-level state managed externally
            data: data,
            fallback: ""
        )

        // Check if group selection is provided via data
        let groupSelectionBinding: SwiftUI.Binding<String> = {
            // Try to find group binding in data
            if let binding = data[group] as? SwiftUI.Binding<String> {
                return binding
            }
            return groupBinding
        }()

        // Font and color
        let labelFont = DynamicHelpers.fontFromComponent(component)
        let labelColor: Color? = {
            if let fc = component.fontColor {
                return DynamicHelpers.getColor(fc)
            }
            return nil
        }()

        return AnyView(
            HStack {
                Image(systemName: groupSelectionBinding.wrappedValue == id ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(.blue)
                    .onTapGesture {
                        groupSelectionBinding.wrappedValue = id
                        // onClick handler
                        if let onClick = component.onClick {
                            DynamicEventHelper.call(onClick, data: data)
                        }
                    }

                if !text.isEmpty {
                    buildLabelText(text: text, font: labelFont, color: labelColor)
                }
            }
        )
    }

    // MARK: - Private helpers

    @ViewBuilder
    private static func buildTitleText(text: String, font: Font?, color: Color?) -> some View {
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
#endif // DEBUG
