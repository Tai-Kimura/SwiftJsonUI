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
        // `label` is the Radio-specific spelling and wins over the generic
        // `text` — the same order CheckboxConverter uses, and what
        // radio_converter.rb emits. Nothing here read it, so a Radio carrying
        // only a label rendered no text at all.
        //
        // Both are string|binding, and the decode slot returns the layout
        // spelling — so a bound one rendered the characters "@{boundText}" on
        // screen until processText was put in front. (49-G fixed the same
        // leak on Compose in 2cf42df.)
        let attrs = component.typedAttributes(RadioAttributes.self)
        let rawText = (attrs.label?.rawRepresentation as? String) ?? component.text
        let text = DynamicHelpers.processText(rawText, data: data)

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
            if let expr = component.rawAttribute("selectedValue") as? String,
               DynamicBindingResolver.isBindingExpression(expr) {
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
                        radioGlyph(component: component, selected: selectionBinding.wrappedValue == item)
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

        // `checked: true` seeds the selection when no group state exists
        // (33 cross-effect: both mobiles ignored it).
        //
        // Read through the generated extraction, not `rawAttribute`: `checked`
        // is boolean|binding, and the raw cast is nil for `@{expr}` — so a
        // bound declaration seeded nothing. 49-B made the codegen expression
        // structurally identical, which only lines up once this resolves the
        // bound form too.
        let literalChecked = DynamicHelpers.resolveBool(
            component.typedAttributes(RadioAttributes.self).checked,
            legacy: nil,
            data: data
        ) == true
        let isGlyphSelected = groupSelectionBinding.wrappedValue == id ||
            (literalChecked && groupSelectionBinding.wrappedValue.isEmpty)

        return AnyView(
            HStack {
                radioGlyph(component: component, selected: isGlyphSelected)

                if !text.isEmpty {
                    buildLabelText(text: text, font: labelFont, color: labelColor)
                }
            }
            // Whole row is tappable (label included), not just the icon
            .contentShape(Rectangle())
            .onTapGesture {
                groupSelectionBinding.wrappedValue = id
                // onClick handler
                if let onClick = component.onClick {
                    DynamicEventHelper.call(onClick, data: data)
                }
            }
            // One accessibility element for the row whose label is the radio
            // text — otherwise the SF Symbol image leaks its symbol name
            // ("circle") as the element label.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text.dynamicLocalized())
            .accessibilityAddTraits(.isButton)
        )
    }

    // MARK: - Private helpers

    // The radio glyph, mirroring the codegen contract (radio_converter.rb
    // add_radio_icon_lines): `icon` / `selectedIcon` name asset images
    // (on = selectedIcon ?? icon, off = icon ?? selectedIcon); without them
    // the SF Symbol pair is used. `iconColor` replaces the hard-coded blue
    // and reaches a custom asset only through template rendering. `iconSize`
    // needs .resizable() because an SF Symbol otherwise scales with the font
    // rather than the frame. checkedColor / uncheckedColor swap with the
    // selection, iconColor stays the single-colour override.
    private static func radioGlyph(component: DynamicComponent, selected: Bool) -> AnyView {
        let icon = component.icon
        // 'selected_icon' is the declared snake alias (the generated kjui
        // table resolves it; the ios decoder only knew the camel spelling —
        // 33 cross-effect: ios rendered the default glyph).
        let selectedIcon = component.selectedIcon
            ?? component.typedAttributes(RadioAttributes.self).selectedIcon
        let size = component.iconSize
        let iconColor = component.iconColor.flatMap { DynamicHelpers.getColor($0) }
        let checked = component.checkedColor.flatMap { DynamicHelpers.getColor($0) }
        let unchecked = component.uncheckedColor.flatMap { DynamicHelpers.getColor($0) }

        let tint: Color
        if checked != nil || unchecked != nil {
            tint = selected ? (checked ?? iconColor ?? .blue) : (unchecked ?? iconColor ?? .gray)
        } else {
            tint = iconColor ?? .blue
        }

        if icon != nil || selectedIcon != nil {
            let onName = selectedIcon ?? icon ?? ""
            let offName = icon ?? selectedIcon ?? ""
            var image = Image(selected ? onName : offName)
            if iconColor != nil {
                image = image.renderingMode(.template)
            }
            var view = AnyView(image.resizable().aspectRatio(contentMode: .fit))
            if let size {
                view = AnyView(view.frame(width: size, height: size))
            }
            return AnyView(view.foregroundColor(tint))
        }

        let image = Image(systemName: selected ? "largecircle.fill.circle" : "circle")
        var view = AnyView(image)
        if let size {
            view = AnyView(image.resizable().aspectRatio(contentMode: .fit).frame(width: size, height: size))
        }
        return AnyView(view.foregroundColor(tint))
    }

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
