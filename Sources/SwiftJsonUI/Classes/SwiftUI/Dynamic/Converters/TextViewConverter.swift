//
//  TextViewConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI TextViewWithPlaceholder
//

import SwiftUI

public struct TextViewConverter {
    
    /// Convert DynamicComponent to SwiftUI TextViewWithPlaceholder
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let text = component.text ?? ""
        let insetArray = component.containerInset ?? [8, 5, 8, 5]
        let containerInset = EdgeInsets(
            top: insetArray.count > 0 ? insetArray[0] : 8,
            leading: insetArray.count > 1 ? insetArray[1] : 5,
            bottom: insetArray.count > 2 ? insetArray[2] : 8,
            trailing: insetArray.count > 3 ? insetArray[3] : 5
        )
        
        return AnyView(
            TextViewWithPlaceholder(
                text: .constant(text),
                hint: component.hint ?? component.placeholder,
                hintColor: DynamicHelpers.colorFromHex(component.hintColor) ?? .gray,
                hintFont: component.hintFont,
                hideOnFocused: component.hideOnFocused ?? true,
                fontSize: component.fontSize ?? 16,
                fontColor: DynamicHelpers.colorFromHex(component.fontColor) ?? .primary,
                fontName: component.font,
                backgroundColor: DynamicHelpers.colorFromHex(component.background) ?? .clear,
                cornerRadius: component.cornerRadius ?? 0,
                containerInset: containerInset,
                flexible: component.flexible ?? false,
                minHeight: component.minHeight,
                maxHeight: component.maxHeight
            )
            .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}