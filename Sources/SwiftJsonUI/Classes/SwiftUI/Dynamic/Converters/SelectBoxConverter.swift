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
        
        // Determine select type (could support date picker in future)
        let selectItemType: SelectBoxView.SelectItemType = .normal
        
        // Date picker settings (for future date support)
        let datePickerMode: SelectBoxView.DatePickerMode = .date
        let datePickerStyle: SelectBoxView.DatePickerStyle = .automatic
        let dateStringFormat = "yyyy-MM-dd"
        
        return AnyView(
            SelectBoxView(
                id: id,
                prompt: prompt,
                fontSize: component.fontSize ?? 16,
                fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? .clear,
                cornerRadius: component.cornerRadius ?? 8,
                selectItemType: selectItemType,
                items: items,
                datePickerMode: datePickerMode,
                datePickerStyle: datePickerStyle,
                dateStringFormat: dateStringFormat,
                minimumDate: nil,
                maximumDate: nil
            )
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}