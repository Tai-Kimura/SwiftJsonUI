//
//  SelectBoxConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI SelectBoxView
//

import SwiftUI

public struct SelectBoxConverter {
    
    /// Convert DynamicComponent to SwiftUI SelectBoxView
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let id = component.id ?? "selectBox"
        let prompt = component.hint ?? component.placeholder
        let items = component.items ?? []
        
        // Determine select type based on selectItemType property
        let selectItemType: SelectBoxView.SelectItemType = {
            if let itemType = component.selectItemType, itemType.lowercased() == "date" {
                return .date
            }
            return .normal
        }()
        
        // Date picker settings
        let datePickerMode: SelectBoxView.DatePickerMode = {
            if let mode = component.datePickerMode {
                switch mode.lowercased() {
                case "time":
                    return .time
                case "datetime", "dateandtime":
                    return .dateTime
                default:
                    return .date
                }
            }
            return .date
        }()
        
        let datePickerStyle: SelectBoxView.DatePickerStyle = {
            if let style = component.datePickerStyle {
                switch style.lowercased() {
                case "wheel", "wheels":
                    return .wheel
                case "compact":
                    return .compact
                case "graphical", "inline":
                    return .graphical
                default:
                    return .automatic
                }
            }
            return .automatic
        }()
        
        let dateStringFormat = component.dateStringFormat ?? "yyyy-MM-dd"
        
        // Parse minimum and maximum dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let minimumDate = component.minimumDate.flatMap { dateFormatter.date(from: $0) }
        let maximumDate = component.maximumDate.flatMap { dateFormatter.date(from: $0) }
        
        return AnyView(
            SelectBoxView(
                id: id,
                prompt: prompt,
                fontSize: component.fontSize ?? 16,
                fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? Color(UIColor.systemGray6),
                cornerRadius: component.cornerRadius ?? 8,
                selectItemType: selectItemType,
                items: items,
                datePickerMode: datePickerMode,
                datePickerStyle: datePickerStyle,
                dateStringFormat: dateStringFormat,
                minimumDate: minimumDate,
                maximumDate: maximumDate
            )
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}