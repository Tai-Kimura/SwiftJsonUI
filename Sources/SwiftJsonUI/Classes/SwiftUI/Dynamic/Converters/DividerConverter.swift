//
//  DividerConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI Divider
//

import SwiftUI
#if DEBUG


public struct DividerConverter {
    
    /// Convert DynamicComponent to SwiftUI Divider
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        let color = getColor(component)
        let thickness = component.height ?? 1
        
        return AnyView(
            Divider()
                .frame(height: thickness)
                .background(color)
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
    
    private static func getColor(_ component: DynamicComponent) -> Color {
        if let bgColor = component.background {
            return DynamicHelpers.getColor(bgColor) ?? Color.gray.opacity(0.3)
        }
        if let borderColor = component.borderColor {
            return DynamicHelpers.getColor(borderColor) ?? Color.gray.opacity(0.3)
        }
        return Color.gray.opacity(0.3)
    }
}
#endif // DEBUG
