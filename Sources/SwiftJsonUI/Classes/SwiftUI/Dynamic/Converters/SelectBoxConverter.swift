//
//  SelectBoxConverter.swift
//  SwiftJsonUI
//
//  Dynamic mode equivalent of selectbox_converter.rb
//  Creates SelectBoxView matching tool-generated code exactly.
//
//  Modifier order (matches selectbox_converter.rb):
//    1. SelectBoxView(...) creation
//       - id, prompt, fontSize, fontColor, backgroundColor, cornerRadius
//       - selectItemType, items (normal) OR datePickerMode/datePickerStyle/dateStringFormat/
//         minimumDate/maximumDate/minuteInterval/selectedDate (date)
//       - selectedIndex, padding
//    2. .onChange (onValueChange)
//    3. apply_frame_constraints + apply_frame_size
//    4. .overlay (border)
//    5. apply_margins
//    6. .opacity / .hidden
//    7. accessibilityIdentifier
//

import SwiftUI
#if DEBUG

public struct SelectBoxConverter {

    /// Convert DynamicComponent to SwiftUI SelectBoxView
    /// Matches selectbox_converter.rb convert method exactly
    public static func convert(
        component: DynamicComponent,
        data: [String: Any]
    ) -> AnyView {
        let id = component.id ?? "selectBox"

        // --- 1. Build SelectBoxView ---

        // prompt
        let prompt = (component.prompt ?? component.hint ?? component.placeholder)?.dynamicLocalized()

        // fontSize
        let fontSize = component.fontSize ?? 16

        // fontColor
        let fontColor: Color = DynamicHelpers.getColor(component.fontColor, data: data) ?? .primary

        // backgroundColor
        let backgroundColor: Color = DynamicHelpers.getColor(component.background, data: data) ?? Color(UIColor.systemGray6)

        // cornerRadius
        let cornerRadius = component.cornerRadius ?? 8

        // selectItemType
        let selectItemType: SelectBoxView.SelectItemType = {
            if let itemType = component.selectItemType, itemType.lowercased() == "date" {
                return .date
            }
            return .normal
        }()

        // items (for normal type) - with binding support
        let items: [String] = {
            if let staticItems = component.items, !staticItems.isEmpty {
                return staticItems
            }
            // Check rawData for binding items
            if let itemsStr = component.rawData["items"] as? String,
               itemsStr.hasPrefix("@{") && itemsStr.hasSuffix("}") {
                let propName = String(itemsStr.dropFirst(2).dropLast(1))
                if let dataItems = data[propName] as? [String] {
                    return dataItems
                }
            }
            return []
        }()

        // datePickerMode
        let datePickerMode: SelectBoxView.DatePickerMode = {
            guard let mode = component.datePickerMode else { return .date }
            switch mode.lowercased() {
            case "time": return .time
            case "datetime", "dateandtime": return .dateTime
            default: return .date
            }
        }()

        // datePickerStyle
        let datePickerStyle: SelectBoxView.DatePickerStyle = {
            guard let style = component.datePickerStyle else { return .wheel }
            switch style.lowercased() {
            case "automatic": return .automatic
            case "compact": return .compact
            case "graphical", "inline": return .graphical
            default: return .wheel
            }
        }()

        // dateStringFormat
        let dateStringFormat = component.dateStringFormat ?? "yyyy-MM-dd"

        // minimumDate / maximumDate / selectedDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let minimumDate = component.minimumDate.flatMap { dateFormatter.date(from: $0) }
        let maximumDate = component.maximumDate.flatMap { dateFormatter.date(from: $0) }
        let selectedDate = component.selectedDate.flatMap { dateFormatter.date(from: $0) }

        // minuteInterval
        let minuteInterval = component.minuteInterval ?? 1

        // selectedIndex (value for initial, binding for two-way sync)
        let selectedIndex = component.selectedIndex
        let selectedIndexBinding: SwiftUI.Binding<Int>? = {
            if let si = component.rawData["selectedIndex"] as? String, si.hasPrefix("@{") {
                let binding = DynamicBindingHelper.int(si, data: data, fallback: selectedIndex ?? 0)
                return binding
            }
            return nil
        }()

        // padding (internal padding for SelectBoxView)
        let padding: EdgeInsets? = {
            let p = DynamicHelpers.getPadding(from: component)
            if p.top != 0 || p.leading != 0 || p.bottom != 0 || p.trailing != 0 {
                return p
            }
            return nil
        }()

        var result = AnyView(
            SelectBoxView(
                id: id,
                prompt: prompt,
                fontSize: fontSize,
                fontColor: fontColor,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                selectItemType: selectItemType,
                items: items,
                datePickerMode: datePickerMode,
                datePickerStyle: datePickerStyle,
                dateStringFormat: dateStringFormat,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                minuteInterval: minuteInterval,
                selectedIndex: selectedIndex,
                selectedIndexBinding: selectedIndexBinding,
                selectedDate: selectedDate,
                padding: padding
            )
        )

        // --- 2. .onChange (onValueChange) ---
        // Determine which binding property to observe for changes
        if let onValueChange = component.onValueChange,
           DynamicEventHelper.extractPropertyName(from: onValueChange) != nil {
            // Find the binding property to observe
            let bindingProp: String? = {
                if let si = component.rawData["selectedIndex"] as? String,
                   let prop = DynamicEventHelper.extractPropertyName(from: si) {
                    return prop
                }
                if let si = component.rawData["selectedItem"] as? String,
                   let prop = DynamicEventHelper.extractPropertyName(from: si) {
                    return prop
                }
                return nil
            }()

            if let prop = bindingProp {
                // Observe Int binding (selectedIndex)
                if let binding = data[prop] as? SwiftUI.Binding<Int> {
                    result = AnyView(
                        result.onChange(of: binding.wrappedValue) { _, newValue in
                            DynamicEventHelper.callWithValue(onValueChange, id: id, value: newValue, data: data)
                        }
                    )
                }
                // Observe String binding (selectedItem)
                else if let binding = data[prop] as? SwiftUI.Binding<String> {
                    result = AnyView(
                        result.onChange(of: binding.wrappedValue) { _, newValue in
                            DynamicEventHelper.callWithValue(onValueChange, id: id, value: newValue, data: data)
                        }
                    )
                }
            }
        }

        // --- 3. apply_frame_constraints + apply_frame_size ---
        // SelectBoxView handles padding/background/cornerRadius internally
        result = DynamicModifierHelper.applyFrameConstraints(result, component: component)
        result = DynamicModifierHelper.applyFrameSize(result, component: component, data: data)

        // --- 4. .overlay (border) ---
        result = DynamicModifierHelper.applyBorder(result, component: component)

        // --- 5. apply_margins ---
        result = DynamicModifierHelper.applyMargins(result, component: component, data: data)

        // --- 6. .opacity / .hidden ---
        result = DynamicModifierHelper.applyOpacity(result, component: component, data: data)
        result = DynamicModifierHelper.applyHidden(result, component: component, data: data)

        // --- 7. accessibilityIdentifier ---
        result = DynamicModifierHelper.applyAccessibilityId(result, component: component)

        return result
    }
}
#endif // DEBUG
